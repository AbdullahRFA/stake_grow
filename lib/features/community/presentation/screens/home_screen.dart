import 'package:firebase_auth/firebase_auth.dart'; // Ensure Firebase Auth is imported
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stake_grow/core/common/loader.dart';
import 'package:stake_grow/features/auth/data/auth_repository.dart';
import 'package:stake_grow/features/community/presentation/community_controller.dart';
import 'package:stake_grow/features/community/presentation/widgets/community_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communitiesAsyncValue = ref.watch(userCommunitiesProvider);
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    // Dynamic Greeting Logic
    final String greeting = _getGreeting();
    final String userName = user?.displayName?.split(' ').first ?? 'User';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Premium Sliver App Bar with Dynamic Greeting
          SliverAppBar(
            expandedHeight: 160.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.teal.shade700,
            centerTitle: false,
            titleSpacing: 20,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$greeting, \n',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                      ),
                    ),
                    TextSpan(
                      text: userName,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.teal.shade800, Colors.teal.shade400],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -50,
                    right: -50,
                    child: CircleAvatar(
                      radius: 100,
                      backgroundColor: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildProfileMenu(context, ref),
              ),
            ],
          ),

          // 2. Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.teal,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Your Circles",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.blueGrey.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Content Body
          communitiesAsyncValue.when(
            loading: () => const SliverFillRemaining(child: Center(child: Loader())),
            error: (error, stack) => SliverFillRemaining(
              child: Center(
                child: Text('Failed to load communities', style: theme.textTheme.bodyLarge),
              ),
            ),
            data: (communities) {
              if (communities.isEmpty) {
                return _buildEmptyState(context);
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final community = communities[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CommunityCard(
                          community: community,
                          onTap: () {
                            context.push('/community-dashboard', extra: community);
                          },
                        ),
                      );
                    },
                    childCount: communities.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showActionBottomSheet(context),
        backgroundColor: Colors.teal.shade700,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          "Create / Join",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  // --- Profile Menu with Corrected Alignment ---
  Widget _buildProfileMenu(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
        ),
        child: const CircleAvatar(
          backgroundColor: Colors.white24,
          radius: 18,
          child: Icon(Icons.person_outline, color: Colors.white, size: 20),
        ),
      ),
      onSelected: (value) {
        if (value == 'profile') {
          context.push('/edit-profile');
        } else if (value == 'logout') {
          ref.read(authRepositoryProvider).logOut();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: ListTile(
            leading: const Icon(Icons.settings_outlined, color: Colors.teal),
            title: Text('Edit Profile', style: GoogleFonts.poppins(fontSize: 14)),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: Text('Sign Out', style: GoogleFonts.poppins(fontSize: 14, color: Colors.redAccent)),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.bubble_chart_outlined, size: 100, color: Colors.teal.shade200),
            ),
            const SizedBox(height: 24),
            Text(
              'No communities yet',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Join a circle or start your own fund\nto begin your journey.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.blueGrey.shade400, height: 1.5),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showActionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Launch Growth",
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 24),
            _buildActionTile(
              context,
              icon: Icons.add_business_rounded,
              color: Colors.teal,
              title: 'Create New Community',
              subtitle: 'Lead a circle and manage shared funds',
              onTap: () => context.push('/create-community'),
            ),
            const SizedBox(height: 12),
            _buildActionTile(
              context,
              icon: Icons.group_add_rounded,
              color: Colors.indigo,
              title: 'Join with Code',
              subtitle: 'Use an invite code to enter a circle',
              onTap: () => context.push('/join-community'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
      BuildContext context, {
        required IconData icon,
        required Color color,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: color.withOpacity(0.04),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.blueGrey.shade400)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.blueGrey),
          ],
        ),
      ),
    );
  }
}