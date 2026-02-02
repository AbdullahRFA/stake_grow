import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stake_grow/core/failure.dart';
import 'package:stake_grow/core/type_defs.dart';
import 'package:stake_grow/features/investment/domain/investment_model.dart';
import 'package:stake_grow/features/donation/domain/donation_model.dart'; // DonationModel import
import 'package:uuid/uuid.dart'; // UUID for generated donations

final investmentRepositoryProvider = Provider((ref) {
  return InvestmentRepository(firestore: FirebaseFirestore.instance);
});

class InvestmentRepository {
  final FirebaseFirestore _firestore;

  InvestmentRepository({required FirebaseFirestore firestore}) : _firestore = firestore;

  // ✅ Create Investment with Share Calculation
  FutureEither<void> createInvestment(InvestmentModel investment) async {
    try {
      final communityRef = _firestore.collection('communities').doc(investment.communityId);
      final investmentRef = _firestore.collection('investments').doc(investment.id);

      // ১. সমস্ত ডোনেশন লোড করে স্টেকহোল্ডারদের শেয়ার বের করা
      final donationsSnapshot = await _firestore
          .collection('donations')
          .where('communityId', isEqualTo: investment.communityId)
          .get();

      // ইউজার অনুযায়ী মোট কন্ট্রিবিউশন ম্যাপ করা
      Map<String, double> userTotalDonations = {};
      double totalPool = 0.0;

      for (var doc in donationsSnapshot.docs) {
        final data = doc.data();
        final uid = data['senderId'];
        final amount = (data['amount'] ?? 0.0).toDouble();

        // এখানে নেগেটিভ এমাউন্টও (লস) হ্যান্ডেল হবে
        userTotalDonations[uid] = (userTotalDonations[uid] ?? 0.0) + amount;
        totalPool += amount;
      }

      // ২. ইনভেস্টমেন্টে কার কত টাকা যাবে তা ক্যালকুলেট করা
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

      // আপডেট করা মডেল (শেয়ার সহ)
      final investmentWithShares = InvestmentModel(
        id: investment.id,
        communityId: investment.communityId,
        projectName: investment.projectName,
        details: investment.details,
        investedAmount: investment.investedAmount,
        expectedProfit: investment.expectedProfit,
        status: investment.status,
        startDate: investment.startDate,
        userShares: calculatedUserShares, // ✅
      );

      // ৩. ট্রানজেকশন রান করা
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

  // ✅ Close Investment & Distribute Profit/Loss
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
        // ১. ইনভেস্টমেন্ট ডাটা রিড
        final investDoc = await transaction.get(investmentRef);
        if (!investDoc.exists) throw Exception("Investment not found");

        final investment = InvestmentModel.fromMap(investDoc.data()!);
        final userShares = investment.userShares;
        final totalInvested = investment.investedAmount;

        // ২. কমিউনিটি ফান্ড আপডেট
        final communityDoc = await transaction.get(communityRef);
        double currentFund = (communityDoc.data()?['totalFund'] ?? 0.0).toDouble();
        double newFund = currentFund + returnAmount;
        transaction.update(communityRef, {'totalFund': newFund});

        // ৩. স্টেকহোল্ডারদের লাভ/লস ডিস্ট্রিবিউশন (ডোনেশন রেকর্ড হিসেবে)
        // Batch Write ব্যবহার করা হচ্ছে না কারণ ট্রানজেকশনের ভেতরে লুপ চালানো হবে
        // Firestore Transaction এর ভেতরে লিমিট থাকে, তাই আলাদাভাবে batch commit করা ভালো
        // তবে এখানে কনসিস্টেন্সির জন্য ট্রানজেকশনের ভেতরেই রাখছি (ছোট স্কেলের জন্য)

        userShares.forEach((uid, investedShare) {
          if (totalInvested > 0) {
            double shareRatio = investedShare / totalInvested;
            double userProfitOrLoss = profitOrLoss * shareRatio;

            // Profit বা Loss এর জন্য রেকর্ড তৈরি
            final donationId = const Uuid().v1();
            final type = userProfitOrLoss >= 0 ? 'Profit Share' : 'Loss Adjustment';

            // UserModel নাম পাওয়ার জন্য আলাদা রিড দরকার, কিন্তু এখানে আমরা শুধু রেকর্ড তৈরি করছি
            // নামের জন্য "System" বা placeholder দেওয়া যেতে পারে, অথবা আলাদাভাবে ইউজার রিড করতে হবে।
            // পারফর্মেন্সের জন্য আমরা এখানে শুধু ID দিয়ে সেভ করছি, ডিসপ্লের সময় নাম আনা যাবে।

            final record = DonationModel(
              id: donationId,
              communityId: communityId,
              senderId: uid,
              senderName: "System Distribution", // UI তে হ্যান্ডেল করা হবে
              amount: double.parse(userProfitOrLoss.toStringAsFixed(2)),
              type: type,
              timestamp: DateTime.now(),
            );

            final donationRef = _firestore.collection('donations').doc(donationId);
            transaction.set(donationRef, record.toMap());
          }
        });

        // ৪. ইনভেস্টমেন্ট ক্লোজ
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