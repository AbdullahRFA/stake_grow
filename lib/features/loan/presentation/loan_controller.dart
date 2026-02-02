import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stake_grow/core/utils/utils.dart';
import 'package:stake_grow/features/auth/data/auth_repository.dart'; // Import Auth Repo
import 'package:stake_grow/features/loan/data/loan_repository.dart';
import 'package:stake_grow/features/loan/domain/loan_model.dart';
import 'package:uuid/uuid.dart';

final communityLoansProvider = StreamProvider.family((ref, String communityId) {
  final loanRepo = ref.watch(loanRepositoryProvider);
  return loanRepo.getCommunityLoans(communityId);
});

final loanControllerProvider = StateNotifierProvider<LoanController, bool>((ref) {
  final loanRepo = ref.watch(loanRepositoryProvider);
  final authRepo = ref.watch(authRepositoryProvider); // ✅ Inject Auth Repo
  return LoanController(loanRepository: loanRepo, authRepository: authRepo);
});

class LoanController extends StateNotifier<bool> {
  final LoanRepository _loanRepository;
  final AuthRepository _authRepository; // ✅ Added

  LoanController({
    required LoanRepository loanRepository,
    required AuthRepository authRepository, // ✅ Added
  })  : _loanRepository = loanRepository,
        _authRepository = authRepository,
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
      // ✅ FIX: Fetch actual user name from Firestore
      String userName = user.displayName ?? 'Member';

      final userModel = await _authRepository.getUserData(user.uid);
      if (userModel != null) {
        userName = userModel.name;
      }

      final loanId = const Uuid().v1();

      final loan = LoanModel(
        id: loanId,
        communityId: communityId,
        borrowerId: user.uid,
        borrowerName: userName, // ✅ Using fetched name
        amount: amount,
        reason: reason,
        requestDate: DateTime.now(),
        repaymentDate: repaymentDate,
        status: 'pending',
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
    final res = await _loanRepository.approveLoan(loan);
    state = false;

    res.fold(
          (l) => showSnackBar(context, l.message),
          (r) {
        showSnackBar(context, 'Loan Approved & Fund Disbursed! ✅');
        Navigator.pop(context);
      },
    );
  }

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
        Navigator.pop(context);
      },
    );
  }
}