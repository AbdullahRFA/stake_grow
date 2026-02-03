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
import 'package:uuid/uuid.dart';

final investmentRepositoryProvider = Provider((ref) {
  return InvestmentRepository(firestore: FirebaseFirestore.instance);
});

class InvestmentRepository {
  final FirebaseFirestore _firestore;

  InvestmentRepository({required FirebaseFirestore firestore}) : _firestore = firestore;

  FutureEither<void> createInvestment(InvestmentModel investment) async {
    try {
      final communityRef = _firestore.collection('communities').doc(investment.communityId);
      final investmentRef = _firestore.collection('investments').doc(investment.id);
      final cid = investment.communityId;

      // 1. FETCH ALL RELEVANT DATA (Donations, Investments, Loans, Activities)
      // We need this to calculate the TRUE liquid balance of users
      final donationsSnap = await _firestore.collection('donations').where('communityId', isEqualTo: cid).get();
      final investmentsSnap = await _firestore.collection('investments').where('communityId', isEqualTo: cid).get();
      final loansSnap = await _firestore.collection('loans').where('communityId', isEqualTo: cid).get();
      final activitiesSnap = await _firestore.collection('activities').where('communityId', isEqualTo: cid).get();

      final donations = donationsSnap.docs.map((e) => DonationModel.fromMap(e.data())).toList();
      final investments = investmentsSnap.docs.map((e) => InvestmentModel.fromMap(e.data())).toList();
      final loans = loansSnap.docs.map((e) => LoanModel.fromMap(e.data())).toList();
      final activities = activitiesSnap.docs.map((e) => ActivityModel.fromMap(e.data())).toList();

      // 2. CALCULATE LIQUID BALANCES
      Map<String, double> userLiquidBalances = FinancialCalculator.calculateUserLiquidBalances(
        donations: donations,
        investments: investments,
        loans: loans,
        activities: activities,
      );

      // 3. CALCULATE SHARES FOR NEW INVESTMENT
      double totalLiquidPool = userLiquidBalances.values.fold(0.0, (sum, val) => sum + val);

      // Validation: Can the community afford this?
      // Note: We use a small epsilon for float comparison safety if needed, or straight comparison
      if (totalLiquidPool < investment.investedAmount) {
        return left(Failure("Insufficient liquid funds among members to support this investment. Total Liquid: ৳$totalLiquidPool"));
      }

      Map<String, double> calculatedUserShares = {};
      if (totalLiquidPool > 0) {
        userLiquidBalances.forEach((uid, balance) {
          if (balance > 0) {
            // Logic: Your Share = (Your Liquid / Total Liquid) * Investment Cost
            double sharePercentage = balance / totalLiquidPool;
            double shareAmount = investment.investedAmount * sharePercentage;
            calculatedUserShares[uid] = double.parse(shareAmount.toStringAsFixed(2));
          }
        });
      }

      final investmentWithShares = InvestmentModel(
        id: investment.id,
        communityId: investment.communityId,
        projectName: investment.projectName,
        details: investment.details,
        investedAmount: investment.investedAmount,
        expectedProfit: investment.expectedProfit,
        status: investment.status,
        startDate: investment.startDate,
        userShares: calculatedUserShares, // ✅ Uses Liquid Logic
      );

      // 4. SAVE TO DB (Transaction)
      await _firestore.runTransaction((transaction) async {
        final communityDoc = await transaction.get(communityRef);
        if (!communityDoc.exists) throw Exception("Community not found");

        double currentBalance = (communityDoc.data()?['totalFund'] ?? 0.0).toDouble();

        if (currentBalance < investment.investedAmount) {
          throw Exception("Insufficient funds in Community Wallet! Available: ৳$currentBalance");
        }

        double newFund = currentBalance - investment.investedAmount;
        transaction.update(communityRef, {'totalFund': newFund});
        transaction.set(investmentRef, investmentWithShares.toMap());
      });

      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Stream<List<InvestmentModel>> getInvestments(String communityId) {
    return _firestore
        .collection('investments')
        .where('communityId', isEqualTo: communityId)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((event) => event.docs
        .map((e) => InvestmentModel.fromMap(e.data()))
        .toList());
  }

  FutureEither<void> closeInvestment({
    required String communityId,
    required String investmentId,
    required double returnAmount,
    required double profitOrLoss,
  }) async {
    try {
      final communityRef = _firestore.collection('communities').doc(communityId);
      final investmentRef = _firestore.collection('investments').doc(investmentId);

      await _firestore.runTransaction((transaction) async {
        final investDoc = await transaction.get(investmentRef);
        if (!investDoc.exists) throw Exception("Investment not found");

        final investment = InvestmentModel.fromMap(investDoc.data()!);
        final userShares = investment.userShares;
        final totalInvested = investment.investedAmount;

        final communityDoc = await transaction.get(communityRef);
        double currentFund = (communityDoc.data()?['totalFund'] ?? 0.0).toDouble();
        double newFund = currentFund + returnAmount;
        transaction.update(communityRef, {'totalFund': newFund});

        userShares.forEach((uid, investedShare) {
          if (totalInvested > 0) {
            double shareRatio = investedShare / totalInvested;
            double userProfitOrLoss = profitOrLoss * shareRatio;

            final donationId = const Uuid().v1();
            final type = userProfitOrLoss >= 0 ? 'Profit Share' : 'Loss Adjustment';

            final record = DonationModel(
              id: donationId,
              communityId: communityId,
              senderId: uid,
              senderName: "System Distribution",
              amount: double.parse(userProfitOrLoss.toStringAsFixed(2)),
              type: type,
              timestamp: DateTime.now(),
              status: 'approved',
            );

            final donationRef = _firestore.collection('donations').doc(donationId);
            transaction.set(donationRef, record.toMap());
          }
        });

        transaction.update(investmentRef, {
          'status': 'completed',
          'returnAmount': returnAmount,
          'actualProfitLoss': profitOrLoss,
          'endDate': DateTime.now().millisecondsSinceEpoch,
        });
      });

      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  FutureEither<void> updateInvestment(InvestmentModel investment) async {
    try {
      await _firestore.collection('investments').doc(investment.id).update({
        'projectName': investment.projectName,
        'details': investment.details,
        'expectedProfit': investment.expectedProfit,
      });
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  FutureEither<void> deleteInvestment(String communityId, String investmentId) async {
    try {
      final communityRef = _firestore.collection('communities').doc(communityId);
      final investmentRef = _firestore.collection('investments').doc(investmentId);

      await _firestore.runTransaction((transaction) async {
        final investDoc = await transaction.get(investmentRef);
        if (!investDoc.exists) throw Exception("Investment not found");

        final investedAmount = (investDoc.data()?['investedAmount'] ?? 0.0).toDouble();

        // Refund money to community
        final communityDoc = await transaction.get(communityRef);
        if (communityDoc.exists) {
          double currentFund = (communityDoc.data()?['totalFund'] ?? 0.0).toDouble();
          transaction.update(communityRef, {'totalFund': currentFund + investedAmount});
        }

        // Delete the investment
        transaction.delete(investmentRef);
      });

      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}