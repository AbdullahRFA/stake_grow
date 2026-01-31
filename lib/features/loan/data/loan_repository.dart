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
}