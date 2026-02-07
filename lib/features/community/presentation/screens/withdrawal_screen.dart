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

  // State variables for exact calendar breakdown
  int _years = 0, _months = 0, _days = 0, _hours = 0, _minutes = 0, _seconds = 0;
  bool _isLocked = false;
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

      // Strict 3 Years Lock Period from Join Date
      _unlockDate = DateTime(joinDate.year + 3, joinDate.month, joinDate.day, joinDate.hour, joinDate.minute);

      _updateCountdown();
    }
  }

  void _updateCountdown() {
    if (_unlockDate == null) return;
    final now = DateTime.now();

    if (_unlockDate!.isAfter(now)) {
      _isLocked = true;

      // Strict Calendar Calculation Logic
      int years = _unlockDate!.year - now.year;
      int months = _unlockDate!.month - now.month;
      int days = _unlockDate!.day - now.day;
      int hours = _unlockDate!.hour - now.hour;
      int minutes = _unlockDate!.minute - now.minute;
      int seconds = _unlockDate!.second - now.second;

      // Handle borrow-over logic for negative components
      if (seconds < 0) {
        seconds += 60;
        minutes--;
      }
      if (minutes < 0) {
        minutes += 60;
        hours--;
      }
      if (hours < 0) {
        hours += 24;
        days--;
      }
      if (days < 0) {
        // Calculate days in the previous month
        final prevMonth = DateTime(_unlockDate!.year, _unlockDate!.month - 1);
        days += DateTime(prevMonth.year, prevMonth.month + 1, 0).day;
        months--;
      }
      if (months < 0) {
        months += 12;
        years--;
      }

      setState(() {
        _years = years;
        _months = months;
        _days = days;
        _hours = hours;
        _minutes = minutes;
        _seconds = seconds;
      });
    } else {
      setState(() {
        _isLocked = false;
        _years = 0; _months = 0; _days = 0; _hours = 0; _minutes = 0; _seconds = 0;
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCountdown();
      if (!_isLocked) timer.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Error: Not logged in")));

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
          final maxWithdrawal = stats.totalDonated;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLockStatusCard(),
                const SizedBox(height: 20),
                _buildBalanceDisplay(maxWithdrawal),
                const SizedBox(height: 24),
                if (_isLocked) _buildPenaltyWarning(),
                _buildForm(user, maxWithdrawal),
                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(height: 10),
                const Text("Request History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),
                _buildHistoryList(withdrawalsAsync, user.uid),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- UI Components ---

  Widget _buildLockStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_isLocked ? Icons.lock_outline : Icons.lock_open_rounded,
                  color: _isLocked ? Colors.orange : Colors.green, size: 28),
              const SizedBox(width: 8),
              Text(
                _isLocked ? "Maturity Locked" : "Funds Unlocked",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isLocked ? Colors.orange.shade800 : Colors.green.shade800),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLocked)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _timeBox(_years, "Yrs"),
                _colon(),
                _timeBox(_months, "Mths"),
                _colon(),
                _timeBox(_days, "Days"),
                _colon(),
                _timeBox(_hours, "Hrs"),
                _colon(),
                _timeBox(_minutes, "Min"),
                _colon(),
                _timeBox(_seconds, "Sec"),
              ],
            )
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

  Widget _buildBalanceDisplay(double maxWithdrawal) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade700, Colors.teal.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
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
          Text("৳${maxWithdrawal.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPenaltyWarning() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Early Withdrawal Penalty", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB71C1C))),
                SizedBox(height: 4),
                Text(
                  "Withdrawing before maturity is considered an 'Emergency Exit'. Admin approval or share transfer is required.",
                  style: TextStyle(fontSize: 12, color: Color(0xFFD32F2F)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(User user, double maxWithdrawal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text("Request Amount", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixText: "৳ ",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),
        const Text("Reason for Withdrawal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Briefly explain why you need to withdraw...",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 55,
          child: ElevatedButton(
            onPressed: () => _submitRequest(user, maxWithdrawal, _isLocked),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isLocked ? Colors.redAccent : Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(_isLocked ? "Request Emergency Withdrawal" : "Submit Withdrawal Request"),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList(AsyncValue<List<WithdrawalModel>> withdrawalsAsync, String uid) {
    return withdrawalsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => const SizedBox(),
      data: (requests) {
        final myRequests = requests.where((r) => r.userId == uid).toList();
        myRequests.sort((a, b) => b.requestDate.compareTo(a.requestDate));

        if (myRequests.isEmpty) return const Center(child: Text("No history found."));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: myRequests.length,
          itemBuilder: (context, index) => _buildHistoryItem(myRequests[index]),
        );
      },
    );
  }

  Widget _timeBox(int value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          constraints: const BoxConstraints(minWidth: 35),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
          child: Text(value.toString().padLeft(2, '0'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }

  Widget _colon() => const Padding(padding: EdgeInsets.only(bottom: 14), child: Text(":", style: TextStyle(fontWeight: FontWeight.bold)));

  Widget _buildHistoryItem(WithdrawalModel req) {
    final color = req.status == 'approved' ? Colors.green : (req.status == 'rejected' ? Colors.red : Colors.orange);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text("৳${req.amount.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(DateFormat('dd MMM yyyy').format(req.requestDate)),
        trailing: Chip(label: Text(req.status.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white)), backgroundColor: color),
      ),
    );
  }

  void _submitRequest(User user, double maxLimit, bool isLocked) {
    final amount = double.tryParse(amountController.text.trim());
    final reason = reasonController.text.trim();

    if (amount == null || amount <= 0 || amount > maxLimit || reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields correctly")));
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
    amountController.clear();
    reasonController.clear();
  }
}