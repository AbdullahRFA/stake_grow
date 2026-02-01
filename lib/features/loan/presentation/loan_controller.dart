import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stake_grow/core/utils/utils.dart';
import 'package:stake_grow/features/loan/data/loan_repository.dart';
import 'package:stake_grow/features/loan/domain/loan_model.dart';
import 'package:uuid/uuid.dart';

// কমিউনিটি অনুযায়ী লোন দেখার প্রভাইডার
final communityLoansProvider = StreamProvider.family((ref, String communityId) {
  final loanRepo = ref.watch(loanRepositoryProvider);
  return loanRepo.getCommunityLoans(communityId);
});

final loanControllerProvider = StateNotifierProvider<LoanController, bool>((ref) {
  final loanRepo = ref.watch(loanRepositoryProvider);
  return LoanController(loanRepository: loanRepo);
});

class LoanController extends StateNotifier<bool> {
  final LoanRepository _loanRepository;

  LoanController({required LoanRepository loanRepository})
      : _loanRepository = loanRepository,
        super(false);

  void requestLoan({
    required String communityId,
    required double amount,
    required String reason,
    required DateTime repaymentDate,
    required BuildContext context,
  }) async {
    state = true;
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final loanId = const Uuid().v1();

      final loan = LoanModel(
        id: loanId,
        communityId: communityId,
        borrowerId: user.uid,
        borrowerName: user.displayName ?? 'Member',
        amount: amount,
        reason: reason,
        requestDate: DateTime.now(),
        repaymentDate: repaymentDate,
        status: 'pending', // শুরুতে পেন্ডিং থাকবে
      );

      final res = await _loanRepository.requestLoan(loan);
      state = false;

      res.fold(
            (l) => showSnackBar(context, l.message),
            (r) {
          showSnackBar(context, 'Loan Request Submitted! ⏳');
          Navigator.pop(context);
        },
      );
    } else {
      state = false;
      showSnackBar(context, 'User not logged in');
    }
  }
  void approveLoan({
    required LoanModel loan,
    required BuildContext context,
  }) async {
    state = true;
    // এখানে আমরা ধরে নিচ্ছি UI তে আগেই চেক করা হয়েছে ইউজার এডমিন কিনা
    final res = await _loanRepository.approveLoan(loan);
    state = false;

    res.fold(
          (l) => showSnackBar(context, l.message),
          (r) {
        showSnackBar(context, 'Loan Approved & Fund Disbursed! ✅');
        Navigator.pop(context); // ডায়ালগ বন্ধ করা
      },
    );
  }
  // ✅ NEW: Repay Loan Function
  void repayLoan({
    required LoanModel loan,
    required BuildContext context,
  }) async {
    state = true;
    final res = await _loanRepository.repayLoan(loan);
    state = false;

    res.fold(
          (l) => showSnackBar(context, l.message),
          (r) {
        showSnackBar(context, 'Loan Repaid & Fund Restored! 💰');
        Navigator.pop(context); // ডায়ালগ বন্ধ
      },
    );
  }
}