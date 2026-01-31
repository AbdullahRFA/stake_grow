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
      );

      final res = await _repo.createInvestment(investment);
      state = false;

      res.fold(
            (l) => showSnackBar(context, l.message),
            (r) {
          showSnackBar(context, 'Investment Started Successfully! 📉'); // 📉 = Fund down (Invested)
          Navigator.pop(context);
        },
      );
    } else {
      state = false;
      showSnackBar(context, 'Access Denied');
    }
  }
}