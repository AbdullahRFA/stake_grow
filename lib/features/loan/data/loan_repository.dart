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

  // Request Loan
  FutureEither<void> requestLoan(LoanModel loan) async {
    try {
      await _firestore.collection('loans').doc(loan.id).set(loan.toMap());
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  // Get Community Loans
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

  // Approve Loan
  FutureEither<void> approveLoan(LoanModel loan) async {
    try {
      final communityRef = _firestore.collection('communities').doc(loan.communityId);
      final loanRef = _firestore.collection('loans').doc(loan.id);

      final snapshot = await communityRef.get();
      if (!snapshot.exists) return left(Failure("Community not found"));

      double currentFund = (snapshot.data()?['totalFund'] ?? 0.0).toDouble();

      if (currentFund < loan.amount) {
        return left(Failure("Insufficient fund! Available: ৳$currentFund"));
      }

      await _firestore.runTransaction((transaction) async {
        final freshSnapshot = await transaction.get(communityRef);
        double freshBalance = (freshSnapshot.data()?['totalFund'] ?? 0.0).toDouble();

        if (freshBalance < loan.amount) throw Exception("Insufficient fund!");

        double newFund = freshBalance - loan.amount;
        transaction.update(communityRef, {'totalFund': newFund});
        transaction.update(loanRef, {'status': 'approved'});
      });

      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  // Repay Loan
  FutureEither<void> repayLoan(LoanModel loan) async {
    try {
      final communityRef = _firestore.collection('communities').doc(loan.communityId);
      final loanRef = _firestore.collection('loans').doc(loan.id);

      await _firestore.runTransaction((transaction) async {
        final communityDoc = await transaction.get(communityRef);
        if (!communityDoc.exists) throw Exception("Community not found");

        double currentFund = (communityDoc.data()?['totalFund'] ?? 0.0).toDouble();
        double newFund = currentFund + loan.amount;

        transaction.update(communityRef, {'totalFund': newFund});
        transaction.update(loanRef, {'status': 'repaid'});
      });

      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  // ✅ NEW: Delete Loan (Only if Pending)
  FutureEither<void> deleteLoan(String loanId) async {
    try {
      await _firestore.collection('loans').doc(loanId).delete();
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  // ✅ NEW: Update Loan (Only if Pending)
  FutureEither<void> updateLoan(LoanModel loan) async {
    try {
      await _firestore.collection('loans').doc(loan.id).update(loan.toMap());
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}