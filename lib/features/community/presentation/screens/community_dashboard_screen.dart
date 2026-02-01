import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stake_grow/core/common/loader.dart'; // লোডার ইম্পোর্ট
import 'package:stake_grow/features/community/domain/community_model.dart';
import 'package:stake_grow/features/community/presentation/user_stats_provider.dart'; // প্রোভাইডার ইম্পোর্ট

class CommunityDashboardScreen extends ConsumerWidget {
  final CommunityModel community;

  const CommunityDashboardScreen({
    super.key,
    required this.community,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isAdmin = currentUser != null && currentUser.uid == community.adminId;

    // ✅ User Stats Watch করা হচ্ছে
    final statsAsync = ref.watch(userStatsProvider(community));

    return Scaffold(
      appBar: AppBar(
        title: Text(community.name),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Loader(),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (stats) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero Card: Community Total Fund
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.teal, Colors.tealAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text('Total Community Fund', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 10),
                      Text(
                        '৳ ${community.totalFund.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${community.members.length} Members Active',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 2. Invite Code (Admin Only)
                if (isAdmin) ...[
                  _buildInviteCard(context, community.inviteCode),
                  const SizedBox(height: 24),
                ],

                // ---------------- USER STATS SECTION ----------------
                const Text(
                  "Your Contributions",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 12),

                // 3. User Total Donation Card
                _buildStatCard(
                  icon: Icons.volunteer_activism,
                  color: Colors.blueAccent,
                  title: 'My Total Contribution',
                  value: '৳ ${stats.totalDonated.toStringAsFixed(0)}',
                  subtitle: 'You own ${stats.contributionPercentage.toStringAsFixed(1)}% of the fund',
                ),
                const SizedBox(height: 12),

                // 4. ✅ Subscription Breakdown Card (New Requirement)
                _buildSubscriptionCard(stats),

                const SizedBox(height: 12),

                // 5. Loan Status
                _buildStatCard(
                  icon: Icons.request_quote,
                  color: _getLoanColor(stats.loanStatus),
                  title: 'Recent Loan Status',
                  value: stats.loanStatus,
                  subtitle: 'Status of your latest request',
                ),

                const SizedBox(height: 30),

                // ---------------- ACTION BUTTONS ----------------
                const Text(
                  "Quick Actions",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // ❌ "My Stats" বাটন রিমুভ করা হয়েছে
                    _buildActionButton(Icons.volunteer_activism, 'Donate', () {
                      context.push('/create-donation', extra: community.id);
                    }),
                    _buildActionButton(Icons.request_quote, 'Loan', () {
                      context.push('/create-loan', extra: community.id);
                    }),
                    _buildActionButton(Icons.bar_chart, 'Invest', () {
                      context.push('/create-investment', extra: community.id);
                    }),
                    _buildActionButton(Icons.event, 'Activity', () {
                      context.push('/create-activity', extra: community.id);
                    }),
                    _buildActionButton(Icons.history, 'History', () {
                      context.push('/transaction-history', extra: community.id);
                    }),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Helper Widgets ---

  Color _getLoanColor(String status) {
    switch (status) {
      case 'APPROVED': return Colors.green;
      case 'PENDING': return Colors.orange;
      case 'REJECTED': return Colors.red;
      case 'REPAID': return Colors.blueGrey;
      default: return Colors.grey;
    }
  }

  Widget _buildSubscriptionCard(UserStats stats) {
    bool hasMonthly = stats.monthlyDonated > 0;
    bool hasRandom = stats.randomDonated > 0;

    if (!hasMonthly && !hasRandom) {
      return const SizedBox(); // কিছুই না থাকলে হাইড
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
        ],
        border: Border.all(color: Colors.purple.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.purple.withOpacity(0.1),
                child: const Icon(Icons.pie_chart, color: Colors.purple, size: 24),
              ),
              const SizedBox(width: 15),
              const Text("Donation Breakdown", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 15),

          if (hasMonthly)
            _buildBreakdownRow("Monthly Subscription", stats.monthlyDonated, stats.monthlyPercent),

          if (hasMonthly && hasRandom)
            const Divider(height: 20),

          if (hasRandom)
            _buildBreakdownRow("One-time / Random", stats.randomDonated, stats.randomPercent),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double amount, double percent) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black87)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("৳ ${amount.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("${percent.toStringAsFixed(1)}% of total", style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ],
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

  Widget _buildInviteCard(BuildContext context, String code) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Community Invite Code', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              Text(code, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
            ],
          ),
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code)).then((_) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied! ✅')));
              });
            },
            icon: const Icon(Icons.copy, color: Colors.teal),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
            ),
            child: Icon(icon, color: Colors.teal, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}