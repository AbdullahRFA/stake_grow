import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stake_grow/core/utils/utils.dart';
import 'package:stake_grow/features/investment/data/investment_repository.dart';
import 'package:stake_grow/features/investment/domain/investment_model.dart';
import 'package:uuid/uuid.dart';

final investmentControllerProvider = StateNotifierProvider<InvestmentController, bool>((ref) {
  final repo = ref.watch(investmentRepositoryProvider);
  return InvestmentController(repo: repo);
});

class InvestmentController extends StateNotifier<bool> {
  final InvestmentRepository _repo;

  InvestmentController({required InvestmentRepository repo})
      : _repo = repo,
        super(false);

  void createInvestment({
    required String communityId,
    required String projectName,
    required String details,
    required double amount,
    required double expectedProfit,
    required BuildContext context,
  }) async {
    state = true;
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final investmentId = const Uuid().v1();
      final investment = InvestmentModel(
        id: investmentId,
        communityId: communityId,
        projectName: projectName,
        details: details,
        investedAmount: amount,
        expectedProfit: expectedProfit,
        status: 'active',
        startDate: DateTime.now(),
        userShares: {},
      );

      final res = await _repo.createInvestment(investment);
      state = false;
      res.fold(
            (l) => showSnackBar(context, l.message),
            (r) {
          showSnackBar(context, 'Investment Started Successfully! 📉');
          Navigator.pop(context);
        },
      );
    } else {
      state = false;
      showSnackBar(context, 'Access Denied');
    }
  }

  void closeInvestment({
    required String communityId,
    required String investmentId,
    required double investedAmount,
    required double returnAmount,
    required BuildContext context,
  }) async {
    state = true;
    double profitOrLoss = returnAmount - investedAmount;

    final res = await _repo.closeInvestment(
      communityId: communityId,
      investmentId: investmentId,
      returnAmount: returnAmount,
      profitOrLoss: profitOrLoss,
    );

    state = false;

    res.fold(
          (l) => showSnackBar(context, l.message),
          (r) {
        if (profitOrLoss >= 0) {
          showSnackBar(context, 'Profit Added to Fund! 🎉 (+৳$profitOrLoss)');
        } else {
          showSnackBar(context, 'Investment Closed with Loss. ⚠️ (৳$profitOrLoss)');
        }
        Navigator.pop(context);
      },
    );
  }

  // ✅ Update Investment
  void updateInvestment({
    required InvestmentModel investment,
    required BuildContext context,
  }) async {
    final res = await _repo.updateInvestment(investment);
    res.fold(
          (l) => showSnackBar(context, l.message),
          (r) {
        showSnackBar(context, 'Investment Updated Successfully');
        Navigator.pop(context); // Close dialog
      },
    );
  }

  // ✅ Delete Investment
  void deleteInvestment({
    required String communityId,
    required String investmentId,
    required BuildContext context,
  }) async {
    final res = await _repo.deleteInvestment(communityId, investmentId);
    res.fold(
          (l) => showSnackBar(context, l.message),
          (r) {
        showSnackBar(context, 'Investment Deleted & Funds Refunded');
        Navigator.pop(context); // Close dialog if open
      },
    );
  }
}