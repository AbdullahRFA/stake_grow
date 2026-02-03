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

  FutureEither<void> requestLoan(LoanModel loan) async {
    try {
      await _firestore.collection('loans').doc(loan.id).set(loan.toMap());
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

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

  FutureEither<void> approveLoan(LoanModel loan) async {
    try {
      final communityRef = _firestore.collection('communities').doc(loan.communityId);
      final loanRef = _firestore.collection('loans').doc(loan.id);

      final donationsSnapshot = await _firestore
          .collection('donations')
          .where('communityId', isEqualTo: loan.communityId)
          .get();

      Map<String, double> userTotalDonations = {};
      double totalPool = 0.0;

      for (var doc in donationsSnapshot.docs) {
        final data = doc.data();
        // ✅ FIX: Only consider approved money
        if (data['status'] == 'approved') {
          final uid = data['senderId'];
          final amount = (data['amount'] ?? 0.0).toDouble();
          userTotalDonations[uid] = (userTotalDonations[uid] ?? 0.0) + amount;
          totalPool += amount;
        }
      }

      Map<String, double> calculatedLenderShares = {};
      if (totalPool > 0) {
        userTotalDonations.forEach((uid, totalDonated) {
          if (totalDonated > 0) {
            double sharePercentage = totalDonated / totalPool;
            double shareAmount = loan.amount * sharePercentage;
            calculatedLenderShares[uid] = double.parse(shareAmount.toStringAsFixed(2));
          }
        });
      }

      await _firestore.runTransaction((transaction) async {
        final communityDoc = await transaction.get(communityRef);
        if (!communityDoc.exists) throw Exception("Community not found");

        double currentFund = (communityDoc.data()?['totalFund'] ?? 0.0).toDouble();

        if (currentFund < loan.amount) {
          throw Exception("Insufficient fund! Available: ৳$currentFund");
        }

        double newFund = currentFund - loan.amount;

        transaction.update(communityRef, {'totalFund': newFund});
        transaction.update(loanRef, {
          'status': 'approved',
          'lenderShares': calculatedLenderShares,
        });
      });

      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

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

  FutureEither<void> deleteLoan(String loanId) async {
    try {
      await _firestore.collection('loans').doc(loanId).delete();
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  FutureEither<void> updateLoan(LoanModel loan) async {
    try {
      await _firestore.collection('loans').doc(loan.id).update(loan.toMap());
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}