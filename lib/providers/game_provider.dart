import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_model.dart';
import '../services/firebase_service.dart';

// Get all games
final gamesProvider = FutureProvider<List<GameModel>>((ref) async {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return await firebaseService.getGames();
});

// Get favorite games by their IDs
final userFavoriteGamesProvider = FutureProvider.family<List<GameModel>, List<String>>((ref, favoriteGameIds) async {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return await firebaseService.getGamesByIds(favoriteGameIds);
});

// Get a single game by ID
final singleGameProvider = FutureProvider.family<GameModel, String>((ref, gameId) async {
  final firebaseService = ref.watch(firebaseServiceProvider);
  final game = await firebaseService.getGameById(gameId);
  return game ?? GameModel(id: gameId, name: 'Unknown Game', maxTeamSize: 4);
});

// Track the currently selected game
final selectedGameProvider = StateProvider<GameModel?>((ref) => null);
