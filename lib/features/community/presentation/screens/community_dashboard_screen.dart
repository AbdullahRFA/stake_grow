import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stake_grow/core/common/loader.dart';
import 'package:stake_grow/features/community/domain/community_model.dart';
import 'package:stake_grow/features/community/presentation/user_stats_provider.dart';
import 'package:stake_grow/features/donation/domain/donation_model.dart';
import 'package:stake_grow/features/loan/domain/loan_model.dart';

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
                // 1. Hero Card
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
                      BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text('Total Community Fund', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 10),
                      Text('৳ ${community.totalFund.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text('${community.members.length} Members Active', style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Invite Code (Admin)
                if (isAdmin) ...[
                  _buildInviteCard(context, community.inviteCode),
                  const SizedBox(height: 24),
                ],

                // 3. Contribution Card
                const Text("Your Contributions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 12),
                _buildStatCard(
                  icon: Icons.volunteer_activism,
                  color: Colors.blueAccent,
                  title: 'My Total Contribution',
                  value: '৳ ${stats.totalDonated.toStringAsFixed(0)}',
                  subtitle: 'You own ${stats.contributionPercentage.toStringAsFixed(1)}% of the fund',
                ),
                const SizedBox(height: 12),

                // 4. Subscription Breakdown
                _buildSubscriptionCard(context, stats),
                const SizedBox(height: 12),

                // 5. ✅ Updated Loan Overview Card
                _buildLoanSummaryCard(context, stats),
                const SizedBox(height: 30),

                // 6. Quick Actions
                const Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionButton(Icons.volunteer_activism, 'Donate', () { context.push('/create-donation', extra: community.id); }),
                    _buildActionButton(Icons.request_quote, 'Loan', () { context.push('/create-loan', extra: community.id); }),
                    _buildActionButton(Icons.bar_chart, isAdmin ? 'Invest' : 'Investments', () {
                      if (isAdmin) { context.push('/create-investment', extra: community.id); }
                      else { context.push('/investment-history', extra: community.id); }
                    }),
                    _buildActionButton(Icons.event, isAdmin ? 'Activity' : 'Activities', () {
                      if (isAdmin) { context.push('/create-activity', extra: community.id); }
                      else { context.push('/activity-history', extra: community.id); }
                    }),
                    if (isAdmin) _buildActionButton(Icons.history, 'History', () { context.push('/transaction-history', extra: community.id); }),
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

  // --- Helper Methods ---

  void _showDonationDetails(BuildContext context, String title, List<DonationModel> donations) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Divider(),
              Expanded(
                child: donations.isEmpty
                    ? const Center(child: Text("No records found."))
                    : ListView.builder(
                  itemCount: donations.length,
                  itemBuilder: (context, index) {
                    final donation = donations[index];
                    return ListTile(
                      leading: const Icon(Icons.check_circle, color: Colors.green),
                      title: Text('Amount: ৳${donation.amount}'),
                      subtitle: Text(DateFormat('dd MMM yyyy, hh:mm a').format(donation.timestamp)),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLoanDetails(BuildContext context, String title, List<LoanModel> loans) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Divider(),
              Expanded(
                child: loans.isEmpty
                    ? const Center(child: Text("No loans found."))
                    : ListView.builder(
                  itemCount: loans.length,
                  itemBuilder: (context, index) {
                    final loan = loans[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getLoanColor(loan.status).withOpacity(0.2),
                          child: Icon(Icons.request_quote, color: _getLoanColor(loan.status)),
                        ),
                        title: Text('৳${loan.amount} - ${loan.status.toUpperCase()}'),
                        subtitle: Text('Reason: ${loan.reason}\nDate: ${DateFormat('dd MMM yyyy').format(loan.requestDate)}'),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getLoanColor(String status) {
    switch (status) {
      case 'approved': return Colors.redAccent; // Active Debt (Red indicates due)
      case 'pending': return Colors.orange;
      case 'repaid': return Colors.green;
      default: return Colors.grey;
    }
  }

  // ✅ New Loan Summary Card
  Widget _buildLoanSummaryCard(BuildContext context, UserStats stats) {
    bool hasPending = stats.pendingLoans.isNotEmpty;
    bool hasActive = stats.activeLoans.isNotEmpty;
    bool hasRepaid = stats.repaidLoans.isNotEmpty;

    if (!hasPending && !hasActive && !hasRepaid) {
      return _buildStatCard(
        icon: Icons.request_quote,
        color: Colors.grey,
        title: 'Loan Status',
        value: 'No History',
        subtitle: 'You have no loan records yet',
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.indigo.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.indigo.withOpacity(0.1),
                  child: const Icon(Icons.account_balance_wallet, color: Colors.indigo, size: 24),
                ),
                const SizedBox(width: 15),
                const Text("Loan Overview", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),

          if (hasActive)
            InkWell(
              onTap: () => _showLoanDetails(context, "Active Loans (To be Repaid)", stats.activeLoans),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: _buildBreakdownRow(
                    "Active Debt (Unpaid)",
                    stats.activeLoanAmount,
                    "${stats.activeLoans.length} Active",
                    Colors.redAccent
                ),
              ),
            ),

          if (hasActive && (hasPending || hasRepaid)) const Divider(height: 1),

          if (hasPending)
            InkWell(
              onTap: () => _showLoanDetails(context, "Pending Requests", stats.pendingLoans),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: _buildBreakdownRow(
                    "Pending Requests",
                    stats.pendingLoans.fold(0, (sum, item) => sum + item.amount),
                    "${stats.pendingLoans.length} Pending",
                    Colors.orange
                ),
              ),
            ),

          if (hasPending && hasRepaid) const Divider(height: 1),

          if (hasRepaid)
            InkWell(
              onTap: () => _showLoanDetails(context, "Repaid History", stats.repaidLoans),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: _buildBreakdownRow(
                    "Repaid Loans",
                    stats.repaidLoans.fold(0, (sum, item) => sum + item.amount),
                    "${stats.repaidLoans.length} Repaid",
                    Colors.green
                ),
              ),
            ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, UserStats stats) {
    // ... (Previous implementation remains same)
    bool hasMonthly = stats.monthlyDonated > 0;
    bool hasRandom = stats.randomDonated > 0;
    if (!hasMonthly && !hasRandom) return const SizedBox();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.purple.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
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
          ),
          if (hasMonthly)
            InkWell(
              onTap: () => _showDonationDetails(context, "Monthly Subscriptions", stats.monthlyList),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: _buildBreakdownRow("Monthly Subscription", stats.monthlyDonated, "${stats.monthlyPercent.toStringAsFixed(1)}% of total", Colors.black87),
              ),
            ),
          if (hasMonthly && hasRandom) const Divider(height: 1),
          if (hasRandom)
            InkWell(
              onTap: () => _showDonationDetails(context, "Random / One-time", stats.randomList),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: _buildBreakdownRow("One-time / Random", stats.randomDonated, "${stats.randomPercent.toStringAsFixed(1)}% of total", Colors.black87),
              ),
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double amount, String subLabel, Color labelColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(label, style: TextStyle(color: labelColor, fontWeight: FontWeight.w500)),
            const SizedBox(width: 5),
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("৳ ${amount.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(subLabel, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({required IconData icon, required Color color, required String title, required String value, required String subtitle, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            CircleAvatar(radius: 25, backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 28)),
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
      ),
    );
  }

  // _buildInviteCard and _buildActionButton remains same...
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