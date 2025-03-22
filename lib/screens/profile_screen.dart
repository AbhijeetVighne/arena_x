import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../providers/post_provider.dart';
import '../providers/game_provider.dart';
import '../providers/team_provider.dart';
import '../services/payment_service.dart';
import '../widgets/profile_header.dart';
import '../widgets/stat_counter.dart';
import '../widgets/post_grid.dart';
import '../widgets/game_list.dart';
import '../widgets/team_list.dart';
import 'follow_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddFundsDialog(UserModel user) {
    final paymentService = ref.read(paymentServiceProvider);
    double amount = 100; // Default amount

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Funds to Wallet'),
        backgroundColor: Colors.grey[900],
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Balance: ₹${user.walletBalance.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 20),
            Text('Enter Amount to Add:', style: const TextStyle(color: Colors.white)),
            Slider(
              value: amount,
              min: 100,
              max: 5000,
              divisions: 49,
              label: '₹${amount.toInt()}',
              activeColor: Colors.greenAccent,
              onChanged: (value) {
                setState(() {
                  amount = value;
                });
              },
            ),
            Text('₹${amount.toInt()}',
                style: const TextStyle(color: Colors.greenAccent, fontSize: 24)),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
            child: const Text('Add Funds', style: TextStyle(color: Colors.black)),
            onPressed: () {
              Navigator.of(context).pop();

              paymentService.openCheckout(
                user: user,
                amount: amount,
                onSuccess: (newBalance) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added ₹${amount.toInt()} successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // The user provider will be updated by the payment service
                },
                onError: (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.greenAccent),
            onPressed: () {
              ref.read(userProfileProvider.notifier).refreshUserData();
              ref.read(postNotifierProvider.notifier).refreshPosts();
              ref.read(teamNotifierProvider.notifier).refreshTeams();
            },
          ),
        ],
      ),
      body: userProfile.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User not found'));
          }

          return Column(
            children: [
              // Profile Header with Wallet
              ProfileHeader(
                user: user,
                onAddFunds: () => _showAddFundsDialog(user),
              ),

              // Stats Row (Posts, Followers, Following, etc.)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    StatCounter(label: 'Posts', count: user.posts),
                    StatCounter(
                        label: 'Followers',
                        count: user.followers,
                        isTappable: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FollowScreen(
                                userId: user.id,
                                type: FollowScreenType.followers,
                              ),
                            ),
                          );
                        }
                    ),
                    StatCounter(
                        label: 'Following',
                        count: user.following,
                        isTappable: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FollowScreen(
                                userId: user.id,
                                type: FollowScreenType.following,
                              ),
                            ),
                          );
                        }
                    ),
                    StatCounter(label: 'Matches', count: user.matchesPlayed),
                    StatCounter(label: 'Wins', count: user.matchesWon),
                    StatCounter(label: 'Coupons', count: user.coupons),
                  ],
                ),
              ),

              // Tab Bar
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Posts'),
                  Tab(text: 'Games'),
                  Tab(text: 'Team'),
                ],
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Posts Tab
                    PostGrid(userId: user.id),

                    // Games Tab
                    GameList(
                      userId: user.id,
                      favoriteGameIds: user.favoriteGameIds,
                      onGamesUpdated: (newGameIds) {
                        ref.read(userProfileProvider.notifier)
                            .updateFavoriteGames(newGameIds);
                      },
                    ),

                    // Team Tab
                    TeamList(
                      userId: user.id,
                      favoriteGameIds: user.favoriteGameIds,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
