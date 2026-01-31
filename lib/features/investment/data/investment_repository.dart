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

  FutureEither<void> createInvestment(InvestmentModel investment) async {
    try {
      final communityRef = _firestore.collection('communities').doc(investment.communityId);
      final investmentRef = _firestore.collection('investments').doc(investment.id);

      // ✅ FIX: ট্রানজেকশন শুরুর আগেই একবার ব্যালেন্স চেক করে নেওয়া (Optimistic Check)
      // এতে ইউজার সুন্দর এরর মেসেজ পাবে
      final snapshot = await communityRef.get();
      if (!snapshot.exists) {
        return left(Failure("Community not found"));
      }

      double currentBalance = (snapshot.data()?['totalFund'] ?? 0.0).toDouble();

      if (currentBalance < investment.investedAmount) {
        return left(Failure("Insufficient funds! Available: ৳$currentBalance"));
      }

      // যদি ব্যালেন্স ঠিক থাকে, তখন আমরা আসল ACID ট্রানজেকশন চালাব
      await _firestore.runTransaction((transaction) async {
        // ডাবল চেক (Safety First) - যদি এই মিলিসেকন্ডে কেউ টাকা তুলে নেয়
        final freshSnapshot = await transaction.get(communityRef);
        double freshBalance = (freshSnapshot.data()?['totalFund'] ?? 0.0).toDouble();

        if (freshBalance < investment.investedAmount) {
          throw Exception("Insufficient funds!"); // এই এক্সেপশন রেয়ার কেসে আসবে
        }

        // সব ঠিক থাকলে আপডেট করো
        double newFund = freshBalance - investment.investedAmount;
        transaction.update(communityRef, {'totalFund': newFund});
        transaction.set(investmentRef, investment.toMap());
      });

      return right(null);
    } catch (e) {
      // যদি রেয়ার কোনো এরর আসে
      return left(Failure(e.toString()));
    }
  }
}