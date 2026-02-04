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
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Transparency & History',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black87),
          bottom: TabBar(
            isScrollable: true,
            padding: const EdgeInsets.only(bottom: 10),
            indicatorSize: TabBarIndicatorSize.label,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: Colors.teal.shade50,
              border: Border.all(color: Colors.teal.shade200),
            ),
            labelColor: Colors.teal.shade700,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Donations', icon: Icon(Icons.volunteer_activism_rounded)),
              Tab(text: 'Investments', icon: Icon(Icons.trending_up_rounded)),
              Tab(text: 'Expenses', icon: Icon(Icons.money_off_csred_rounded)),
              Tab(text: 'Loans', icon: Icon(Icons.request_quote_rounded)),
            ],
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

// -----------------------------------------------------------------------------
// 1. DONATION LIST
// -----------------------------------------------------------------------------
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
        if (data.isEmpty) return _buildEmptyState(Icons.volunteer_activism, "No donations yet");

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final donation = data[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: _cardDecoration(),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_downward_rounded, color: Colors.green.shade700),
                ),
                title: Text(
                  donation.senderName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text(
                  DateFormat('dd MMM, hh:mm a').format(donation.timestamp),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                trailing: Text(
                  '+ ৳${donation.amount}',
                  style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// 2. INVESTMENT LIST (Updated with Modern UI & Logic)
// -----------------------------------------------------------------------------
class _InvestmentList extends ConsumerWidget {
  final String communityId;
  const _InvestmentList({required this.communityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investmentsAsync = ref.watch(communityInvestmentsProvider(communityId));
    final communityAsync = ref.watch(communityDetailsProvider(communityId));
    final currentUser = FirebaseAuth.instance.currentUser;

    return investmentsAsync.when(
      loading: () => const Loader(),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (investments) {
        return communityAsync.when(
          loading: () => const Loader(),
          error: (e, s) => const SizedBox(),
          data: (community) {
            final isAdmin = currentUser != null && currentUser.uid == community.adminId;

            if (investments.isEmpty) return _buildEmptyState(Icons.show_chart, "No investments found");

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: investments.length,
              itemBuilder: (context, index) {
                final invest = investments[index];
                final isActive = invest.status == 'active';
                final isProfit = invest.actualProfitLoss != null && invest.actualProfitLoss! >= 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: _cardDecoration(),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.orange.shade50 : (isProfit ? Colors.green.shade50 : Colors.red.shade50),
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              invest.projectName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            _buildStatusBadge(
                              isActive ? "RUNNING" : "CLOSED",
                              isActive ? Colors.orange : (isProfit ? Colors.green : Colors.red),
                            ),
                          ],
                        ),
                      ),

                      // Body
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatColumn("Invested", "৳${invest.investedAmount}", Colors.black87),
                            Container(width: 1, height: 40, color: Colors.grey.shade300),
                            if (isActive)
                              _buildStatColumn("Exp. Profit", "৳${invest.expectedProfit}", Colors.orange)
                            else
                              _buildStatColumn(
                                  isProfit ? "Net Profit" : "Net Loss",
                                  "৳${invest.actualProfitLoss}",
                                  isProfit ? Colors.green : Colors.red
                              ),
                          ],
                        ),
                      ),

                      // Footer Action (Admin Only)
                      if (isActive && isAdmin) ...[
                        const Divider(height: 1),
                        InkWell(
                          onTap: () => _showReturnDialog(context, ref, invest),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                            ),
                            child: const Center(
                              child: Text(
                                "Record Return / Close Project",
                                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        )
                      ] else if (!isActive) ...[
                        const Divider(height: 1),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: Text(
                              "Returned: ৳${invest.returnAmount}",
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ),
                        )
                      ]
                    ],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Close Investment"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Project: ${invest.projectName}", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text("Invested Capital: ৳${invest.investedAmount}", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            TextField(
              controller: returnController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Total Returned Amount",
                helperText: "Principal + Profit (or - Loss)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixText: "৳ ",
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
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
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Confirm Close"),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 3. ACTIVITY / EXPENSE LIST
// -----------------------------------------------------------------------------
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
        if (data.isEmpty) return _buildEmptyState(Icons.money_off, "No expenses recorded");

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final activity = data[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: _cardDecoration(),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.receipt_long_rounded, color: Colors.red.shade700),
                ),
                title: Text(activity.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(activity.type, style: const TextStyle(fontSize: 12)),
                trailing: Text(
                  '- ৳${activity.cost}',
                  style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// 4. LOAN LIST (Redesigned with Action Buttons)
// -----------------------------------------------------------------------------
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
        if (data.isEmpty) return _buildEmptyState(Icons.handshake, "No loan requests");

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final loan = data[index];
            final isPending = loan.status == 'pending';
            final isApproved = loan.status == 'approved';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: _cardDecoration(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: User & Amount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.teal.shade100,
                              radius: 18,
                              child: Text(loan.borrowerName[0].toUpperCase(), style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(loan.borrowerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text("Reason: ${loan.reason}", style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                              ],
                            )
                          ],
                        ),
                        Text(
                          "৳${loan.amount}",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Status Badge & Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatusBadge(
                            loan.status.toUpperCase(),
                            isPending ? Colors.orange : (isApproved ? Colors.blue : Colors.green)
                        ),

                        // Action Buttons
                        if (isPending)
                          ElevatedButton.icon(
                            onPressed: () => _confirmAction(context, ref, loan, "approve"),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text("Approve"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          )
                        else if (isApproved)
                          ElevatedButton.icon(
                            onPressed: () => _confirmAction(context, ref, loan, "repay"),
                            icon: const Icon(Icons.assignment_return, size: 16),
                            label: const Text("Mark Repaid"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          )
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmAction(BuildContext context, WidgetRef ref, LoanModel loan, String action) {
    final isApprove = action == "approve";
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isApprove ? 'Approve Loan Request?' : 'Confirm Repayment?'),
        content: Text(
            isApprove
                ? 'This will deduct ৳${loan.amount} from the Community Fund and give it to ${loan.borrowerName}.'
                : 'Has ${loan.borrowerName} returned the full amount of ৳${loan.amount} to the fund?'
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (isApprove) {
                ref.read(loanControllerProvider.notifier).approveLoan(loan: loan, context: context);
              } else {
                ref.read(loanControllerProvider.notifier).repayLoan(loan: loan, context: context);
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: isApprove ? Colors.blue : Colors.teal, foregroundColor: Colors.white),
            child: Text(isApprove ? 'Approve' : 'Confirm'),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// HELPER WIDGETS (Styling)
// -----------------------------------------------------------------------------

Widget _buildEmptyState(IconData icon, String message) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 60, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(message, style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
      ],
    ),
  );
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.1),
        spreadRadius: 1,
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

Widget _buildStatusBadge(String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
    ),
  );
}

Widget _buildStatColumn(String label, String value, Color valueColor) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valueColor)),
    ],
  );
}