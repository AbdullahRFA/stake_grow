import 'dart:async';
import 'dart:ui'; // Required for FontFeature
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stake_grow/core/common/loader.dart';
import 'package:stake_grow/features/activity/domain/activity_model.dart';
import 'package:stake_grow/features/community/domain/community_model.dart';
import 'package:stake_grow/features/community/domain/withdrawal_model.dart'; // ✅ Import Withdrawal Model
import 'package:stake_grow/features/community/presentation/community_controller.dart'; // ✅ Import Controller
import 'package:stake_grow/features/community/presentation/transaction_providers.dart';
import 'package:stake_grow/features/community/presentation/user_stats_provider.dart';
import 'package:stake_grow/features/donation/domain/donation_model.dart';
import 'package:stake_grow/features/donation/presentation/donation_controller.dart';
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
    // Watch live community details
    final communityAsync = ref.watch(communityDetailsProvider(community.id));

    return communityAsync.when(
      loading: () => const Scaffold(body: Loader()),
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (liveCommunity) {
        final currentUser = FirebaseAuth.instance.currentUser;

        // 1. Check Main Admin (Owner)
        final isMainAdmin = currentUser != null && currentUser.uid == liveCommunity.adminId;

        // 2. Check Co-Admin
        final isCoAdmin = currentUser != null && liveCommunity.mods.contains(currentUser.uid);

        // 3. Combined Privilege for operational tasks
        final hasAdminPrivileges = isMainAdmin || isCoAdmin;

        // Watch Streams
        final statsAsync = ref.watch(userStatsProvider(liveCommunity.id));
        final loansAsync = ref.watch(communityLoansProvider(liveCommunity.id));
        final donationsAsync = ref.watch(communityDonationsProvider(liveCommunity.id));
        // ✅ NEW: Watch Withdrawals Stream
        final withdrawalsAsync = ref.watch(communityWithdrawalsProvider(liveCommunity.id));

        return Scaffold(
          appBar: AppBar(
            title: Text(liveCommunity.name),
            centerTitle: true,
            actions: [
              IconButton(
                onPressed: () {
                  context.push('/settings', extra: liveCommunity);
                },
                icon: const Icon(Icons.settings),
              ),
            ],
          ),
          body: statsAsync.when(
            loading: () => const Loader(),
            error: (e, s) => Center(child: Text('Error: $e')),
            data: (stats) {
              return loansAsync.when(
                loading: () => const Loader(),
                error: (e, s) => Center(child: Text('Error loading loans: $e')),
                data: (allLoans) {
                  final myLoans = allLoans.where((l) => l.borrowerId == currentUser?.uid).toList();

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
                              Text('৳ ${liveCommunity.totalFund.toStringAsFixed(2)}',
                                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              Text('${liveCommunity.members.length} Members Active', style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 1A. Admin Deposit Requests Card
                        if (hasAdminPrivileges)
                          donationsAsync.when(
                            data: (donations) {
                              final pendingDeposits = donations.where((d) => d.status == 'pending').toList();
                              if (pendingDeposits.isEmpty) return const SizedBox();
                              return _buildAdminDepositCard(context, pendingDeposits, ref);
                            },
                            loading: () => const SizedBox(),
                            error: (e, s) => Text("Error loading deposits: $e"),
                          ),
                        if(hasAdminPrivileges) const SizedBox(height: 16),

                        // ✅ 1B. Admin Withdrawal Requests Card (New Feature)
                        if (hasAdminPrivileges)
                          withdrawalsAsync.when(
                            data: (withdrawals) {
                              final pending = withdrawals.where((w) => w.status == 'pending').toList();
                              // Call the helper widget here
                              return _buildAdminWithdrawalCard(context, pending, ref);
                            },
                            loading: () => const SizedBox(),
                            error: (e, s) => const SizedBox(),
                          ),
                        if(hasAdminPrivileges) const SizedBox(height: 16),

                        // 2. Due/Warning Card
                        DueWarningCard(stats: stats),
                        const SizedBox(height: 16),

                        // 3. Invite Code (Admin)
                        if (hasAdminPrivileges) ...[
                          _buildInviteCard(context, liveCommunity.inviteCode),
                          const SizedBox(height: 24),
                        ],

                        // 4. Contribution Card
                        const Text("Your Contributions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 12),
                        _buildStatCard(
                          icon: Icons.volunteer_activism,
                          color: Colors.blueAccent,
                          title: 'My Liquid Balance',
                          value: '৳ ${stats.totalDonated.toStringAsFixed(0)}',
                          subtitle: 'You own ${stats.contributionPercentage.toStringAsFixed(1)}% of the fund',
                        ),
                        const SizedBox(height: 12),

                        // 4A. My Deposit History Card
                        _buildMyDepositHistoryCard(context, stats.allMyDeposits, ref),
                        const SizedBox(height: 16),

                        // 5. Profit/Loss Card
                        _buildProfitLossCard(stats),
                        const SizedBox(height: 12),

                        // 6. Subscription Breakdown
                        _buildSubscriptionCard(context, stats),
                        const SizedBox(height: 16),

                        // 7. Investment Overview
                        _buildInvestmentCard(context, stats, liveCommunity),
                        const SizedBox(height: 16),

                        // 8. Active Lending Portfolio
                        _buildActiveLendingCard(context, stats, allLoans, currentUser?.uid),
                        const SizedBox(height: 16),

                        // 9. Activity/Expense Impact Card
                        _buildExpenseImpactCard(context, stats, liveCommunity.id),
                        const SizedBox(height: 16),

                        // 10. Admin Loan Overview
                        if (hasAdminPrivileges) ...[
                          _buildAdminLoanOverviewCard(context, allLoans, ref),
                          const SizedBox(height: 16),
                        ],

                        // 11. My Loan Overview
                        _buildLoanSummaryCard(context, myLoans, ref, isMyLoan: true),
                        const SizedBox(height: 30),

                        // 12. Quick Actions
                        const Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildActionButton(Icons.volunteer_activism, 'Deposit', () {
                              context.push('/create-donation', extra: {
                                'communityId': liveCommunity.id,
                                'isMonthlyDisabled': stats.isCurrentMonthPaid,
                              });
                            }),
                            _buildActionButton(Icons.request_quote, 'Loan', () { context.push('/create-loan', extra: liveCommunity.id); }),
                            _buildActionButton(Icons.bar_chart, hasAdminPrivileges ? 'Invest' : 'Investments', () {
                              if (hasAdminPrivileges) { context.push('/create-investment', extra: liveCommunity.id); }
                              else { context.push('/investment-history', extra: liveCommunity.id); }
                            }),
                            _buildActionButton(Icons.event, hasAdminPrivileges ? 'Activity' : 'Activities', () {
                              if (hasAdminPrivileges) { context.push('/create-activity', extra: liveCommunity.id); }
                              else { context.push('/activity-history', extra: liveCommunity.id); }
                            }),
                            if (hasAdminPrivileges) _buildActionButton(Icons.history, 'History', () { context.push('/transaction-history', extra: liveCommunity.id); }),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  // --- Helper Widgets ---

  // ✅ NEW: Admin Withdrawal Management Card
  Widget _buildAdminWithdrawalCard(BuildContext context, List<WithdrawalModel> requests, WidgetRef ref) {
    if(requests.isEmpty) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text("Withdrawal Requests", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              return Card(
                child: ListTile(
                  title: Text("${req.userName} (${req.type})"),
                  subtitle: Text("Amount: ৳${req.amount}\nReason: ${req.reason}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () {
                          // Approve
                          ref.read(communityControllerProvider.notifier).approveWithdrawal(req, context);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () {
                          // Reject
                          ref.read(communityControllerProvider.notifier).rejectWithdrawal(req.id, context);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Admin Verification Card
  Widget _buildAdminDepositCard(BuildContext context, List<DonationModel> pendingDeposits, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orange),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_user, color: Colors.orange),
              SizedBox(width: 8),
              Text("Deposit Requests", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pendingDeposits.length,
            itemBuilder: (context, index) {
              final deposit = pendingDeposits[index];
              return Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(deposit.senderName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Amount: ৳${deposit.amount} (${deposit.type})"),
                      Text("Via: ${deposit.paymentMethod}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      if (deposit.transactionId != null)
                        Text("TrxID: ${deposit.transactionId}", style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _showVerifyDepositDialog(context, ref, deposit),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    child: const Text("Verify"),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Verify Deposit Dialog
  void _showVerifyDepositDialog(BuildContext context, WidgetRef ref, DonationModel deposit) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Verify Deposit"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("User: ${deposit.senderName}"),
            Text("Amount: ৳${deposit.amount}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 5),
            Text("Method: ${deposit.paymentMethod}"),
            if(deposit.phoneNumber != null) Text("Phone: ${deposit.phoneNumber}"),
            if(deposit.transactionId != null) Text("TrxID: ${deposit.transactionId}"),
            const SizedBox(height: 15),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: "Reason (If Rejecting)",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              final reason = reasonController.text.trim().isEmpty ? "Admin rejected request" : reasonController.text.trim();
              ref.read(donationControllerProvider.notifier).rejectDonation(deposit.id, reason, context);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Reject"),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(donationControllerProvider.notifier).approveDonation(deposit, context);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text("Approve"),
          ),
        ],
      ),
    );
  }

  // My Deposit History Card (User View)
  Widget _buildMyDepositHistoryCard(BuildContext context, List<DonationModel> allDeposits, WidgetRef ref) {
    final previewDeposits = allDeposits.where((d) => d.status != 'approved').toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history, color: Colors.blue, size: 24),
              SizedBox(width: 10),
              Text("My Deposit Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),

          if (previewDeposits.isEmpty && allDeposits.isNotEmpty)
            const Text("All recent deposits are approved.", style: TextStyle(color: Colors.grey)),

          if (previewDeposits.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: previewDeposits.length > 2 ? 2 : previewDeposits.length,
              itemBuilder: (context, index) {
                final deposit = previewDeposits[index];
                Color statusColor = deposit.status == 'pending' ? Colors.orange : Colors.red;
                IconData statusIcon = deposit.status == 'pending' ? Icons.hourglass_empty : Icons.cancel;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.1),
                    child: Icon(statusIcon, color: statusColor, size: 20),
                  ),
                  title: Text("৳${deposit.amount} - ${deposit.status.toUpperCase()}",
                      style: TextStyle(fontWeight: FontWeight.bold, color: statusColor, fontSize: 14)),
                  subtitle: deposit.status == 'rejected'
                      ? Text("Note: ${deposit.rejectionReason}", style: const TextStyle(color: Colors.red, fontSize: 12))
                      : Text(DateFormat('dd MMM, hh:mm a').format(deposit.timestamp)),
                );
              },
            ),

          const SizedBox(height: 10),
          // ✅ Button to View Full Details
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                _showDepositDetails(context, allDeposits, ref);
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.blue),
              ),
              child: const Text("View Deposit Details", style: TextStyle(color: Colors.blue)),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ New: Detailed Bottom Sheet with Edit/Delete for Pending
  void _showDepositDetails(BuildContext context, List<DonationModel> allDeposits, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Deposit History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Divider(),
              Expanded(
                child: allDeposits.isEmpty
                    ? const Center(child: Text("No deposit history found."))
                    : ListView.builder(
                  itemCount: allDeposits.length,
                  itemBuilder: (context, index) {
                    final deposit = allDeposits[index];
                    Color statusColor;
                    IconData statusIcon;

                    switch (deposit.status) {
                      case 'approved':
                        statusColor = Colors.green;
                        statusIcon = Icons.check_circle;
                        break;
                      case 'rejected':
                        statusColor = Colors.red;
                        statusIcon = Icons.cancel;
                        break;
                      default:
                        statusColor = Colors.orange;
                        statusIcon = Icons.hourglass_empty;
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: statusColor.withOpacity(0.1),
                          child: Icon(statusIcon, color: statusColor, size: 24),
                        ),
                        title: Text("৳${deposit.amount}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Type: ${deposit.type} | Method: ${deposit.paymentMethod}"),
                            Text("Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(deposit.timestamp)}"),
                            if (deposit.transactionId != null)
                              Text("TrxID: ${deposit.transactionId}", style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                            if (deposit.status == 'rejected')
                              Text("Note: ${deposit.rejectionReason}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        trailing: deposit.status == 'pending'
                            ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.pop(context);
                                _showEditDepositDialog(context, ref, deposit);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _showDeleteDepositDialog(context, ref, deposit.id);
                              },
                            ),
                          ],
                        )
                            : Text(deposit.status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
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

  // ✅ New: Edit Deposit Dialog
  void _showEditDepositDialog(BuildContext context, WidgetRef ref, DonationModel deposit) {
    final amountController = TextEditingController(text: deposit.amount.toString());
    final trxIdController = TextEditingController(text: deposit.transactionId);
    final phoneController = TextEditingController(text: deposit.phoneNumber);
    String selectedMethod = deposit.paymentMethod;
    List<String> paymentMethods = ['Bkash', 'Rocket', 'Nagad', 'Manual (Cash)'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Edit Deposit Request"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Amount (৳)"),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: paymentMethods.contains(selectedMethod) ? selectedMethod : 'Manual (Cash)',
                      decoration: const InputDecoration(labelText: 'Payment Method'),
                      items: paymentMethods.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (val) => setState(() => selectedMethod = val!),
                    ),
                    if (selectedMethod != 'Manual (Cash)') ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Phone Number'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: trxIdController,
                        decoration: const InputDecoration(labelText: 'Transaction ID'),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    final newAmount = double.tryParse(amountController.text) ?? deposit.amount;

                    final updatedDeposit = DonationModel(
                      id: deposit.id,
                      communityId: deposit.communityId,
                      senderId: deposit.senderId,
                      senderName: deposit.senderName,
                      amount: newAmount,
                      type: deposit.type,
                      timestamp: deposit.timestamp,
                      status: 'pending',
                      rejectionReason: null, // Clear rejection reason if editing
                      paymentMethod: selectedMethod,
                      transactionId: selectedMethod != 'Manual (Cash)' ? trxIdController.text.trim() : null,
                      phoneNumber: selectedMethod != 'Manual (Cash)' ? phoneController.text.trim() : null,
                    );

                    ref.read(donationControllerProvider.notifier).updateDonation(updatedDeposit, ctx);
                  },
                  child: const Text("Update"),
                ),
              ],
            );
          }
      ),
    );
  }

  // ✅ New: Delete Deposit Dialog
  void _showDeleteDepositDialog(BuildContext context, WidgetRef ref, String depositId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Request"),
        content: const Text("Are you sure you want to delete this deposit request?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Close details sheet if open
              ref.read(donationControllerProvider.notifier).deleteDonation(depositId, context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseImpactCard(BuildContext context, UserStats stats, String communityId) {
    if (stats.totalExpenseShare == 0) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.red.shade100),
        boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.volunteer_activism, color: Colors.redAccent, size: 28),
              const SizedBox(width: 10),
              const Text("My Expense Contribution", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),

          Text("৳ ${stats.totalExpenseShare.toStringAsFixed(0)}",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
          const Text("Used for community activities", style: TextStyle(color: Colors.grey, fontSize: 12)),

          const SizedBox(height: 15),
          const Divider(),
          const SizedBox(height: 5),
          const Text("Recent Contributions:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 5),

          ...stats.myImpactActivities.take(3).map((activity) {
            final myShare = activity.expenseShares[FirebaseAuth.instance.currentUser?.uid] ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(activity.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(DateFormat('dd MMM yyyy').format(activity.date),
                            style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Text("- ৳ ${myShare.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                ],
              ),
            );
          }),

          if (stats.myImpactActivities.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Center(child: Text("+ ${stats.myImpactActivities.length - 3} more", style: const TextStyle(fontSize: 10, color: Colors.grey))),
            ),

          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                context.push('/activity-history', extra: communityId);
              },
              icon: const Icon(Icons.list_alt, size: 16, color: Colors.redAccent),
              label: const Text("View All Activities", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveLendingCard(BuildContext context, UserStats stats, List<LoanModel> allLoans, String? myUid) {
    final myRepaidLending = allLoans.where((l) =>
    l.status == 'repaid' && l.lenderShares.containsKey(myUid)
    ).toList();

    if (stats.lockedInLoan == 0 && myRepaidLending.isEmpty) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.teal.shade200),
        boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.handshake, color: Colors.teal, size: 28),
              const SizedBox(width: 10),
              const Text("Money Locked in Loans", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          Text("৳ ${stats.lockedInLoan.toStringAsFixed(0)}",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
          const Text("Currently lent to members", style: TextStyle(color: Colors.grey, fontSize: 12)),

          const SizedBox(height: 15),
          const Divider(),
          const SizedBox(height: 5),
          const Text("Active Borrowers:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 5),

          if (stats.myFundedLoans.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text("No active loans funded by you.", style: TextStyle(color: Colors.grey)),
            )
          else
            ...stats.myFundedLoans.take(3).map((loan) {
              final myShare = loan.lenderShares[myUid] ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(loan.borrowerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text("৳ ${myShare.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                      ],
                    ),
                    LoanCountdownTimer(targetDate: loan.repaymentDate, fontSize: 11, color: Colors.orange),
                  ],
                ),
              );
            }),

          if (stats.myFundedLoans.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Center(child: Text("+ ${stats.myFundedLoans.length - 3} more", style: const TextStyle(fontSize: 10, color: Colors.grey))),
            ),

          const SizedBox(height: 10),
          if (myRepaidLending.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _showLoanDetails(context, "Previous Lending History", myRepaidLending, null, isMyLoan: false, isAdminAction: false);
                },
                icon: const Icon(Icons.history, size: 16, color: Colors.teal),
                label: const Text("View Previous Lending History", style: TextStyle(color: Colors.teal, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.teal),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfitLossCard(UserStats stats) {
    double totalDeposited = stats.monthlyDonated + stats.randomDonated;
    double profitOrLoss = stats.totalLifetimeContributed - totalDeposited;
    bool isProfit = profitOrLoss >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.indigo.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("My Total Deposit", style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 5),
                Text("৳ ${totalDeposited.toStringAsFixed(0)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isProfit ? "Total Profit" : "Total Loss", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      isProfit ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isProfit ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "৳ ${profitOrLoss.abs().toStringAsFixed(0)}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isProfit ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentCard(BuildContext context, UserStats stats, CommunityModel community) {
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

  Widget _buildAdminLoanOverviewCard(BuildContext context, List<LoanModel> allLoans, WidgetRef ref) {
    return _buildLoanSummaryCard(context, allLoans, ref, isMyLoan: false);
  }

  Widget _buildLoanSummaryCard(BuildContext context, List<LoanModel> loans, WidgetRef? ref, {required bool isMyLoan}) {
    final pending = loans.where((l) => l.status == 'pending').toList();
    final active = loans.where((l) => l.status == 'approved').toList();
    final repaid = loans.where((l) => l.status == 'repaid').toList();
    final rejected = loans.where((l) => l.status == 'rejected').toList();
    final activeAmount = active.fold(0.0, (sum, item) => sum + item.amount);

    if (isMyLoan && pending.isEmpty && active.isEmpty && repaid.isEmpty && rejected.isEmpty) {
      return _buildStatCard(
        icon: Icons.request_quote,
        color: Colors.grey,
        title: 'My Loans',
        value: 'No History',
        subtitle: 'You have no loan records yet',
      );
    }

    String title = isMyLoan ? "My Loans" : "Community Loan Overview";
    Color cardColor = isMyLoan ? Colors.white : Colors.indigo.shade50;
    Color iconColor = isMyLoan ? Colors.indigo : Colors.deepPurple;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: iconColor.withOpacity(0.2)),
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
                  backgroundColor: iconColor.withOpacity(0.1),
                  child: Icon(isMyLoan ? Icons.account_balance_wallet : Icons.admin_panel_settings, color: iconColor, size: 24),
                ),
                const SizedBox(width: 15),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          if (active.isNotEmpty)
            InkWell(
              onTap: () => _showLoanDetails(context, isMyLoan ? "Active Loans (To be Repaid)" : "All Active Community Loans", active, ref, isMyLoan: isMyLoan, isAdminAction: !isMyLoan),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: _buildBreakdownRow("Active Debt", activeAmount, "${active.length} Active", Colors.redAccent),
              ),
            ),
          if (active.isNotEmpty && (pending.isNotEmpty || repaid.isNotEmpty)) const Divider(height: 1),
          if (pending.isNotEmpty)
            InkWell(
              onTap: () => _showLoanDetails(context, isMyLoan ? "Pending Requests" : "All Pending Requests", pending, ref, isMyLoan: isMyLoan, isAdminAction: !isMyLoan),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: _buildBreakdownRow("Pending Requests", pending.fold(0, (sum, item) => sum + item.amount), "${pending.length} Pending", Colors.orange),
              ),
            ),
          if (pending.isNotEmpty && repaid.isNotEmpty) const Divider(height: 1),
          if (repaid.isNotEmpty)
            InkWell(
              onTap: () => _showLoanDetails(context, isMyLoan ? "Repaid History" : "All Repaid Loans", repaid, ref, isMyLoan: isMyLoan, isAdminAction: false),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: _buildBreakdownRow("Repaid Loans", repaid.fold(0, (sum, item) => sum + item.amount), "${repaid.length} Repaid", Colors.green),
              ),
            ),
          if (rejected.isNotEmpty) ...[
            const Divider(height: 1),
            InkWell(
              onTap: () => _showLoanDetails(context, isMyLoan ? "Rejected Requests" : "Rejected History", rejected, ref, isMyLoan: isMyLoan, isAdminAction: false),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: _buildBreakdownRow("Rejected", rejected.fold(0, (sum, item) => sum + item.amount), "${rejected.length} Rejected", Colors.red),
              ),
            ),
          ],
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void _showLoanDetails(BuildContext context, String title, List<LoanModel> loans, WidgetRef? ref, {required bool isMyLoan, required bool isAdminAction}) {
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
                    Widget? trailingWidget;

                    if (ref != null) {
                      if (isAdminAction && loan.status == 'pending') {
                        // ✅ Admin Actions: Approve / Reject
                        trailingWidget = Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
                              tooltip: "Approve Loan",
                              onPressed: () {
                                Navigator.pop(context); // Close sheet
                                ref.read(loanControllerProvider.notifier).approveLoan(loan: loan, context: context);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
                              tooltip: "Reject Loan",
                              onPressed: () {
                                Navigator.pop(context); // Close sheet
                                _showRejectDialog(context, ref, loan);
                              },
                            ),
                          ],
                        );
                      } else if (isAdminAction && loan.status == 'approved') {
                        // ✅ Admin Action: Repay (Mark as Paid)
                        trailingWidget = IconButton(
                          icon: const Icon(Icons.monetization_on, color: Colors.blue, size: 30),
                          tooltip: "Mark as Repaid",
                          onPressed: () {
                            _showRepayDialog(context, ref, loan);
                          },
                        );
                      } else if (isMyLoan && loan.status == 'pending') {
                        // ✅ User Actions: Edit / Delete
                        trailingWidget = Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.pop(context);
                                _showEditDialog(context, ref, loan);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                ref.read(loanControllerProvider.notifier).deleteLoan(loan.id, context);
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        );
                      }
                    }

                    // ✅ Warning for Active Loans
                    Widget? penaltyWarning;
                    if (loan.status == 'approved') {
                      penaltyWarning = Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("⚠️ Late Repayment Rules:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red)),
                            const SizedBox(height: 4),
                            const Text("▶ deadline par hole prothom 5 diner moddhe rapy korle:\nমূল টাকার সাথে ৫% জরিমানা যুক্ত হবে।", style: TextStyle(fontSize: 11)),
                            const SizedBox(height: 4),
                            const Text("▶ prothom 5 din par hole porer 5 diner jonne:\nমূল টাকার উপর ১০% জরিমানা সহ পরিশোধ করতে হবে।", style: TextStyle(fontSize: 11)),
                            const SizedBox(height: 8),
                            // ✅ Countdown for Repayment
                            Row(
                              children: [
                                const Icon(Icons.timer, size: 14, color: Colors.red),
                                const SizedBox(width: 5),
                                LoanCountdownTimer(targetDate: loan.repaymentDate, color: Colors.red, fontSize: 12),
                              ],
                            ),
                          ],
                        ),
                      );
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: _getLoanColor(loan.status).withOpacity(0.2),
                                child: Icon(Icons.request_quote, color: _getLoanColor(loan.status)),
                              ),
                              title: Text('৳${loan.amount} - ${loan.status.toUpperCase()}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${loan.borrowerName}\nReason: ${loan.reason}'),
                                  const SizedBox(height: 4),
                                  // ✅ Requested Date (Always show)
                                  Text('Requested: ${DateFormat('dd MMM yyyy').format(loan.requestDate)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),

                                  // ✅ Date Logic based on status
                                  if (loan.status == 'repaid')
                                    Text('Repayment Date: ${DateFormat('dd MMM yyyy').format(loan.repaymentDate)}',
                                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12))
                                  else
                                    Text('Deadline: ${DateFormat('dd MMM yyyy').format(loan.repaymentDate)}',
                                        style: const TextStyle(fontSize: 12)),

                                  if (loan.status == 'rejected')
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        "Note: ${loan.reason}",
                                        style: const TextStyle(color: Colors.red, fontStyle: FontStyle.italic),
                                      ),
                                    ),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: trailingWidget,
                            ),
                            if (penaltyWarning != null) penaltyWarning,
                          ],
                        ),
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

  // ✅ New: Repay Dialog
  void _showRepayDialog(BuildContext context, WidgetRef ref, LoanModel loan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Repayment"),
        content: Text("Mark loan of ৳${loan.amount} from ${loan.borrowerName} as repaid?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Close details sheet
              ref.read(loanControllerProvider.notifier).repayLoan(loan: loan, context: context);
            },
            child: const Text("Confirm Repay"),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, LoanModel loan) {
    final amountController = TextEditingController(text: loan.amount.toString());
    final reasonController = TextEditingController(text: loan.reason);
    DateTime selectedDate = loan.repaymentDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
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
                  const SizedBox(height: 20),
                  // ✅ Date Picker
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: "Repayment Deadline",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('dd MMM yyyy').format(selectedDate)),
                          const Icon(Icons.calendar_today, size: 20, color: Colors.teal),
                        ],
                      ),
                    ),
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
                      repaymentDate: selectedDate, // ✅ Updated Date
                      status: loan.status,
                      lenderShares: loan.lenderShares,
                    );

                    ref.read(loanControllerProvider.notifier).updateLoan(updatedLoan, ctx);
                  },
                  child: const Text("Update"),
                ),
              ],
            );
          }
      ),
    );
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref, LoanModel loan) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reject Loan Request"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Are you sure you want to reject this loan?"),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: "Reason (Optional)",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              final rejectReason = reasonController.text.trim();

              final updatedLoan = LoanModel(
                id: loan.id,
                communityId: loan.communityId,
                borrowerId: loan.borrowerId,
                borrowerName: loan.borrowerName,
                amount: loan.amount,
                reason: rejectReason.isNotEmpty
                    ? "${loan.reason}\n(Rejection Note: $rejectReason)"
                    : loan.reason,
                requestDate: loan.requestDate,
                repaymentDate: loan.repaymentDate,
                status: 'rejected',
                lenderShares: loan.lenderShares,
              );

              ref.read(loanControllerProvider.notifier).updateLoan(updatedLoan, ctx);
            },
            child: const Text("Reject"),
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
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }
}

