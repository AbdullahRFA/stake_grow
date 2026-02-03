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
      final cid = loan.communityId;

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

      // 3. CALCULATE LENDER SHARES
      double totalLiquidPool = userLiquidBalances.values.fold(0.0, (sum, val) => sum + val);

      if (totalLiquidPool < loan.amount) {
        return left(Failure("Insufficient liquid funds to grant this loan."));
      }

      Map<String, double> calculatedLenderShares = {};
      if (totalLiquidPool > 0) {
        userLiquidBalances.forEach((uid, balance) {
          if (balance > 0) {
            double sharePercentage = balance / totalLiquidPool;
            double shareAmount = loan.amount * sharePercentage;
            calculatedLenderShares[uid] = double.parse(shareAmount.toStringAsFixed(2));
          }
        });
      }

      // 4. TRANSACTION
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
          'lenderShares': calculatedLenderShares, // ✅ Based on Liquid Balance
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