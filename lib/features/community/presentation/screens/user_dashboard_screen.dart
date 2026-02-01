import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stake_grow/core/common/loader.dart';
import 'package:stake_grow/features/community/domain/community_model.dart';
import 'package:stake_grow/features/community/presentation/user_stats_provider.dart';

class UserDashboardScreen extends ConsumerWidget {
  final CommunityModel community;
  const UserDashboardScreen({super.key, required this.community});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider(community));

    return Scaffold(
      appBar: AppBar(title: const Text('My Dashboard')),
      body: statsAsync.when(
        loading: () => const Loader(),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (stats) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 1. Donation Overview Card
                _buildStatCard(
                  icon: Icons.volunteer_activism,
                  color: Colors.teal,
                  title: 'Total Donation',
                  value: '৳ ${stats.totalDonated.toStringAsFixed(0)}',
                  subtitle: 'You contributed ${stats.contributionPercentage.toStringAsFixed(1)}% of total fund',
                ),
                const SizedBox(height: 16),

                // 2. Subscription Status
                _buildStatCard(
                  icon: Icons.card_membership,
                  color: stats.subscriptionStatus.contains('Paid') ? Colors.green : Colors.orange,
                  title: 'Subscription Status',
                  value: stats.subscriptionStatus,
                  subtitle: 'Monthly contribution status',
                ),
                const SizedBox(height: 16),

                // 3. Loan Status
                _buildStatCard(
                  icon: Icons.request_quote,
                  color: Colors.blueAccent,
                  title: 'Loan Status',
                  value: stats.loanStatus,
                  subtitle: 'Status of your most recent loan request',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 5),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(subtitle, style: TextStyle(fontSize: 12, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}