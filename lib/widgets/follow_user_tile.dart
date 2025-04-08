import 'package:arena_x/services/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';


class FollowUserTile extends ConsumerStatefulWidget {
  final UserModel user;
  final String currentUserId;
  final VoidCallback? onFollowChanged;

  const FollowUserTile({
    Key? key,
    required this.user,
    required this.currentUserId,
    this.onFollowChanged,
  }) : super(key: key);

  @override
  ConsumerState<FollowUserTile> createState() => _FollowUserTileState();
}

class _FollowUserTileState extends ConsumerState<FollowUserTile> {
  bool _isLoading = false;
  late bool _isFollowing;
  late bool _isFollowedBy;
  late bool _isMutualFollow;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.user.followingIds.contains(widget.currentUserId);
    _isFollowedBy = widget.user.followerIds.contains(widget.currentUserId);
    _isMutualFollow = _isFollowing && _isFollowedBy;
  }

  Future<void> _toggleFollow() async {
    if (widget.currentUserId == widget.user.id) {
      // Don't allow following yourself
      return;
    }

    setState(() => _isLoading = true);

    try {
      final firebaseService = ref.read(firebaseServiceProvider);

      if (_isFollowedBy) {
        // Unfollow
        await firebaseService.unfollowUser(widget.currentUserId, widget.user.id);
        setState(() {
          _isFollowedBy = false;
          _isMutualFollow = _isFollowing && _isFollowedBy;
        });
      } else {
        // Follow
        await firebaseService.followUser(widget.currentUserId, widget.user.id);
        setState(() {
          _isFollowedBy = true;
          _isMutualFollow = _isFollowing && _isFollowedBy;
        });
      }

      // Notify parent to refresh the list
      if (widget.onFollowChanged != null) {
        widget.onFollowChanged!();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: widget.user.profileImageUrl != null
            ? NetworkImage(widget.user.profileImageUrl!)
            : null,
        backgroundColor: Colors.grey[800],
        child: widget.user.profileImageUrl == null
            ? Text(
          widget.user.username.substring(0, 1).toUpperCase(),
          style: const TextStyle(color: Colors.white),
        )
            : null,
      ),
      title: Row(
        children: [
          Text(
            widget.user.username,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (_isMutualFollow)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Icon(
                Icons.verified_user,
                size: 14,
                color: Colors.greenAccent,
              ),
            ),
        ],
      ),
      subtitle: Text(
        _isMutualFollow
            ? 'You follow each other'
            : _isFollowing
            ? 'Follows you'
            : _isFollowedBy
            ? 'You follow'
            : '',
        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
      ),
      trailing: widget.currentUserId == widget.user.id
          ? null // Don't show follow button for the current user
          : _isLoading
          ? const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.greenAccent,
        ),
      )
          : OutlinedButton(
        onPressed: _toggleFollow,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: _isFollowedBy ? Colors.grey : Colors.greenAccent,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          minimumSize: const Size(80, 30),
        ),
        child: Text(
          _isFollowedBy ? 'Unfollow' : 'Follow',
          style: TextStyle(
            color: _isFollowedBy ? Colors.grey : Colors.greenAccent,
            fontSize: 12,
          ),
        ),
      ),
      onTap: () {
        // Navigate to user profile when tapped
        // Implementation depends on how you've set up navigation to profiles
      },
    );
  }
}