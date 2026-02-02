import 'dart:async';
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
import 'package:stake_grow/features/loan/presentation/loan_controller.dart';

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
            onPressed: () {
              context.push('/settings', extra: community);
            },
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

                // 2. Due/Warning Card with Live Clock
                DueWarningCard(stats: stats),
                const SizedBox(height: 16),

                // 3. Invite Code (Admin)
                if (isAdmin) ...[
                  _buildInviteCard(context, community.inviteCode),
                  const SizedBox(height: 24),
                ],

                // 4. Contribution Card
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

                // 5. Subscription Breakdown
                _buildSubscriptionCard(context, stats),
                const SizedBox(height: 16),

                // ✅ 6. Investment Overview Card (Updated: Always Visible)
                _buildInvestmentCard(context, stats, community),
                const SizedBox(height: 16),

                // 7. My Loan Overview
                _buildLoanSummaryCard(context, stats, ref),
                const SizedBox(height: 30),

                // 8. Quick Actions
                const Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionButton(Icons.volunteer_activism, 'Donate', () {
                      context.push('/create-donation', extra: {
                        'communityId': community.id,
                        'isMonthlyDisabled': stats.isCurrentMonthPaid,
                      });
                    }),

                    _buildActionButton(Icons.request_quote, 'Loan', () { context.push('/create-loan', extra: community.id); }),

                    // Admin creates, Members view history (Button Label differs)
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

  // --- Helper Widgets ---

  // ✅ UPDATED: Investment Overview (Visible to All)
  Widget _buildInvestmentCard(BuildContext context, UserStats stats, CommunityModel community) {
    // 🔴 Removed the 'if (stats.lockedInInvestment == 0)' check to show always

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: Colors.orange, size: 28),
              const SizedBox(width: 10),
              const Text("Active Investments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("My Invested Amount", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text("৳ ${stats.lockedInInvestment.toStringAsFixed(0)}",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("Exp. Profit Share", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text("~ ৳ ${stats.activeInvestmentProfitExpectation.toStringAsFixed(0)}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(),
          InkWell(
            onTap: () => context.push('/investment-history', extra: community.id),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("View Investment Details", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                  Icon(Icons.arrow_forward, size: 16, color: Colors.orange),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLoanSummaryCard(BuildContext context, UserStats stats, WidgetRef ref) {
    bool hasPending = stats.pendingLoans.isNotEmpty;
    bool hasActive = stats.activeLoans.isNotEmpty;
    bool hasRepaid = stats.repaidLoans.isNotEmpty;

    if (!hasPending && !hasActive && !hasRepaid) {
      return _buildStatCard(
        icon: Icons.request_quote,
        color: Colors.grey,
        title: 'My Loans',
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
                const Text("My Loans", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          if (hasActive)
            InkWell(
              onTap: () => _showLoanDetails(context, "Active Loans (To be Repaid)", stats.activeLoans, ref, false),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: _buildBreakdownRow("Active Debt (Unpaid)", stats.activeLoanAmount, "${stats.activeLoans.length} Active", Colors.redAccent),
              ),
            ),
          if (hasActive && (hasPending || hasRepaid)) const Divider(height: 1),
          if (hasPending)
            InkWell(
              onTap: () => _showLoanDetails(context, "Pending Requests", stats.pendingLoans, ref, true),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: _buildBreakdownRow("Pending Requests", stats.pendingLoans.fold(0, (sum, item) => sum + item.amount), "${stats.pendingLoans.length} Pending", Colors.orange),
              ),
            ),
          if (hasPending && hasRepaid) const Divider(height: 1),
          if (hasRepaid)
            InkWell(
              onTap: () => _showLoanDetails(context, "Repaid History", stats.repaidLoans, ref, false),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: _buildBreakdownRow("Repaid Loans", stats.repaidLoans.fold(0, (sum, item) => sum + item.amount), "${stats.repaidLoans.length} Repaid", Colors.green),
              ),
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void _showLoanDetails(BuildContext context, String title, List<LoanModel> loans, WidgetRef ref, bool isEditable) {
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
                        trailing: isEditable
                            ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.pop(context); // Close sheet
                                _showEditDialog(context, ref, loan);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                ref.read(loanControllerProvider.notifier).deleteLoan(loan.id, context);
                                Navigator.pop(context); // Close sheet
                              },
                            ),
                          ],
                        )
                            : null,
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

  void _showEditDialog(BuildContext context, WidgetRef ref, LoanModel loan) {
    final amountController = TextEditingController(text: loan.amount.toString());
    final reasonController = TextEditingController(text: loan.reason);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Loan Request"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Amount (৳)"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: "Reason"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final newAmount = double.tryParse(amountController.text) ?? loan.amount;
              final newReason = reasonController.text.trim();

              final updatedLoan = LoanModel(
                id: loan.id,
                communityId: loan.communityId,
                borrowerId: loan.borrowerId,
                borrowerName: loan.borrowerName,
                amount: newAmount,
                reason: newReason,
                requestDate: loan.requestDate,
                repaymentDate: loan.repaymentDate,
                status: loan.status,
              );

              ref.read(loanControllerProvider.notifier).updateLoan(updatedLoan, ctx);
            },
            child: const Text("Update"),
          ),
        ],
      ),
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

  Widget _buildSubscriptionCard(BuildContext context, UserStats stats) {
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

  Color _getLoanColor(String status) {
    switch (status) {
      case 'approved': return Colors.redAccent;
      case 'pending': return Colors.orange;
      case 'repaid': return Colors.green;
      default: return Colors.grey;
    }
  }
}

