import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stake_grow/core/failure.dart';
import 'package:stake_grow/core/type_defs.dart';
import 'package:stake_grow/features/investment/domain/investment_model.dart';

final investmentRepositoryProvider = Provider((ref) {
  return InvestmentRepository(firestore: FirebaseFirestore.instance);
});

class InvestmentRepository {
  final FirebaseFirestore _firestore;

  InvestmentRepository({required FirebaseFirestore firestore}) : _firestore = firestore;

  // ... createInvestment and getInvestments ... (Keep them as is)
  FutureEither<void> createInvestment(InvestmentModel investment) async {
    // ... (Old Code) ...
    try {
      final communityRef = _firestore.collection('communities').doc(investment.communityId);
      final investmentRef = _firestore.collection('investments').doc(investment.id);

      final snapshot = await communityRef.get();
      if (!snapshot.exists) return left(Failure("Community not found"));

      double currentBalance = (snapshot.data()?['totalFund'] ?? 0.0).toDouble();

      if (currentBalance < investment.investedAmount) {
        return left(Failure("Insufficient funds! Available: ৳$currentBalance"));
      }

      await _firestore.runTransaction((transaction) async {
        final freshSnapshot = await transaction.get(communityRef);
        double freshBalance = (freshSnapshot.data()?['totalFund'] ?? 0.0).toDouble();

        if (freshBalance < investment.investedAmount) throw Exception("Insufficient funds!");

        double newFund = freshBalance - investment.investedAmount;
        transaction.update(communityRef, {'totalFund': newFund});
        transaction.set(investmentRef, investment.toMap());
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

  // ✅ NEW: ইনভেস্টমেন্ট ক্লোজ করা এবং ফান্ডে টাকা ফেরত আনা
  FutureEither<void> closeInvestment({
    required String communityId,
    required String investmentId,
    required double returnAmount, // মোট কত টাকা ফেরত এসেছে
    required double profitOrLoss, // লাভ বা লস
  }) async {
    try {
      final communityRef = _firestore.collection('communities').doc(communityId);
      final investmentRef = _firestore.collection('investments').doc(investmentId);

      await _firestore.runTransaction((transaction) async {
        // ১. কমিউনিটি ফান্ড রিড করা
        final communityDoc = await transaction.get(communityRef);
        if (!communityDoc.exists) throw Exception("Community not found");

        double currentFund = (communityDoc.data()?['totalFund'] ?? 0.0).toDouble();

        // ২. ফান্ড আপডেট (বর্তমান ফান্ড + ফেরত আসা টাকা)
        // লাভ হলে ফান্ড বাড়বে, ক্ষতি হলে কম টাকা ফেরত আসবে, তাই ফান্ড কম বাড়বে (যা লস হিসেবে কাউন্ট হবে)
        double newFund = currentFund + returnAmount;

        transaction.update(communityRef, {'totalFund': newFund});

        // ৩. ইনভেস্টমেন্ট আপডেট (Completed)
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
}