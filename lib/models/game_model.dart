class GameModel {
  final String id;
  final String name;
  final String? imageUrl;
  final int maxTeamSize;
  final String? description;

  GameModel({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.maxTeamSize,
    this.description,
  });

  factory GameModel.fromMap(Map<String, dynamic> map) {
    return GameModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'],
      maxTeamSize: map['maxTeamSize'] ?? 4, // Default team size if not specified
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'maxTeamSize': maxTeamSize,
      'description': description,
    };
  }

  // Predefined games as per requirements
  static List<GameModel> getPredefinedGames() {
    return [
      GameModel(
        id: 'bgmi',
        name: 'BGMI',
        imageUrl: 'https://example.com/bgmi.jpg', // This would be a real URL in production
        maxTeamSize: 4,
        description: 'Battlegrounds Mobile India',
      ),
      GameModel(
        id: 'freefire',
        name: 'Free Fire',
        imageUrl: 'https://example.com/freefire.jpg', // This would be a real URL in production
        maxTeamSize: 4,
        description: 'Free Fire Battle Royale',
      ),
      GameModel(
        id: 'valorant',
        name: 'Valorant',
        imageUrl: 'https://example.com/valorant.jpg', // This would be a real URL in production
        maxTeamSize: 5,
        description: 'Valorant Tactical Shooter',
      ),
    ];
  }
}
