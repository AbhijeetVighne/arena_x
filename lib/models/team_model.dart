class TeamModel {
  final String id;
  final String name;
  final String gameId;
  final String createdBy;
  final List<String> memberIds;
  final String? teamLogoUrl;
  final DateTime createdAt;

  TeamModel({
    required this.id,
    required this.name,
    required this.gameId,
    required this.createdBy,
    required this.memberIds,
    this.teamLogoUrl,
    required this.createdAt,
  });

  factory TeamModel.fromMap(Map<String, dynamic> map) {
    return TeamModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      gameId: map['gameId'] ?? '',
      createdBy: map['createdBy'] ?? '',
      memberIds: List<String>.from(map['memberIds'] ?? []),
      teamLogoUrl: map['teamLogoUrl'],
      createdAt: (map['createdAt'] != null)
          ? (map['createdAt'] is DateTime
          ? map['createdAt']
          : DateTime.fromMillisecondsSinceEpoch(map['createdAt']))
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'gameId': gameId,
      'createdBy': createdBy,
      'memberIds': memberIds,
      'teamLogoUrl': teamLogoUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  TeamModel copyWith({
    String? id,
    String? name,
    String? gameId,
    String? createdBy,
    List<String>? memberIds,
    String? teamLogoUrl,
    DateTime? createdAt,
  }) {
    return TeamModel(
      id: id ?? this.id,
      name: name ?? this.name,
      gameId: gameId ?? this.gameId,
      createdBy: createdBy ?? this.createdBy,
      memberIds: memberIds ?? this.memberIds,
      teamLogoUrl: teamLogoUrl ?? this.teamLogoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
