import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_model.dart';
import '../providers/game_provider.dart';
import '../providers/team_provider.dart';

class GameList extends ConsumerStatefulWidget {
  final String userId;
  final List<String> favoriteGameIds;
  final Function(List<String>) onGamesUpdated;

  const GameList({
    Key? key,
    required this.userId,
    required this.favoriteGameIds,
    required this.onGamesUpdated,
  }) : super(key: key);

  @override
  ConsumerState<GameList> createState() => _GameListState();
}

class _GameListState extends ConsumerState<GameList> {
  late List<String> _selectedGameIds;

  @override
  void initState() {
    super.initState();
    _selectedGameIds = List.from(widget.favoriteGameIds);
  }

  @override
  void didUpdateWidget(GameList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.favoriteGameIds != widget.favoriteGameIds) {
      setState(() {
        _selectedGameIds = List.from(widget.favoriteGameIds);
      });
    }
  }

  void _toggleGameSelection(String gameId) async {
    // If trying to remove a game, check if there are teams for it
    if (_selectedGameIds.contains(gameId)) {
      // Force refresh the teams list to ensure we have the latest data
      // This will make sure we don't see teams that the user has already left
      ref.invalidate(gameTeamsProvider(gameId));

      // Check if user has teams for this game before allowing removal
      final gameTeams = await ref.read(gameTeamsProvider(gameId).future);

      if (gameTeams.isNotEmpty) {
        // Show a proper dialog instead of a snackbar
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Cannot Remove Game',
              style: TextStyle(color: Colors.red),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This game has active teams associated with it:',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                // List the teams that exist for this game
                ...gameTeams.map((team) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.group, color: Colors.greenAccent, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        team.name,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.grey),
                    children: [
                      const TextSpan(
                        text: 'You must leave these teams before removing this game from your favorites. Go to the ',
                      ),
                      TextSpan(
                        text: 'Teams',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(
                        text: ' tab to leave a team.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK', style: TextStyle(color: Colors.greenAccent)),
              ),
            ],
          ),
        );
        return;
      }

      setState(() {
        _selectedGameIds.remove(gameId);
        widget.onGamesUpdated(_selectedGameIds);
      });
    } else {
      // Adding a game
      if (_selectedGameIds.length >= 3) {
        // Show dialog for max games reached
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Maximum Games Reached',
              style: TextStyle(color: Colors.orange),
            ),
            content: const Text(
              'You can select up to 3 favorite games. Please remove a game before adding a new one.',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK', style: TextStyle(color: Colors.greenAccent)),
              ),
            ],
          ),
        );
        return;
      }

      setState(() {
        _selectedGameIds.add(gameId);
        widget.onGamesUpdated(_selectedGameIds);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gamesAsync = ref.watch(gamesProvider);

    return gamesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (games) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Your Favorite Games (max 3)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You have selected ${_selectedGameIds.length}/3 games',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: games.length,
                  itemBuilder: (context, index) {
                    final game = games[index];
                    final isSelected = _selectedGameIds.contains(game.id);

                    return Card(
                      color: Colors.grey[900],
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected ? Colors.greenAccent : Colors.grey[800],
                          child: game.imageUrl != null
                              ? null
                              : Icon(
                            Icons.sports_esports,
                            color: isSelected ? Colors.black : Colors.white,
                          ),
                          backgroundImage: game.imageUrl != null
                              ? NetworkImage(game.imageUrl!)
                              : null,
                        ),
                        title: Text(
                          game.name,
                          style: TextStyle(
                            color: isSelected ? Colors.greenAccent : Colors.white,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          game.description ?? 'Team Size: ${game.maxTeamSize}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                        trailing: isSelected
                            ? IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                          onPressed: () => _toggleGameSelection(game.id),
                        )
                            : IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.greenAccent),
                          onPressed: () => _toggleGameSelection(game.id),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
