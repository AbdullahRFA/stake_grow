import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stake_grow/core/common/loader.dart';
import 'package:stake_grow/features/community/presentation/transaction_providers.dart';
import 'package:stake_grow/features/loan/domain/loan_model.dart';
import 'package:stake_grow/features/loan/presentation/loan_controller.dart';

class TransactionHistoryScreen extends ConsumerWidget {
  final String communityId;
  final int initialIndex; // ✅ NEW: নির্দিষ্ট ট্যাব খোলার জন্য

  const TransactionHistoryScreen({
    super.key,
    required this.communityId,
    this.initialIndex = 0, // ডিফল্ট 0 (Donations)
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      initialIndex: initialIndex, // ✅ এখানে ব্যবহার করা হলো
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
            _InvestmentList(communityId: communityId),
            _ActivityList(communityId: communityId),
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
        return Center(child: Text('Error: $e'));
      },
      data: (data) {
        if (data.isEmpty) return const Center(child: Text('No loan requests.'));
        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            final loan = data[index];
            final isPending = loan.status == 'pending';
            final isApproved = loan.status == 'approved'; // ✅ চেক করা হলো

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isPending
                    ? Colors.orange
                    : (isApproved ? Colors.blue : Colors.green),
                child: Icon(
                  isPending
                      ? Icons.hourglass_empty
                      : (isApproved ? Icons.money : Icons.check_circle),
                  color: Colors.white,
                ),
              ),
              title: Text(loan.borrowerName),
              subtitle: Text(
                "Status: ${loan.status.toUpperCase()}\nReason: ${loan.reason}",
                style: TextStyle(
                  color: isPending
                      ? Colors.orange.shade800
                      : (isApproved ? Colors.blue : Colors.green),
                  fontWeight: FontWeight.bold,
                ),
              ),
              isThreeLine: true,
              trailing: Text(
                '৳${loan.amount}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),

              // ✅ Logic: Pending হলে Approve, Approved হলে Repay
              onTap: () {
                if (isPending) {
                  // ১. Approve Dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Approve Loan?'),
                      content: Text(
                          'Approve ৳${loan.amount} for ${loan.borrowerName}?\nThis will deduct money from the fund.'),
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
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                          child: const Text('Approve & Pay'),
                        ),
                      ],
                    ),
                  );
                } else if (isApproved) {
                  // ২. Repay Dialog (NEW)
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Mark as Repaid?'),
                      content: Text(
                          'Has ${loan.borrowerName} returned ৳${loan.amount}?\nThis will add the amount back to the Community Fund.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // কল করা হচ্ছে repayLoan
                            ref.read(loanControllerProvider.notifier).repayLoan(
                              loan: loan,
                              context: context,
                            );
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                          child: const Text('Confirm Repayment'),
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