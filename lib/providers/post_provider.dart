import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../services/firebase_service.dart';
import 'auth_provider.dart';

final userPostsProvider = FutureProvider.autoDispose<List<PostModel>>((ref) async {
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return [];
  }

  final firebaseService = ref.watch(firebaseServiceProvider);
  return await firebaseService.getUserPosts(user.uid);
});

final postNotifierProvider = StateNotifierProvider<PostNotifier, AsyncValue<List<PostModel>>>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  final user = ref.watch(currentUserProvider);

  return PostNotifier(firebaseService, user?.uid);
});

class PostNotifier extends StateNotifier<AsyncValue<List<PostModel>>> {
  final FirebaseService _firebaseService;
  final String? _userId;

  PostNotifier(this._firebaseService, this._userId) : super(const AsyncValue.loading()) {
    if (_userId != null) {
      _fetchPosts();
    }
  }

  Future<void> _fetchPosts() async {
    try {
      if (_userId == null) {
        state = const AsyncValue.data([]);
        return;
      }

      state = const AsyncValue.loading();
      final posts = await _firebaseService.getUserPosts(_userId!);
      state = AsyncValue.data(posts);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> refreshPosts() async {
    await _fetchPosts();
  }
}
