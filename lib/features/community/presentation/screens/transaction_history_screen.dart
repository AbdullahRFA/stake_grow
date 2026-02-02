import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stake_grow/core/common/loader.dart';
import 'package:stake_grow/features/community/presentation/transaction_providers.dart';
import 'package:stake_grow/features/investment/domain/investment_model.dart';
import 'package:stake_grow/features/investment/presentation/investment_controller.dart';
import 'package:stake_grow/features/loan/domain/loan_model.dart';
import 'package:stake_grow/features/loan/presentation/loan_controller.dart';

class TransactionHistoryScreen extends ConsumerWidget {
  final String communityId;
  final int initialIndex;

  const TransactionHistoryScreen({
    super.key,
    required this.communityId,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      initialIndex: initialIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Transparency & History'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Donations', icon: Icon(Icons.volunteer_activism)),
              Tab(text: 'Investments', icon: Icon(Icons.trending_up)),
              Tab(text: 'Expenses', icon: Icon(Icons.money_off)),
              Tab(text: 'Loans', icon: Icon(Icons.request_quote)),
            ],
            labelColor: Colors.teal,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.teal,
          ),
        ),
        body: TabBarView(
          children: [
            _DonationList(communityId: communityId),
            _InvestmentList(communityId: communityId), // ✅ Updated Widget
            _ActivityList(communityId: communityId),
            _LoanList(communityId: communityId),
          ],
        ),
      ),
    );
  }
}

// ... _DonationList (Keep as is) ...
class _DonationList extends ConsumerWidget {
  final String communityId;
  const _DonationList({required this.communityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donations = ref.watch(communityDonationsProvider(communityId));
    return donations.when(
      loading: () => const Loader(),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (data) {
        if (data.isEmpty) return const Center(child: Text('No donations yet.'));
        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            final donation = data[index];
            return ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.arrow_downward, color: Colors.white)),
              title: Text(donation.senderName),
              subtitle: Text(DateFormat('dd MMM, hh:mm a').format(donation.timestamp)),
              trailing: Text('+ ৳${donation.amount}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
            );
          },
        );
      },
    );
  }
}

// ✅ 2. Updated Investment List with Admin Action
class _InvestmentList extends ConsumerWidget {
  final String communityId;
  const _InvestmentList({required this.communityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investmentsAsync = ref.watch(communityInvestmentsProvider(communityId));
    final communityAsync = ref.watch(communityDetailsProvider(communityId)); // ✅ Check Admin
    final currentUser = FirebaseAuth.instance.currentUser;

    return investmentsAsync.when(
      loading: () => const Loader(),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (investments) {
        return communityAsync.when(
          loading: () => const Loader(),
          error: (e, s) => Center(child: Text('Error loading community info')),
          data: (community) {
            final isAdmin = currentUser != null && currentUser.uid == community.adminId;

            if (investments.isEmpty) return const Center(child: Text('No investments yet.'));

            return ListView.builder(
              itemCount: investments.length,
              itemBuilder: (context, index) {
                final invest = investments[index];
                final isActive = invest.status == 'active';

                // ROI Calculation
                double roi = invest.investedAmount == 0
                    ? 0
                    : (invest.expectedProfit / invest.investedAmount) * 100;

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isActive
                          ? Colors.orange
                          : (invest.actualProfitLoss! >= 0 ? Colors.green : Colors.red),
                      child: Icon(
                        isActive
                            ? Icons.trending_up
                            : (invest.actualProfitLoss! >= 0 ? Icons.check : Icons.arrow_downward),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(invest.projectName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Invested: ৳${invest.investedAmount}"),
                        if (isActive)
                          Text("Expected Profit: ৳${invest.expectedProfit} (${roi.toStringAsFixed(1)}%)")
                        else
                          Text(
                            "Returned: ৳${invest.returnAmount} \n${invest.actualProfitLoss! >= 0 ? 'Profit' : 'Loss'}: ৳${invest.actualProfitLoss}",
                            style: TextStyle(
                              color: invest.actualProfitLoss! >= 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    isThreeLine: true,
                    // ✅ Show Button only if Admin & Active
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isActive ? '' : 'Closed', // Hide amount if active to save space for button
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        if (isActive && isAdmin)
                          IconButton(
                            icon: const Icon(Icons.input, color: Colors.blue, size: 28),
                            tooltip: "Record Return",
                            onPressed: () => _showReturnDialog(context, ref, invest),
                          )
                        else if (!isActive)
                        // If closed, simple checkmark
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showReturnDialog(BuildContext context, WidgetRef ref, InvestmentModel invest) {
    final returnController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Record Investment Return"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Project: ${invest.projectName}"),
            const SizedBox(height: 5),
            Text("Invested: ৳${invest.investedAmount}", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 15),
            TextField(
              controller: returnController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Total Returned Amount",
                hintText: "Include principal + profit",
                border: OutlineInputBorder(),
                prefixText: "৳ ",
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Note: This amount will be added back to the Community Fund.",
              style: TextStyle(fontSize: 12, color: Colors.redAccent),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final returnAmount = double.tryParse(returnController.text.trim());
              if (returnAmount != null) {
                ref.read(investmentControllerProvider.notifier).closeInvestment(
                  communityId: invest.communityId,
                  investmentId: invest.id,
                  investedAmount: invest.investedAmount,
                  returnAmount: returnAmount,
                  context: context,
                );
                Navigator.pop(ctx); // Close dialog manually here to be safe
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            child: const Text("Confirm & Distribute"),
          ),
        ],
      ),
    );
  }
}

// ... _ActivityList (Keep as is) ...
class _ActivityList extends ConsumerWidget {
  final String communityId;
  const _ActivityList({required this.communityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(communityActivitiesProvider(communityId));
    return activities.when(
      loading: () => const Loader(),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (data) {
        if (data.isEmpty) return const Center(child: Text('No expenses yet.'));
        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            final activity = data[index];
            return ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.volunteer_activism, color: Colors.white)),
              title: Text(activity.title),
              subtitle: Text(activity.type),
              trailing: Text('- ৳${activity.cost}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
            );
          },
        );
      },
    );
  }
}

// ... _LoanList (Keep as is) ...
class _LoanList extends ConsumerWidget {
  final String communityId;
  const _LoanList({required this.communityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loans = ref.watch(communityLoansProvider(communityId));
    return loans.when(
      loading: () => const Loader(),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (data) {
        if (data.isEmpty) return const Center(child: Text('No loan requests.'));
        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            final loan = data[index];
            final isPending = loan.status == 'pending';
            final isApproved = loan.status == 'approved';
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isPending ? Colors.orange : (isApproved ? Colors.blue : Colors.green),
                child: Icon(isPending ? Icons.hourglass_empty : (isApproved ? Icons.money : Icons.check_circle), color: Colors.white),
              ),
              title: Text(loan.borrowerName),
              subtitle: Text("Status: ${loan.status.toUpperCase()}\nReason: ${loan.reason}"),
              isThreeLine: true,
              trailing: Text('৳${loan.amount}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              onTap: () {
                if (isPending) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Approve Loan?'),
                      content: Text('Approve ৳${loan.amount} for ${loan.borrowerName}?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(loanControllerProvider.notifier).approveLoan(loan: loan, context: context);
                          },
                          child: const Text('Approve'),
                        ),
                      ],
                    ),
                  );
                } else if (isApproved) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Mark as Repaid?'),
                      content: Text('Has ${loan.borrowerName} returned ৳${loan.amount}?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(loanControllerProvider.notifier).repayLoan(loan: loan, context: context);
                          },
                          child: const Text('Confirm'),
                        ),
                      ],
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}