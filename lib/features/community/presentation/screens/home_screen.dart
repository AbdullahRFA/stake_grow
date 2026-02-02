import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stake_grow/core/common/loader.dart';
import 'package:stake_grow/features/auth/data/auth_repository.dart';
import 'package:stake_grow/features/community/presentation/community_controller.dart';
import 'package:stake_grow/features/community/presentation/widgets/community_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. ডাটা স্ট্রিম শোনা (Watch)
    final communitiesAsyncValue = ref.watch(userCommunitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Communities'),
        actions: [
          // ✅ UPDATE: User Account Actions (Profile & Logout)
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, size: 32), // Profile Icon
            onSelected: (value) {
              if (value == 'profile') {
                context.push('/edit-profile'); // Navigate to Edit Profile
              } else if (value == 'logout') {
                ref.read(authRepositoryProvider).logOut(); // Logout Action
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.teal),
                      SizedBox(width: 8),
                      Text('Edit Profile'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Log Out'),
                    ],
                  ),
                ),
              ];
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      // 2. AsyncValue হ্যান্ডলিং (Loading, Error, Data)
      body: communitiesAsyncValue.when(
        loading: () => const Loader(),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (communities) {

          // ক) যদি কোনো কমিউনিটি না থাকে
          if (communities.isEmpty) {
            return const Center(
              child: Text(
                'You haven\'t joined any community yet.\nTap + to create one!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // খ) ডাটা থাকলে লিস্ট দেখানো
          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: communities.length,
            itemBuilder: (context, index) {
              final community = communities[index];
              return CommunityCard(
                community: community,
                onTap: () {
                  context.push('/community-dashboard', extra: community);
                },
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Bottom Sheet দেখানো হবে
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'What do you want to do?',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    ListTile(
                      leading: const Icon(Icons.add_circle, color: Colors.teal, size: 30),
                      title: const Text('Create New Community'),
                      subtitle: const Text('Become an admin of a new fund'),
                      onTap: () {
                        Navigator.pop(context); // বন্ধ করো
                        context.push('/create-community');
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.group_add, color: Colors.blueAccent, size: 30),
                      title: const Text('Join Existing Community'),
                      subtitle: const Text('Enter an invite code to join'),
                      onTap: () {
                        Navigator.pop(context); // বন্ধ করো
                        context.push('/join-community');
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}