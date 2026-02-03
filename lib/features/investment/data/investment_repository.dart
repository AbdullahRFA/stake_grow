import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stake_grow/core/failure.dart';
import 'package:stake_grow/core/type_defs.dart';
import 'package:stake_grow/features/investment/domain/investment_model.dart';
import 'package:stake_grow/features/donation/domain/donation_model.dart';
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

      final donationsSnapshot = await _firestore
          .collection('donations')
          .where('communityId', isEqualTo: investment.communityId)
          .get();

      Map<String, double> userTotalDonations = {};
      double totalPool = 0.0;

      for (var doc in donationsSnapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'approved') {
          final uid = data['senderId'];
          final amount = (data['amount'] ?? 0.0).toDouble();
          userTotalDonations[uid] = (userTotalDonations[uid] ?? 0.0) + amount;
          totalPool += amount;
        }
      }

      Map<String, double> calculatedUserShares = {};

      if (totalPool > 0) {
        userTotalDonations.forEach((uid, totalDonated) {
          if (totalDonated > 0) {
            double sharePercentage = totalDonated / totalPool;
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
        userShares: calculatedUserShares,
      );

      await _firestore.runTransaction((transaction) async {
        final communityDoc = await transaction.get(communityRef);
        if (!communityDoc.exists) throw Exception("Community not found");

        double currentBalance = (communityDoc.data()?['totalFund'] ?? 0.0).toDouble();

        if (currentBalance < investment.investedAmount) {
          throw Exception("Insufficient funds! Available: ৳$currentBalance");
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

  // ✅ NEW: Update Investment (Metadata Only)
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

  // ✅ NEW: Delete Investment (Refunds Money)
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