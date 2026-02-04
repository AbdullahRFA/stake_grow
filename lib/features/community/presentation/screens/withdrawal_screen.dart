import 'dart:async';
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
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  DateTime? _unlockDate;

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    amountController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  void _calculateRemainingTime() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final joinTimestamp = widget.community.memberJoinDates[user.uid] ??
          widget.community.createdAt.millisecondsSinceEpoch;
      final joinDate = DateTime.fromMillisecondsSinceEpoch(joinTimestamp);

      // 3 Years Lock Period
      _unlockDate = DateTime(joinDate.year + 3, joinDate.month, joinDate.day, joinDate.hour, joinDate.minute);

      final now = DateTime.now();
      if (_unlockDate!.isAfter(now)) {
        setState(() {
          _remainingTime = _unlockDate!.difference(now);
        });
      } else {
        setState(() {
          _remainingTime = Duration.zero;
        });
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_unlockDate == null) return;

      final now = DateTime.now();
      if (_unlockDate!.isAfter(now)) {
        setState(() {
          _remainingTime = _unlockDate!.difference(now);
        });
      } else {
        timer.cancel();
        setState(() {
          _remainingTime = Duration.zero;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Error: Not logged in")));

    final isLocked = _remainingTime.inSeconds > 0;

    // Fetch User Stats (Liquid Balance)
    final statsAsync = ref.watch(userStatsProvider(widget.community.id));
    final withdrawalsAsync = ref.watch(communityWithdrawalsProvider(widget.community.id));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Fund Withdrawal", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: statsAsync.when(
        loading: () => const Loader(),
        error: (e, s) => Center(child: Text("Error: $e")),
        data: (stats) {
          final maxWithdrawal = stats.totalDonated; // Liquid Balance

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Lock Status & Timer Card
                _buildLockStatusCard(isLocked),

                const SizedBox(height: 20),

                // 2. Balance Display
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal.shade700, Colors.teal.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Liquid Balance", style: TextStyle(color: Colors.white70, fontSize: 14)),
                          SizedBox(height: 4),
                          Text("Available for request", style: TextStyle(color: Colors.white38, fontSize: 10)),
                        ],
                      ),
                      Text(
                        "৳${maxWithdrawal.toStringAsFixed(0)}",
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 3. Warning (If Locked)
                if (isLocked)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Early Withdrawal Penalty",
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Withdrawing before the 3-year maturity period is considered an 'Emergency Exit'. You may need to transfer your share or wait for admin approval.",
                                style: TextStyle(fontSize: 12, color: Colors.red.shade800),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // 4. Input Form
                const Text("Request Amount", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.currency_lira, size: 20), // Using Lira as Taka symbol approx if needed, or text
                    prefixText: "৳ ",
                    hintText: "0.00",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                const Text("Reason for Withdrawal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Briefly explain why you need to withdraw funds...",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () => _submitRequest(user, maxWithdrawal, isLocked),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLocked ? Colors.redAccent : Colors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      shadowColor: (isLocked ? Colors.red : Colors.teal).withOpacity(0.4),
                    ),
                    child: Text(
                      isLocked ? "Request Emergency Withdrawal" : "Submit Withdrawal Request",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(height: 10),
                const Text("Request History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),

                // 5. History List
                withdrawalsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => const SizedBox(),
                  data: (requests) {
                    final myRequests = requests.where((r) => r.userId == user.uid).toList();
                    myRequests.sort((a, b) => b.requestDate.compareTo(a.requestDate)); // Newest first

                    if (myRequests.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text("No withdrawal history found.", style: TextStyle(color: Colors.grey.shade500)),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: myRequests.length,
                      itemBuilder: (context, index) {
                        final req = myRequests[index];
                        return _buildHistoryItem(req);
                      },
                    );
                  },
                )
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Widgets ---

  Widget _buildLockStatusCard(bool isLocked) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isLocked ? Icons.lock_outline : Icons.lock_open_rounded,
                  color: isLocked ? Colors.orange : Colors.green, size: 28),
              const SizedBox(width: 8),
              Text(
                isLocked ? "Maturity Locked" : "Funds Unlocked",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isLocked ? Colors.orange.shade800 : Colors.green.shade800
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLocked)
            _buildCountdownTimer()
          else
            const Text(
              "You have completed the 3-year maturity period.\nStandard withdrawals are now enabled.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildCountdownTimer() {
    // Calculate components manually from _remainingTime duration isn't enough because Duration doesn't give Months/Years accurately
    // We will do an approximation for display or strict calculation based on the difference

    // Better approach for UI: Parse duration into components
    // Note: Duration class gives total days. We need to break it down.
    // Simplifying logic for display:
    // This is a rough breakdown. For perfect calendar accuracy, you'd use a library like JodaTime/TimeMachine,
    // but for this UI, basic math is acceptable.

    int days = _remainingTime.inDays;
    int years = (days / 365).floor();
    days = days % 365;
    int months = (days / 30).floor();
    days = days % 30;

    int hours = _remainingTime.inHours % 24;
    int minutes = _remainingTime.inMinutes % 60;
    int seconds = _remainingTime.inSeconds % 60;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _timeBox(years, "Yrs"),
        _colon(),
        _timeBox(months, "Mths"),
        _colon(),
        _timeBox(days, "Days"),
        _colon(),
        _timeBox(hours, "Hrs"),
        _colon(),
        _timeBox(minutes, "Min"),
        _colon(),
        _timeBox(seconds, "Sec"),
      ],
    );
  }

  Widget _timeBox(int value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          constraints: const BoxConstraints(minWidth: 40),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _colon() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 14),
      child: Text(":", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
    );
  }

  Widget _buildHistoryItem(WithdrawalModel req) {
    Color statusColor;
    IconData statusIcon;

    switch (req.status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(statusIcon, color: statusColor, size: 20),
        ),
        title: Text("৳${req.amount.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('dd MMM yyyy, hh:mm a').format(req.requestDate), style: const TextStyle(fontSize: 12)),
            Text(req.type, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            req.status.toUpperCase(),
            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
          ),
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

    // Clear fields after submission
    amountController.clear();
    reasonController.clear();
  }
}