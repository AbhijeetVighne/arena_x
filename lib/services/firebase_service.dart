import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/game_model.dart';
import '../models/team_model.dart';
import '../models/post_model.dart';

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // User methods
  Future<UserModel?> getUserData(String userId) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(userId).get();

      if (!docSnapshot.exists) {
        // If user doesn't exist in Firestore yet, create a new user profile
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          final newUser = UserModel(
            id: userId,
            username: currentUser.displayName ?? 'User${userId.substring(0, 5)}',
            profileImageUrl: currentUser.photoURL,
            walletBalance: 0.0,
            favoriteGameIds: [],
            followerIds: [],
            followingIds: [],
          );

          await _firestore.collection('users').doc(userId).set(newUser.toMap());
          return newUser;
        }
        return null;
      }

      final data = docSnapshot.data() as Map<String, dynamic>;
      return UserModel.fromMap({...data, 'id': userId});
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  Future<void> updateUserData(UserModel user) async {
    await _firestore.collection('users').doc(user.id).update(user.toMap());
  }

  // Follow/Unfollow methods
  Future<void> followUser(String currentUserId, String targetUserId) async {
    // Don't allow following yourself
    if (currentUserId == targetUserId) {
      throw Exception("You cannot follow yourself");
    }

    final batch = _firestore.batch();

    // Update current user's following list
    final currentUserRef = _firestore.collection('users').doc(currentUserId);
    batch.update(currentUserRef, {
      'followingIds': FieldValue.arrayUnion([targetUserId]),
    });

    // Update target user's followers list
    final targetUserRef = _firestore.collection('users').doc(targetUserId);
    batch.update(targetUserRef, {
      'followerIds': FieldValue.arrayUnion([currentUserId]),
    });

    // Create a follow activity for notifications
    final activityRef = _firestore.collection('activities').doc();
    batch.set(activityRef, {
      'type': 'follow',
      'fromUserId': currentUserId,
      'toUserId': targetUserId,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    await batch.commit();
  }

  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    final batch = _firestore.batch();

    // Update current user's following list
    final currentUserRef = _firestore.collection('users').doc(currentUserId);
    batch.update(currentUserRef, {
      'followingIds': FieldValue.arrayRemove([targetUserId]),
    });

    // Update target user's followers list
    final targetUserRef = _firestore.collection('users').doc(targetUserId);
    batch.update(targetUserRef, {
      'followerIds': FieldValue.arrayRemove([currentUserId]),
    });

    await batch.commit();
  }

  // Check if two users follow each other
  Future<bool> checkMutualFollow(String userId1, String userId2) async {
    final user1Doc = await _firestore.collection('users').doc(userId1).get();
    final user2Doc = await _firestore.collection('users').doc(userId2).get();

    if (!user1Doc.exists || !user2Doc.exists) {
      return false;
    }

    final user1Data = user1Doc.data() as Map<String, dynamic>;
    final user2Data = user2Doc.data() as Map<String, dynamic>;

    final user1FollowingIds = List<String>.from(user1Data['followingIds'] ?? []);
    final user2FollowingIds = List<String>.from(user2Data['followingIds'] ?? []);

    return user1FollowingIds.contains(userId2) && user2FollowingIds.contains(userId1);
  }

  // Search users
  Future<List<UserModel>> searchUsers(String query, {int limit = 20}) async {
    if (query.isEmpty) {
      return [];
    }

    // Create a query that searches for usernames starting with the query
    final querySnapshot = await _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: query + '\uf8ff')
        .limit(limit)
        .get();

    return querySnapshot.docs.map((doc) {
      return UserModel.fromMap({...doc.data(), 'id': doc.id});
    }).toList();
  }

  // Get user followers
  Future<List<UserModel>> getUserFollowers(String userId) async {
    final user = await getUserData(userId);
    if (user == null) {
      return [];
    }

    List<UserModel> followers = [];
    for (final followerId in user.followerIds) {
      final follower = await getUserData(followerId);
      if (follower != null) {
        followers.add(follower);
      }
    }

    return followers;
  }

  // Get user following
  Future<List<UserModel>> getUserFollowing(String userId) async {
    final user = await getUserData(userId);
    if (user == null) {
      return [];
    }

    List<UserModel> following = [];
    for (final followingId in user.followingIds) {
      final followingUser = await getUserData(followingId);
      if (followingUser != null) {
        following.add(followingUser);
      }
    }

    return following;
  }

  // Game methods
  Future<List<GameModel>> getGames() async {
    try {
      final querySnapshot = await _firestore.collection('games').get();
      final games = querySnapshot.docs.map((doc) {
        return GameModel.fromMap({...doc.data(), 'id': doc.id});
      }).toList();

      // If there are no games in the database, initialize with predefined games
      if (games.isEmpty) {
        final predefinedGames = GameModel.getPredefinedGames();
        for (final game in predefinedGames) {
          await _firestore.collection('games').doc(game.id).set(game.toMap());
        }
        return predefinedGames;
      }

      return games;
    } catch (e) {
      print('Error getting games: $e');
      return GameModel.getPredefinedGames(); // Fallback to predefined games
    }
  }

  Future<List<GameModel>> getGamesByIds(List<String> gameIds) async {
    if (gameIds.isEmpty) return [];

    try {
      final List<GameModel> games = [];

      for (final gameId in gameIds) {
        final docSnapshot = await _firestore.collection('games').doc(gameId).get();
        if (docSnapshot.exists) {
          games.add(GameModel.fromMap({...docSnapshot.data()!, 'id': gameId}));
        }
      }

      return games;
    } catch (e) {
      print('Error getting games by IDs: $e');
      return [];
    }
  }

  // Added method to get a single game by ID
  Future<GameModel?> getGameById(String gameId) async {
    try {
      final docSnapshot = await _firestore.collection('games').doc(gameId).get();
      if (docSnapshot.exists) {
        return GameModel.fromMap({...docSnapshot.data()!, 'id': gameId});
      }
      return null;
    } catch (e) {
      print('Error getting game by ID: $e');
      return null;
    }
  }

  // Team methods
  Future<List<TeamModel>> getUserTeams(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('teams')
          .where('memberIds', arrayContains: userId)
          .get();

      return querySnapshot.docs.map((doc) {
        return TeamModel.fromMap({...doc.data(), 'id': doc.id});
      }).toList();
    } catch (e) {
      print('Error getting user teams: $e');
      return [];
    }
  }

  Future<List<TeamModel>> getUserGameTeams(String userId, String gameId, {bool forceRefresh = false}) async {
    try {
      // Force a refresh by using no-cache option when requested
      final querySnapshot = await _firestore
          .collection('teams')
          .where('memberIds', arrayContains: userId)
          .where('gameId', isEqualTo: gameId)
          .get(forceRefresh ? const GetOptions(source: Source.server) : null);

      return querySnapshot.docs.map((doc) {
        return TeamModel.fromMap({...doc.data(), 'id': doc.id});
      }).toList();
    } catch (e) {
      print('Error getting user game teams: $e');
      return [];
    }
  }

  Future<TeamModel> createTeam({
    required String name,
    required String gameId,
    required String createdBy,
  }) async {
    try {
      final teamRef = _firestore.collection('teams').doc();

      final newTeam = TeamModel(
        id: teamRef.id,
        name: name,
        gameId: gameId,
        createdBy: createdBy,
        memberIds: [createdBy],
        createdAt: DateTime.now(),
      );

      await teamRef.set(newTeam.toMap());

      // Update user's teams list
      final userRef = _firestore.collection('users').doc(createdBy);
      await userRef.update({
        'teamIds': FieldValue.arrayUnion([teamRef.id]),
      });

      return newTeam;
    } catch (e) {
      print('Error creating team: $e');
      rethrow;
    }
  }

  Future<void> inviteToTeam(String teamId, String invitedUserId) async {
    try {
      // Get team data to find the team creator
      final teamSnapshot = await _firestore.collection('teams').doc(teamId).get();
      final teamData = teamSnapshot.data() as Map<String, dynamic>;
      final gameId = teamData['gameId'] as String;
      final teamCreatorId = teamData['createdBy'] as String;

      // Check if user that is inviting is the team creator
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId != teamCreatorId) {
        throw Exception('Only the team creator can send invitations');
      }

      // Check if the users follow each other
      final isMutualFollow = await checkMutualFollow(currentUserId!, invitedUserId);
      if (!isMutualFollow) {
        throw Exception('You must follow each other before sending team invitations');
      }

      // Check if the invited user has the game in their favorite games
      final userSnapshot = await _firestore.collection('users').doc(invitedUserId).get();
      final userData = userSnapshot.data() as Map<String, dynamic>;
      final favoriteGameIds = List<String>.from(userData['favoriteGameIds'] ?? []);

      if (!favoriteGameIds.contains(gameId)) {
        throw Exception('The invited user must have the game in their favorite games');
      }

      // Check if the invited user is already in another team for the same game
      final userTeamsSnapshot = await _firestore
          .collection('teams')
          .where('memberIds', arrayContains: invitedUserId)
          .where('gameId', isEqualTo: gameId)
          .get();

      if (userTeamsSnapshot.docs.isNotEmpty) {
        throw Exception('The invited user is already in another team for this game');
      }

      // Create invitation in Firestore
      await _firestore.collection('teamInvitations').add({
        'teamId': teamId,
        'invitedByUserId': currentUserId,
        'invitedUserId': invitedUserId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create a notification activity
      await _firestore.collection('activities').add({
        'type': 'team_invitation',
        'teamId': teamId,
        'fromUserId': currentUserId,
        'toUserId': invitedUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'data': {
          'teamName': teamData['name'],
          'gameId': gameId,
        }
      });
    } catch (e) {
      print('Error inviting to team: $e');
      rethrow;
    }
  }

  // Method to leave a team
  Future<void> leaveTeam(String teamId, String userId) async {
    try {
      final batch = _firestore.batch();
      final teamRef = _firestore.collection('teams').doc(teamId);
      final teamDoc = await teamRef.get();

      if (!teamDoc.exists) {
        throw Exception('Team not found');
      }

      final teamData = teamDoc.data() as Map<String, dynamic>;
      final memberIds = List<String>.from(teamData['memberIds'] ?? []);
      final createdBy = teamData['createdBy'] as String;

      // Check if the user is a member of the team
      if (!memberIds.contains(userId)) {
        throw Exception('You are not a member of this team');
      }

      // Remove user from the team members
      memberIds.remove(userId);

      // If there are still members in the team
      if (memberIds.isNotEmpty) {
        // If the user leaving is the creator, assign a new creator
        if (createdBy == userId) {
          batch.update(teamRef, {
            'memberIds': memberIds,
            'createdBy': memberIds.first, // Assign the first remaining member as the new creator
          });
        } else {
          // Just remove the user from members
          batch.update(teamRef, {
            'memberIds': memberIds,
          });
        }
      } else {
        // If the team will be empty, delete it
        batch.delete(teamRef);
      }

      // Update user's teams list in user document if needed
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        if (userData.containsKey('teamIds')) {
          batch.update(userRef, {
            'teamIds': FieldValue.arrayRemove([teamId]),
          });
        }
      }

      await batch.commit();
    } catch (e) {
      print('Error leaving team: $e');
      rethrow;
    }
  }

  // Post methods
  Future<List<PostModel>> getUserPosts(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return PostModel.fromMap({...doc.data(), 'id': doc.id});
      }).toList();
    } catch (e) {
      print('Error getting user posts: $e');
      return [];
    }
  }
}
