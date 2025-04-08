// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['id'] as String,
  username: json['username'] as String,
  profileImageUrl: json['profileImageUrl'] as String?,
  walletBalance: (json['walletBalance'] as num?)?.toDouble() ?? 0.0,
  favoriteGameIds:
      (json['favoriteGameIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  followerIds:
      (json['followerIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  followingIds:
      (json['followingIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  posts: (json['posts'] as num?)?.toInt() ?? 0,
  matchesPlayed: (json['matchesPlayed'] as num?)?.toInt() ?? 0,
  matchesWon: (json['matchesWon'] as num?)?.toInt() ?? 0,
  coupons: (json['coupons'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'profileImageUrl': instance.profileImageUrl,
  'walletBalance': instance.walletBalance,
  'favoriteGameIds': instance.favoriteGameIds,
  'followerIds': instance.followerIds,
  'followingIds': instance.followingIds,
  'posts': instance.posts,
  'matchesPlayed': instance.matchesPlayed,
  'matchesWon': instance.matchesWon,
  'coupons': instance.coupons,
};