// ... DueWarningCard & LoanCountdownTimer (Keep existing classes below the main widget)
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

class LoanCountdownTimer extends StatefulWidget {
  final DateTime targetDate;
  final double fontSize;
  final Color color;

  const LoanCountdownTimer({
    super.key,
    required this.targetDate,
    this.fontSize = 12,
    this.color = Colors.black87,
  });

  @override
  State<LoanCountdownTimer> createState() => _LoanCountdownTimerState();
}

class _LoanCountdownTimerState extends State<LoanCountdownTimer> {
  Timer? _timer;
  String _timeLeft = "Loading...";

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) _updateTime();
    });
    _updateTime(); // Initial Call
  }

  void _updateTime() {
    final now = DateTime.now();
    final difference = widget.targetDate.difference(now);

    if (difference.isNegative) {
      if (mounted) setState(() => _timeLeft = "Overdue");
    } else {
      int days = difference.inDays;
      int hours = difference.inHours % 24;
      int minutes = difference.inMinutes % 60;
      int seconds = difference.inSeconds % 60;

      if (mounted) {
        setState(() {
          _timeLeft = "${days}d ${hours}h ${minutes}m ${seconds}s remaining";
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _timeLeft,
      style: TextStyle(
        fontSize: widget.fontSize,
        color: widget.color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}