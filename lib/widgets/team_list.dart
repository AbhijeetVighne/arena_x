import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_model.dart';
import '../models/team_model.dart';
import '../models/user_model.dart';
import '../providers/game_provider.dart';
import '../providers/team_provider.dart';
import '../providers/user_provider.dart';
import '../services/firebase_service.dart';

class TeamList extends ConsumerStatefulWidget {
  final String userId;
  final List<String> favoriteGameIds;

  const TeamList({
    Key? key,
    required this.userId,
    required this.favoriteGameIds,
  }) : super(key: key);

  @override
  ConsumerState<TeamList> createState() => _TeamListState();
}

class _TeamListState extends ConsumerState<TeamList> {
  String? _selectedGameId;
  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _inviteUserController = TextEditingController();

  @override
  void dispose() {
    _teamNameController.dispose();
    _inviteUserController.dispose();
    super.dispose();
  }

  void _showCreateTeamDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Team'),
        backgroundColor: Colors.grey[900],
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select Game',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.greenAccent),
                ),
              ),
              dropdownColor: Colors.grey[900],
              value: _selectedGameId,
              items: widget.favoriteGameIds.map((gameId) {
                // Get each game individually instead of the whole list
                final gameAsync = ref.watch(singleGameProvider(gameId));

                return gameAsync.when(
                  loading: () => DropdownMenuItem(
                    value: gameId,
                    child: const Text('Loading...', style: TextStyle(color: Colors.white)),
                  ),
                  error: (error, stack) => DropdownMenuItem(
                    value: gameId,
                    child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
                  ),
                  data: (game) {
                    return DropdownMenuItem(
                      value: gameId,
                      child: Text(game.name, style: const TextStyle(color: Colors.white)),
                    );
                  },
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGameId = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _teamNameController,
              decoration: const InputDecoration(
                labelText: 'Team Name',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.greenAccent),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
            child: const Text('Create', style: TextStyle(color: Colors.black)),
            onPressed: () {
              if (_selectedGameId == null || _teamNameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select a game and enter a team name'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              // Create the team and handle possible errors
              ref.read(teamNotifierProvider.notifier).createTeam(
                _teamNameController.text.trim(),
                _selectedGameId!,
              ).then((team) {
                // Success case
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Team "${team.name}" created successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
                // Force refresh the teams list
                ref.refresh(userTeamsProvider);
                _teamNameController.clear();
                Navigator.of(context).pop();
              }).catchError((error) {
                // Error case - show error in a dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Colors.grey[900],
                    title: const Text('Error', style: TextStyle(color: Colors.red)),
                    content: Text(
                      error.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK', style: TextStyle(color: Colors.greenAccent)),
                      ),
                    ],
                  ),
                );
              });
            },
          ),
        ],
      ),
    );
  }

  void _showInviteDialog(TeamModel team) {
    final searchResultsProvider = ref.read(userSearchProvider.notifier);
    final followingUsers = ref.read(userFollowingProvider);
    List<String> suggestedUserIds = [];
    String selectedUserId = '';

    // Initialize with suggested users when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      followingUsers.whenData((users) {
        if (users.isNotEmpty) {
          // Get up to 4 suggested users
          suggestedUserIds = users.take(4).map((user) => user.id).toList();
          searchResultsProvider.searchUsers('');
        }
      });
    });

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Invite User to Team'),
          backgroundColor: Colors.grey[900],
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Team: ${team.name}',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _inviteUserController,
                onChanged: (value) {
                  // If user types @, perform a search by username
                  if (value.startsWith('@')) {
                    searchResultsProvider.searchUsers(value.substring(1));
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Search by @username',
                  hintText: 'Enter @username to search',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.greenAccent),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),

              // Show search results
              Consumer(
                builder: (context, ref, child) {
                  final searchResults = ref.watch(userSearchProvider);

                  return searchResults.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
                    error: (error, _) => Text('Error: $error', style: const TextStyle(color: Colors.red)),
                    data: (users) {
                      if (_inviteUserController.text.isNotEmpty && _inviteUserController.text.startsWith('@')) {
                        return Container(
                            constraints: BoxConstraints(maxHeight: 150, maxWidth: 300),
                            child: users.isEmpty
                                ? Center(child: Text('No users found', style: TextStyle(color: Colors.grey)))
                                : Material(
                              color: Colors.transparent,
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const ClampingScrollPhysics(),
                                itemCount: users.length,
                                itemBuilder: (context, index) {
                                  final user = users[index];
                                  return ListTile(
                                    title: Text(user.username, style: const TextStyle(color: Colors.white)),
                                    onTap: () {
                                      setState(() {
                                        selectedUserId = user.id;
                                        _inviteUserController.text = '@${user.username}';
                                      });
                                    },
                                    selected: selectedUserId == user.id,
                                    selectedTileColor: Colors.greenAccent.withOpacity(0.3),
                                  );
                                },
                              ),
                            ),
                        );
                        } else if (suggestedUserIds.isNotEmpty) {
                          // Show suggested users from following list
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            const Text(
                            'Suggested Users:',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                      const SizedBox(height: 8),
                      Container(
                      constraints: BoxConstraints(maxHeight: 150, maxWidth: 300),
                      child: suggestedUserIds.isEmpty
                      ? Center(child: Text('No suggestions', style: TextStyle(color: Colors.grey)))
                          : Material(
                      color: Colors.transparent,
                      child: ListView.builder(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: suggestedUserIds.length,
                      itemBuilder: (context, index) {
                      final userId = suggestedUserIds[index];
                      return FutureBuilder<UserModel?>(
                      future: ref.read(firebaseServiceProvider).getUserData(userId),
                      builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                      final user = snapshot.data!;
                      return ListTile(
                      title: Text(user.username, style: const TextStyle(color: Colors.white)),
                      leading: user.profileImageUrl != null
                      ? CircleAvatar(backgroundImage: NetworkImage(user.profileImageUrl!))
                          : const CircleAvatar(child: Icon(Icons.person)),
                      onTap: () {
                      setState(() {
                      selectedUserId = user.id;
                      _inviteUserController.text = '@${user.username}';
                      });
                      },
                      selected: selectedUserId == user.id,
                      selectedTileColor: Colors.greenAccent.withOpacity(0.3),
                      );
                      }
                      return const ListTile(
                      title: Text('Loading...', style: TextStyle(color: Colors.grey)),
                      );
                      },
                      );
                      },
                      ),
                      ),
                      ),
                      ],
                      );
                      }

                      return const SizedBox.shrink();
                    },
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
              child: const Text('Invite', style: TextStyle(color: Colors.black)),
              onPressed: () {
                if (selectedUserId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a user to invite'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                ref.read(teamNotifierProvider.notifier).inviteToTeam(
                  team.id,
                  selectedUserId,
                ).then((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invitation sent!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                });

                _inviteUserController.clear();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(userTeamsProvider);

    return teamsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (teams) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Team Creation Button
              if (widget.favoriteGameIds.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: _showCreateTeamDialog,
                  icon: const Icon(Icons.add, color: Colors.black),
                  label: const Text('Create New Team', style: TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                )
              else
                Card(
                  color: Colors.grey[900],
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Add a game in the Games tab to create a team',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Teams Display
              Expanded(
                child: teams.isEmpty
                    ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No teams yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Create a team to start playing together',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  itemCount: teams.length,
                  itemBuilder: (context, index) {
                    final team = teams[index];
                    return _buildTeamCard(team);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLeaveTeamDialog(TeamModel team) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Leave Team', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to leave this team? If you are the only member, the team will be deleted.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              final teamNotifier = ref.read(teamNotifierProvider.notifier);
              teamNotifier.leaveTeam(team.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('You have left the team'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
            child: const Text('Leave', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard(TeamModel team) {
    final gamesAsync = ref.watch(gamesProvider);

    return gamesAsync.when(
      loading: () => const Card(
        margin: EdgeInsets.only(bottom: 12),
        child: ListTile(
          title: Text('Loading team...', style: TextStyle(color: Colors.white)),
        ),
      ),
      error: (error, stack) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          title: Text('Error: $error', style: const TextStyle(color: Colors.red)),
        ),
      ),
      data: (games) {
        final game = games.firstWhere(
              (g) => g.id == team.gameId,
          orElse: () => GameModel(id: team.gameId, name: 'Unknown Game', maxTeamSize: 4),
        );

        return Card(
          color: Colors.grey[900],
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      team.name,
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      game.name,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Members: ${team.memberIds.length}/${game.maxTeamSize}',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        // Leave Team button
                        ElevatedButton.icon(
                          onPressed: () => _showLeaveTeamDialog(team),
                          icon: const Icon(Icons.exit_to_app, size: 16, color: Colors.black),
                          label: const Text('Leave', style: TextStyle(color: Colors.black)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: const Size(80, 30),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Invite button (only for team creator)
                        if (team.createdBy == widget.userId && team.memberIds.length < game.maxTeamSize)
                          ElevatedButton.icon(
                            onPressed: () => _showInviteDialog(team),
                            icon: const Icon(Icons.person_add, size: 16, color: Colors.black),
                            label: const Text('Invite', style: TextStyle(color: Colors.black)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: const Size(80, 30),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
