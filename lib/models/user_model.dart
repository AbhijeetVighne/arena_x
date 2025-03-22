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

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      walletBalance: (map['walletBalance'] ?? 0.0).toDouble(),
      favoriteGameIds: List<String>.from(map['favoriteGameIds'] ?? []),
      followerIds: List<String>.from(map['followerIds'] ?? []),
      followingIds: List<String>.from(map['followingIds'] ?? []),
      posts: map['posts'] ?? 0,
      matchesPlayed: map['matchesPlayed'] ?? 0,
      matchesWon: map['matchesWon'] ?? 0,
      coupons: map['coupons'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'profileImageUrl': profileImageUrl,
      'walletBalance': walletBalance,
      'favoriteGameIds': favoriteGameIds,
      'followerIds': followerIds,
      'followingIds': followingIds,
      'posts': posts,
      'matchesPlayed': matchesPlayed,
      'matchesWon': matchesWon,
      'coupons': coupons,
    };
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