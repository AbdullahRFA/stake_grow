import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stake_grow/core/common/loader.dart';
import 'package:stake_grow/features/community/domain/community_model.dart';
import 'package:stake_grow/features/community/domain/withdrawal_model.dart';
import 'package:stake_grow/features/community/presentation/community_controller.dart';
import 'package:stake_grow/features/community/presentation/transaction_providers.dart';
import 'package:stake_grow/features/community/presentation/user_stats_provider.dart';
import 'package:uuid/uuid.dart';

class WithdrawalScreen extends ConsumerStatefulWidget {
  final CommunityModel community;
  const WithdrawalScreen({super.key, required this.community});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends ConsumerState<WithdrawalScreen> {
  final amountController = TextEditingController();
  final reasonController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Error: Not logged in")));

    // 1. Calculate Duration
    final joinTimestamp = widget.community.memberJoinDates[user.uid] ?? widget.community.createdAt.millisecondsSinceEpoch;
    final joinDate = DateTime.fromMillisecondsSinceEpoch(joinTimestamp);
    final now = DateTime.now();
    final difference = now.difference(joinDate).inDays;
    final isLocked = difference < (365 * 3); // 3 Years (approx 1095 days)

    // 2. Fetch User Stats (Liquid Balance)
    final statsAsync = ref.watch(userStatsProvider(widget.community.id));
    final withdrawalsAsync = ref.watch(communityWithdrawalsProvider(widget.community.id));

    return Scaffold(
      appBar: AppBar(title: const Text("Fund Withdrawal")),
      body: statsAsync.when(
        loading: () => const Loader(),
        error: (e, s) => Center(child: Text("Error: $e")),
        data: (stats) {
          final maxWithdrawal = stats.totalDonated; // Liquid Balance

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Policy Card
                _buildPolicyCard(isLocked, joinDate, maxWithdrawal),
                const SizedBox(height: 20),

                if (isLocked)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red)),
                    child: const Text(
                      "⚠️ Early Withdrawal Warning:\nSince you are withdrawing before 3 years, this is considered an 'Emergency Exit'.\n\nYou may need to:\n1. Transfer/Sell your share to another member.\n2. Or wait for Admin approval if community funds permit.",
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),

                const SizedBox(height: 20),

                // 🔹 Request Form
                const Text("Request Withdrawal", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Amount (Max: ৳${maxWithdrawal.toStringAsFixed(0)})",
                    prefixText: "৳ ",
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Reason",
                    hintText: "Why do you need to withdraw?",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _submitRequest(user, maxWithdrawal, isLocked),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLocked ? Colors.redAccent : Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(15),
                    ),
                    child: Text(isLocked ? "Request Emergency Withdrawal" : "Submit Withdrawal Request"),
                  ),
                ),

                const SizedBox(height: 30),
                const Divider(),
                const Text("My Requests", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),

                // 🔹 History List
                withdrawalsAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, s) => const SizedBox(),
                    data: (requests) {
                      final myRequests = requests.where((r) => r.userId == user.uid).toList();
                      if(myRequests.isEmpty) return const Text("No history.");

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: myRequests.length,
                        itemBuilder: (context, index) {
                          final req = myRequests[index];
                          Color color = req.status == 'pending' ? Colors.orange : (req.status == 'approved' ? Colors.green : Colors.red);
                          return Card(
                            child: ListTile(
                              title: Text("৳${req.amount} (${req.type})"),
                              subtitle: Text("Status: ${req.status.toUpperCase()}\n${DateFormat('dd MMM yyyy').format(req.requestDate)}"),
                              trailing: Icon(Icons.circle, color: color, size: 12),
                            ),
                          );
                        },
                      );
                    }
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPolicyCard(bool isLocked, DateTime joinDate, double balance) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(isLocked ? Icons.lock : Icons.lock_open, color: isLocked ? Colors.red : Colors.green, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isLocked ? "Withdrawal Locked" : "Withdrawal Unlocked", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Joined: ${DateFormat('dd MMM yyyy').format(joinDate)}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Available Liquid Balance:"),
                Text("৳ ${balance.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal)),
              ],
            ),
            if(isLocked)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text("Standard withdrawal available after 3 years.", style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
              ),
          ],
        ),
      ),
    );
  }

  void _submitRequest(User user, double maxLimit, bool isLocked) {
    final amount = double.tryParse(amountController.text.trim());
    final reason = reasonController.text.trim();

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Amount")));
      return;
    }
    if (amount > maxLimit) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Insufficient Liquid Balance!")));
      return;
    }
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please provide a reason")));
      return;
    }

    final req = WithdrawalModel(
      id: const Uuid().v1(),
      communityId: widget.community.id,
      userId: user.uid,
      userName: user.displayName ?? "Member",
      amount: amount,
      reason: reason,
      type: isLocked ? "Early Exit" : "Standard",
      status: 'pending',
      requestDate: DateTime.now(),
    );

    ref.read(communityControllerProvider.notifier).requestWithdrawal(req, context);
  }
}