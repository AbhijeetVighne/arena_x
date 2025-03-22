import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../widgets/follow_user_tile.dart';

enum FollowScreenType { followers, following }

class FollowScreen extends ConsumerStatefulWidget {
  final String userId;
  final FollowScreenType type;

  const FollowScreen({
    Key? key,
    required this.userId,
    required this.type,
  }) : super(key: key);

  @override
  ConsumerState<FollowScreen> createState() => _FollowScreenState();
}

class _FollowScreenState extends ConsumerState<FollowScreen> {
  List<UserModel> _users = [];
  bool _isLoading = false;
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      final firebaseService = ref.read(firebaseServiceProvider);

      // Get the current user ID
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        _currentUserId = currentUser.uid;
      }

      // Get the user whose followers/following we're viewing
      final targetUser = await firebaseService.getUserData(widget.userId);
      if (targetUser == null) {
        throw Exception('User not found');
      }

      // Get the IDs of users we need to fetch
      final List<String> userIds = widget.type == FollowScreenType.followers
          ? targetUser.followerIds
          : targetUser.followingIds;

      // Fetch all users
      final users = await Future.wait(
        userIds.map((id) => firebaseService.getUserData(id)).toList(),
      );

      setState(() {
        _users = users.whereType<UserModel>().toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _refreshUsers() {
    _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.type == FollowScreenType.followers
        ? 'Followers'
        : 'Following';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
          : _users.isEmpty
          ? Center(
        child: Text(
          widget.type == FollowScreenType.followers
              ? 'No followers yet'
              : 'Not following anyone yet',
          style: TextStyle(color: Colors.grey[400]),
        ),
      )
          : ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          return FollowUserTile(
            user: _users[index],
            currentUserId: _currentUserId,
            onFollowChanged: _refreshUsers,
          );
        },
      ),
    );
  }
}