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
          IconButton(
            onPressed: () {
              ref.read(authRepositoryProvider).logOut();
            },
            icon: const Icon(Icons.logout),
          ),
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
                  // এখানে আমরা পরে ড্যাশবোর্ডে যাওয়ার কোড লিখব
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Opening ${community.name}...')),
                  );
                },
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/create-community'),
        child: const Icon(Icons.add),
      ),
    );
  }
}