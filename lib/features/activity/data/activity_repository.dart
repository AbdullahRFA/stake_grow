import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stake_grow/core/failure.dart';
import 'package:stake_grow/core/type_defs.dart';
import 'package:stake_grow/core/utils/financial_calculator.dart'; // ✅ New Import
import 'package:stake_grow/features/activity/domain/activity_model.dart';
import 'package:stake_grow/features/donation/domain/donation_model.dart';
import 'package:stake_grow/features/investment/domain/investment_model.dart';
import 'package:stake_grow/features/loan/domain/loan_model.dart';

final activityRepositoryProvider = Provider((ref) {
  return ActivityRepository(firestore: FirebaseFirestore.instance);
});

class ActivityRepository {
  final FirebaseFirestore _firestore;
  ActivityRepository({required FirebaseFirestore firestore}) : _firestore = firestore;

  FutureEither<void> createActivity(ActivityModel activity) async {
    try {
      final communityRef = _firestore.collection('communities').doc(activity.communityId);
      final activityRef = _firestore.collection('activities').doc(activity.id);
      final cid = activity.communityId;

      // 1. FETCH ALL DATA
      final donations = (await _firestore.collection('donations').where('communityId', isEqualTo: cid).get())
          .docs.map((e) => DonationModel.fromMap(e.data())).toList();
      final investments = (await _firestore.collection('investments').where('communityId', isEqualTo: cid).get())
          .docs.map((e) => InvestmentModel.fromMap(e.data())).toList();
      final loans = (await _firestore.collection('loans').where('communityId', isEqualTo: cid).get())
          .docs.map((e) => LoanModel.fromMap(e.data())).toList();
      final activities = (await _firestore.collection('activities').where('communityId', isEqualTo: cid).get())
          .docs.map((e) => ActivityModel.fromMap(e.data())).toList();

      // 2. CALCULATE LIQUID BALANCES
      Map<String, double> userLiquidBalances = FinancialCalculator.calculateUserLiquidBalances(
        donations: donations,
        investments: investments,
        loans: loans,
        activities: activities,
      );

      // 3. CALCULATE EXPENSE SHARES
      double totalLiquidPool = userLiquidBalances.values.fold(0.0, (sum, val) => sum + val);

      if (totalLiquidPool < activity.cost) {
        return left(Failure("Insufficient liquid funds to cover this expense."));
      }

      Map<String, double> calculatedExpenseShares = {};
      if (totalLiquidPool > 0) {
        userLiquidBalances.forEach((uid, balance) {
          if (balance > 0) {
            double sharePercentage = balance / totalLiquidPool;
            double shareAmount = activity.cost * sharePercentage;
            calculatedExpenseShares[uid] = double.parse(shareAmount.toStringAsFixed(2));
          }
        });
      }

      final activityWithShares = ActivityModel(
        id: activity.id,
        communityId: activity.communityId,
        title: activity.title,
        details: activity.details,
        cost: activity.cost,
        date: activity.date,
        type: activity.type,
        expenseShares: calculatedExpenseShares, // ✅ Based on Liquid Balance
      );

      // 4. TRANSACTION
      await _firestore.runTransaction((transaction) async {
        final communityDoc = await transaction.get(communityRef);
        if (!communityDoc.exists) throw Exception("Community not found");

        double currentFund = (communityDoc.data()?['totalFund'] ?? 0.0).toDouble();

        if (currentFund < activity.cost) {
          throw Exception("Insufficient funds! Available: ৳$currentFund");
        }

        double newFund = currentFund - activity.cost;

        transaction.update(communityRef, {'totalFund': newFund});
        transaction.set(activityRef, activityWithShares.toMap());
      });

      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Stream<List<ActivityModel>> getActivities(String communityId) {
    return _firestore
        .collection('activities')
        .where('communityId', isEqualTo: communityId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((event) => event.docs
        .map((e) => ActivityModel.fromMap(e.data()))
        .toList());
  }
}