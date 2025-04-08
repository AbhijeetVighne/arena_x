import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String username;
  final String? profileImageUrl;
  final double walletBalance;
  final List<String> favoriteGameIds;
  final List<String> followerIds; // List of user IDs who follow this user
  final List<String> followingIds; // List of user IDs this user follows
  final int posts;
  final int matchesPlayed;
  final int matchesWon;
  final int coupons;

  UserModel({
    required this.id,
    required this.username,
    this.profileImageUrl,
    this.walletBalance = 0.0,
    this.favoriteGameIds = const [],
    this.followerIds = const [],
    this.followingIds = const [],
    this.posts = 0,
    this.matchesPlayed = 0,
    this.matchesWon = 0,
    this.coupons = 0,
  });

  // Getters for follower/following counts
  int get followers => followerIds.length;
  int get following => followingIds.length;

  // Method to check if two users follow each other
  bool isFollowingMutual(String otherUserId) {
    return followerIds.contains(otherUserId) && followingIds.contains(otherUserId);
  }

  static UserModel error = UserModel(id: '', username: '');

  // For json_serializable
  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  // For Firestore .withConverter
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> docSnap, _) {
    final data = docSnap.data()!;
    return UserModel.fromJson({...data, 'uid': docSnap.id}); // embed id
  }

  Map<String, dynamic> toFirestore() {
    final data = toJson();
    data.remove('uid'); // don't store UID inside document fields
    return data;
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? profileImageUrl,
    double? walletBalance,
    List<String>? favoriteGameIds,
    List<String>? followerIds,
    List<String>? followingIds,
    int? posts,
    int? matchesPlayed,
    int? matchesWon,
    int? coupons,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      walletBalance: walletBalance ?? this.walletBalance,
      favoriteGameIds: favoriteGameIds ?? this.favoriteGameIds,
      followerIds: followerIds ?? this.followerIds,
      followingIds: followingIds ?? this.followingIds,
      posts: posts ?? this.posts,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      matchesWon: matchesWon ?? this.matchesWon,
      coupons: coupons ?? this.coupons,
    );
  }
}