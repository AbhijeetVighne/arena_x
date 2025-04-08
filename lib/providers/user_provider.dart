import 'package:arena_x/services/firebase_service.dart';
import 'package:arena_x/services/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

import 'auth_provider.dart';

final userDataProvider = FutureProvider.autoDispose<UserModel?>((ref) async {
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return null;
  }

  final firebaseService = ref.watch(firebaseServiceProvider);
  return await firebaseService.getUserData(user.uid);
});

final userProfileProvider = StateNotifierProvider<UserProfileNotifier, AsyncValue<UserModel?>>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  final user = ref.watch(currentUserProvider);

  return UserProfileNotifier(firebaseService, user?.uid);
});

// User search provider
final userSearchProvider = StateNotifierProvider<UserSearchNotifier, AsyncValue<List<UserModel>>>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return UserSearchNotifier(firebaseService);
});

class UserSearchNotifier extends StateNotifier<AsyncValue<List<UserModel>>> {
  final FirebaseService _firebaseService;

  UserSearchNotifier(this._firebaseService) : super(const AsyncValue.data([]));

  Future<void> searchUsers(String query) async {
    try {
      state = const AsyncValue.loading();
      final results = await _firebaseService.searchUsers(query);
      state = AsyncValue.data(results);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

// User following provider
final userFollowingProvider = FutureProvider.autoDispose<List<UserModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return [];
  }

  final firebaseService = ref.watch(firebaseServiceProvider);
  return await firebaseService.getUserFollowing(user.uid);
});

class UserProfileNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final FirebaseService _firebaseService;
  final String? _userId;

  UserProfileNotifier(this._firebaseService, this._userId) : super(const AsyncValue.loading()) {
    if (_userId != null) {
      _fetchUserData();
    }
  }

  Future<void> _fetchUserData() async {
    try {
      if (_userId == null) {
        state = const AsyncValue.data(null);
        return;
      }

      state = const AsyncValue.loading();
      final userData = await _firebaseService.getUserData(_userId!);
      state = AsyncValue.data(userData);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateWalletBalance(double newBalance) async {
    try {
      if (_userId == null || state.value == null) return;

      final updatedUser = state.value!.copyWith(walletBalance: newBalance);
      await _firebaseService.updateUserData(updatedUser);
      state = AsyncValue.data(updatedUser);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateFavoriteGames(List<String> favoriteGameIds) async {
    try {
      if (_userId == null || state.value == null) return;

      // Check if any games being removed have teams
      final currentFavorites = state.value!.favoriteGameIds;
      final gamesToRemove = currentFavorites.where((gameId) => !favoriteGameIds.contains(gameId)).toList();

      if (gamesToRemove.isNotEmpty) {
        // Check for each game if there are teams
        for (final gameId in gamesToRemove) {
          final teams = await _firebaseService.getUserGameTeams(_userId!, gameId);
          if (teams.isNotEmpty) {
            throw Exception("You have a team for this game. You must leave the team before removing the game from favorites.");
          }
        }
      }

      final updatedUser = state.value!.copyWith(favoriteGameIds: favoriteGameIds);
      await _firebaseService.updateUserData(updatedUser);
      state = AsyncValue.data(updatedUser);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow; // Rethrow the error so the UI can show the error message
    }
  }

  Future<void> refreshUserData() async {
    await _fetchUserData();
  }
}
