import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stake_grow/core/failure.dart';
import 'package:stake_grow/core/type_defs.dart';
import 'package:stake_grow/features/loan/domain/loan_model.dart';

final loanRepositoryProvider = Provider((ref) {
  return LoanRepository(firestore: FirebaseFirestore.instance);
});

class LoanRepository {
  final FirebaseFirestore _firestore;

  LoanRepository({required FirebaseFirestore firestore}) : _firestore = firestore;

  // লোন রিকোয়েস্ট সাবমিট করা
  FutureEither<void> requestLoan(LoanModel loan) async {
    try {
      // loans কালেকশনে ডাটা সেভ করা
      await _firestore.collection('loans').doc(loan.id).set(loan.toMap());
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  // একটি কমিউনিটির সব লোন রিকোয়েস্ট দেখার স্ট্রিম
  Stream<List<LoanModel>> getCommunityLoans(String communityId) {
    return _firestore
        .collection('loans')
        .where('communityId', isEqualTo: communityId)
        .orderBy('requestDate', descending: true)
        .snapshots()
        .map((event) {
      List<LoanModel> loans = [];
      for (var doc in event.docs) {
        loans.add(LoanModel.fromMap(doc.data()));
      }
      return loans;
    });
  }
  // লোন এপ্রুভ করার ACID ট্রানজেকশন
  // লোন এপ্রুভ করার ACID ট্রানজেকশন (Fixed)
  FutureEither<void> approveLoan(LoanModel loan) async {
    try {
      final communityRef = _firestore.collection('communities').doc(loan.communityId);
      final loanRef = _firestore.collection('loans').doc(loan.id);

      // 1️⃣ Optimistic Check: ট্রানজেকশন শুরুর আগেই ব্যালেন্স চেক (Web Error Fix)
      final snapshot = await communityRef.get();
      if (!snapshot.exists) {
        return left(Failure("Community not found"));
      }

      double currentFund = (snapshot.data()?['totalFund'] ?? 0.0).toDouble();

      // যদি টাকা কম থাকে, ট্রানজেকশনে ঢোকার দরকার নেই
      if (currentFund < loan.amount) {
        return left(Failure("Insufficient fund! Available: ৳$currentFund"));
      }

      // 2️⃣ ACID Transaction
      await _firestore.runTransaction((transaction) async {
        // ডাবল চেক (Safety First)
        final freshSnapshot = await transaction.get(communityRef);
        double freshBalance = (freshSnapshot.data()?['totalFund'] ?? 0.0).toDouble();

        if (freshBalance < loan.amount) {
          throw Exception("Insufficient fund!");
        }

        // ফান্ড আপডেট (টাকা কমানো)
        double newFund = freshBalance - loan.amount;
        transaction.update(communityRef, {'totalFund': newFund});

        // লোন স্ট্যাটাস আপডেট
        transaction.update(loanRef, {'status': 'approved'});
      });

      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}