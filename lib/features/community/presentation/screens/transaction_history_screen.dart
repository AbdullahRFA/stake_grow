import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stake_grow/core/common/loader.dart';
import 'package:stake_grow/features/community/presentation/transaction_providers.dart';
// ✅ Import Loan Features
import 'package:stake_grow/features/loan/domain/loan_model.dart';
import 'package:stake_grow/features/loan/presentation/loan_controller.dart';

class TransactionHistoryScreen extends ConsumerWidget {
  final String communityId;
  const TransactionHistoryScreen({super.key, required this.communityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4, // ✅ UPDATE: এখন ৪টি ট্যাব (Donation, Investment, Expense, Loans)
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Transparency & History'),
          bottom: const TabBar(
            isScrollable: true, // ছোট স্ক্রিনে ট্যাবগুলো যেন এঁটে যায়
            tabs: [
              Tab(text: 'Donations', icon: Icon(Icons.volunteer_activism)),
              Tab(text: 'Investments', icon: Icon(Icons.trending_up)),
              Tab(text: 'Expenses', icon: Icon(Icons.money_off)),
              // ✅ New Tab
              Tab(text: 'Loans', icon: Icon(Icons.request_quote)),
            ],
            labelColor: Colors.teal,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.teal,
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Donations List
            _DonationList(communityId: communityId),

            // Tab 2: Investments List
            _InvestmentList(communityId: communityId),

            // Tab 3: Activities (Expenses) List
            _ActivityList(communityId: communityId),

            // ✅ Tab 4: Loans List (With Admin Approval)
            _LoanList(communityId: communityId),
          ],
        ),
      ),
    );
  }
}

// ---------------- Sub Widgets ----------------

class _DonationList extends ConsumerWidget {
  final String communityId;
  const _DonationList({required this.communityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donations = ref.watch(communityDonationsProvider(communityId));

    return donations.when(
      loading: () => const Loader(),
      error: (e, s) {
        print('🔴 Donation Error: $e');
        return Center(child: Text('Error: $e'));
      },
      data: (data) {
        if (data.isEmpty) return const Center(child: Text('No donations yet.'));
        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            final donation = data[index];
            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.arrow_downward, color: Colors.white),
              ),
              title: Text(donation.senderName),
              subtitle: Text(DateFormat('dd MMM, hh:mm a').format(donation.timestamp)),
              trailing: Text(
                '+ ৳${donation.amount}',
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            );
          },
        );
      },
    );
  }
}

class _InvestmentList extends ConsumerWidget {
  final String communityId;
  const _InvestmentList({required this.communityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investments = ref.watch(communityInvestmentsProvider(communityId));

    return investments.when(
      loading: () => const Loader(),
      error: (e, s) {
        print('🔴 Investment Error: $e');
        return Center(child: Text('Error: $e'));
      },
      data: (data) {
        if (data.isEmpty) return const Center(child: Text('No investments yet.'));
        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            final invest = data[index];
            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.orange,
                child: Icon(Icons.bar_chart, color: Colors.white),
              ),
              title: Text(invest.projectName),
              subtitle: Text(invest.status.toUpperCase()),
              trailing: Text(
                '- ৳${invest.investedAmount}',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            );
          },
        );
      },
    );
  }
}

class _ActivityList extends ConsumerWidget {
  final String communityId;
  const _ActivityList({required this.communityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(communityActivitiesProvider(communityId));

    return activities.when(
      loading: () => const Loader(),
      error: (e, s) {
        print('🔴 Activity Error: $e');
        return Center(child: Text('Error: $e'));
      },
      data: (data) {
        if (data.isEmpty) return const Center(child: Text('No expenses yet.'));
        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            final activity = data[index];
            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.redAccent,
                child: Icon(Icons.volunteer_activism, color: Colors.white),
              ),
              title: Text(activity.title),
              subtitle: Text(activity.type),
              trailing: Text(
                '- ৳${activity.cost}',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            );
          },
        );
      },
    );
  }
}

// ✅ NEW: Loan List with Admin Approval Action
class _LoanList extends ConsumerWidget {
  final String communityId;
  const _LoanList({required this.communityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loans = ref.watch(communityLoansProvider(communityId));

    return loans.when(
      loading: () => const Loader(),
      error: (e, s) {
        print('🔴 Loan Error: $e');
        print('Stack Trace: $s');
        return Center(child: Text('Error: $e'));
      },
      data: (data) {
        if (data.isEmpty) return const Center(child: Text('No loan requests.'));
        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            final loan = data[index];
            final isPending = loan.status == 'pending';

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isPending ? Colors.orange : Colors.green,
                child: Icon(
                  // 🔴 ফিক্স: আগে এখানে Colors ছিল, এখন Icons হবে
                  isPending ? Icons.hourglass_empty : Icons.check,
                  color: Colors.white,
                ),
              ),
              title: Text(loan.borrowerName),
              subtitle: Text(
                "Status: ${loan.status.toUpperCase()}\nReason: ${loan.reason}",
                style: TextStyle(
                  color: isPending ? Colors.orange.shade800 : Colors.grey,
                  fontWeight: isPending ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              isThreeLine: true,
              trailing: Text(
                '৳${loan.amount}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              // ✅ Admin Action: Tap to Approve
              onTap: isPending
                  ? () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Approve Loan?'),
                    content: Text(
                        'Approve ৳${loan.amount} for ${loan.borrowerName}?\nThis will deduct money from the Community Fund immediately.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(loanControllerProvider.notifier).approveLoan(
                            loan: loan,
                            context: context,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Approve & Pay'),
                      ),
                    ],
                  ),
                );
              }
                  : null,
            );
          },
        );
      },
    );
  }
}