class PostModel {
  final String id;
  final String userId;
  final String? imageUrl;
  final String? caption;
  final List<String> likes;
  final DateTime createdAt;
  final String? gameId;

  PostModel({
    required this.id,
    required this.userId,
    this.imageUrl,
    this.caption,
    this.likes = const [],
    required this.createdAt,
    this.gameId,
  });

  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      imageUrl: map['imageUrl'],
      caption: map['caption'],
      likes: List<String>.from(map['likes'] ?? []),
      createdAt: (map['createdAt'] != null)
          ? (map['createdAt'] is DateTime
          ? map['createdAt']
          : DateTime.fromMillisecondsSinceEpoch(map['createdAt']))
          : DateTime.now(),
      gameId: map['gameId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'imageUrl': imageUrl,
      'caption': caption,
      'likes': likes,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'gameId': gameId,
    };
  }
}
