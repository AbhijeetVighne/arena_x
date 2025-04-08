import 'package:arena_x/services/firebase_service.dart';
import 'package:arena_x/services/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/team_model.dart';

import 'auth_provider.dart';

// Get teams for the current user with auto-refresh
final userTeamsProvider = AutoDisposeFutureProvider<List<TeamModel>>((ref) async {
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return [];
  }

  final firebaseService = ref.watch(firebaseServiceProvider);
  return await firebaseService.getUserTeams(user.uid);
});

// Get teams for a specific game
final gameTeamsProvider = FutureProvider.family<List<TeamModel>, String>((ref, gameId) async {
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return [];
  }

  final firebaseService = ref.watch(firebaseServiceProvider);
  return await firebaseService.getUserGameTeams(user.uid, gameId);
});

final teamNotifierProvider = StateNotifierProvider<TeamNotifier, AsyncValue<List<TeamModel>>>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  final user = ref.watch(currentUserProvider);

  return TeamNotifier(firebaseService, user?.uid);
});

class TeamNotifier extends StateNotifier<AsyncValue<List<TeamModel>>> {
  final FirebaseService _firebaseService;
  final String? _userId;

  TeamNotifier(this._firebaseService, this._userId) : super(const AsyncValue.loading()) {
    if (_userId != null) {
      _fetchTeams();
    }
  }

  Future<void> _fetchTeams() async {
    try {
      if (_userId == null) {
        state = const AsyncValue.data([]);
        return;
      }

      state = const AsyncValue.loading();
      final teams = await _firebaseService.getUserTeams(_userId!);
      state = AsyncValue.data(teams);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<TeamModel> createTeam(String name, String gameId) async {
    try {
      if (_userId == null) throw Exception("User not authenticated");

      // Check if user already has a team for this game
      final userGameTeams = await _firebaseService.getUserGameTeams(_userId!, gameId);
      if (userGameTeams.isNotEmpty) {
        throw Exception("You already have a team for this game. You can only have one team per game.");
      }

      final newTeam = await _firebaseService.createTeam(
        name: name,
        gameId: gameId,
        createdBy: _userId!,
      );

      // Update state with new team
      final currentTeams = [...(state.value ?? <TeamModel>[])];
      currentTeams.add(newTeam);
      state = AsyncValue.data(currentTeams);

      // Return the created team
      return newTeam;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> inviteToTeam(String teamId, String invitedUserId) async {
    try {
      await _firebaseService.inviteToTeam(teamId, invitedUserId);
      await _fetchTeams(); // Refresh teams list
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> refreshTeams() async {
    await _fetchTeams();
  }

  Future<void> leaveTeam(String teamId) async {
    try {
      if (_userId == null) throw Exception("User not authenticated");

      await _firebaseService.leaveTeam(teamId, _userId!);
      await _fetchTeams(); // Refresh teams list after leaving
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}
