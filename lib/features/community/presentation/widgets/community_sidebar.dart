import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stake_grow/features/community/domain/community_model.dart';
import 'package:stake_grow/features/community/presentation/user_stats_provider.dart';
import 'package:stake_grow/features/loan/domain/loan_model.dart';
import 'personal_detail_screen.dart';

class CommunitySidebar extends ConsumerWidget {
  final CommunityModel community;
  final UserStats stats;
  final List<LoanModel> allLoans;
  final List<LoanModel> myLoans;

  const CommunitySidebar({
    super.key,
    required this.community,
    required this.stats,
    required this.allLoans,
    required this.myLoans,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = user != null && (user.uid == community.adminId || community.mods.contains(user.uid));

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Colors.teal),
            accountName: Text(user?.displayName ?? "User"),
            accountEmail: Text(user?.email ?? ""),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.teal.shade800, size: 40),
            ),
          ),
          _buildSidebarItem(
            context,
            icon: Icons.pie_chart,
            title: "Donation Breakdown",
            onTap: () => _navigateToDetail(context, "Donation Breakdown"),
          ),
          _buildSidebarItem(
            context,
            icon: Icons.trending_up,
            title: "Portfolio & Activities",
            onTap: () => _navigateToDetail(context, "Portfolio & Activities"),
          ),
          _buildSidebarItem(
            context,
            icon: Icons.handshake,
            title: "Money Locked in Loans",
            onTap: () => _navigateToDetail(context, "Money Locked in Loans"),
          ),
          _buildSidebarItem(
            context,
            icon: Icons.volunteer_activism,
            title: "My Expense Contribution",
            onTap: () => _navigateToDetail(context, "My Expense Contribution"),
          ),
          // My Loans Section
          _buildSidebarItem(
            context,
            icon: Icons.account_balance_wallet,
            title: "My Loans",
            onTap: () => _navigateToDetail(context, "My Loans"),
          ),
          // Community Loans (Admin Only)
          if (isAdmin)
            _buildSidebarItem(
              context,
              icon: Icons.admin_panel_settings,
              title: "Community Loans",
              onTap: () => _navigateToDetail(context, "Community Loans"),
            ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout"),
            onTap: () => FirebaseAuth.instance.signOut(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  void _navigateToDetail(BuildContext context, String type) {
    Navigator.pop(context); // Close Drawer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonalDetailScreen(
          type: type,
          community: community,
          stats: stats,
          allLoans: allLoans,
          myLoans: myLoans,
        ),
      ),
    );
  }
}