class DueWarningCard extends StatefulWidget {
  final UserStats stats;
  const DueWarningCard({super.key, required this.stats});

  @override
  State<DueWarningCard> createState() => _DueWarningCardState();
}

class _DueWarningCardState extends State<DueWarningCard> {
  Timer? _timer;
  String _timeDisplayString = "Loading...";
  late DateTime _targetDate;
  bool _isOverdue = false;

  @override
  void initState() {
    super.initState();
    _setupTimerState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant DueWarningCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stats.isCurrentMonthPaid != widget.stats.isCurrentMonthPaid) {
      _setupTimerState();
    }
  }

  void _setupTimerState() {
    final now = DateTime.now();
    if (widget.stats.isCurrentMonthPaid) {
      _targetDate = DateTime(now.year, now.month + 1, 1);
    } else {
      _targetDate = DateTime(now.year, now.month, 15, 23, 59, 59);
    }
    _updateTime();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateTime();
      }
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    final difference = _targetDate.difference(now);

    if (difference.isNegative) {
      if (mounted) {
        setState(() {
          _isOverdue = true;
          _timeDisplayString = "00 Year 00 Month 00 Days 00 Hours 00 Min 00 Sec";
        });
      }
    } else {
      String formattedTime = _calculateDetailedBreakdown(_targetDate, now);
      if (mounted) {
        setState(() {
          _isOverdue = false;
          _timeDisplayString = formattedTime;
        });
      }
    }
  }

  String _calculateDetailedBreakdown(DateTime target, DateTime now) {
    int years = target.year - now.year;
    int months = target.month - now.month;
    int days = target.day - now.day;
    int hours = target.hour - now.hour;
    int minutes = target.minute - now.minute;
    int seconds = target.second - now.second;

    if (seconds < 0) { seconds += 60; minutes--; }
    if (minutes < 0) { minutes += 60; hours--; }
    if (hours < 0) { hours += 24; days--; }
    if (days < 0) {
      final prevMonth = DateTime(target.year, target.month - 1);
      final daysInPrevMonth = DateTime(prevMonth.year, prevMonth.month + 1, 0).day;
      days += daysInPrevMonth;
      months--;
    }
    if (months < 0) { months += 12; years--; }

    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "$years Year $months Month $days Days ${twoDigits(hours)} Hours ${twoDigits(minutes)} Min ${twoDigits(seconds)} Sec";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isPaid = widget.stats.isCurrentMonthPaid;
    final Color bgColor = isPaid ? Colors.green.shade50 : (_isOverdue ? Colors.red.shade50 : Colors.orange.shade50);
    final Color borderColor = isPaid ? Colors.green : (_isOverdue ? Colors.red : Colors.orange);
    final Color textColor = isPaid ? Colors.green : (_isOverdue ? Colors.red : Colors.orange);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(
            isPaid ? Icons.check_circle : (_isOverdue ? Icons.warning_amber_rounded : Icons.access_time_filled),
            color: textColor,
            size: 40,
          ),
          const SizedBox(height: 10),
          Text(
            isPaid
                ? "Current Month Payment Complete! 🎉"
                : (_isOverdue ? "Payment Overdue!" : "Monthly Payment Due"),
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 18),
          ),
          const SizedBox(height: 5),
          if (!isPaid && !_isOverdue)
            const Text("Target: 15th of this month", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),
          if (!isPaid && _isOverdue)
            const Text("Please Pay ASAP with Penalty", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor.withOpacity(0.5)),
              ),
              child: Text(
                _timeDisplayString,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          if (isPaid)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text("Next cycle starts in:", style: TextStyle(color: Colors.green.shade800)),
            ),
          if (!isPaid) ...[
            const SizedBox(height: 15),
            const Divider(),
            const SizedBox(height: 10),
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("যদি কোনো সদস্য সময়মতো পেমেন্ট করতে ব্যর্থ হয়:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  _buildRuleRow("১৬–২০ তারিখের মধ্যে:", "মূল টাকার সাথে ৫% জরিমানা।"),
                  _buildRuleRow("২০ তারিখের পর:", "পরবর্তী মাসের সাথে ১০% জরিমানা সহ।"),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildRuleRow(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("▶ ", style: TextStyle(color: Colors.red, fontSize: 12)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 12, height: 1.4),
                children: [
                  TextSpan(text: "$title ", style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}