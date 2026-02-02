import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stake_grow/core/failure.dart';
import 'package:stake_grow/core/type_defs.dart';
import 'package:stake_grow/features/activity/domain/activity_model.dart';

final activityRepositoryProvider = Provider((ref) {
  return ActivityRepository(firestore: FirebaseFirestore.instance);
});

class ActivityRepository {
  final FirebaseFirestore _firestore;
  ActivityRepository({required FirebaseFirestore firestore}) : _firestore = firestore;

  FutureEither<void> createActivity(ActivityModel activity) async {
    try {
      final communityRef = _firestore.collection('communities').doc(activity.communityId);
      final activityRef = _firestore.collection('activities').doc(activity.id);

      // 1. Fetch Donation History to calculate shares
      final donationsSnapshot = await _firestore
          .collection('donations')
          .where('communityId', isEqualTo: activity.communityId)
          .get();

      Map<String, double> userTotalDonations = {};
      double totalPool = 0.0;

      for (var doc in donationsSnapshot.docs) {
        final data = doc.data();
        final uid = data['senderId'];
        final amount = (data['amount'] ?? 0.0).toDouble();
        userTotalDonations[uid] = (userTotalDonations[uid] ?? 0.0) + amount;
        totalPool += amount;
      }

      // 2. Calculate Expense Shares for each user
      Map<String, double> calculatedExpenseShares = {};
      if (totalPool > 0) {
        userTotalDonations.forEach((uid, totalDonated) {
          if (totalDonated > 0) {
            double sharePercentage = totalDonated / totalPool;
            double shareAmount = activity.cost * sharePercentage;
            // Round to 2 decimal places
            calculatedExpenseShares[uid] = double.parse(shareAmount.toStringAsFixed(2));
          }
        });
      }

      // 3. Create updated model with calculated shares
      final activityWithShares = ActivityModel(
        id: activity.id,
        communityId: activity.communityId,
        title: activity.title,
        details: activity.details,
        cost: activity.cost,
        date: activity.date,
        type: activity.type,
        expenseShares: calculatedExpenseShares, // ✅ Attached shares
      );

      // 4. Run Transaction (Deduct Fund & Save Activity)
      await _firestore.runTransaction((transaction) async {
        final communityDoc = await transaction.get(communityRef);
        if (!communityDoc.exists) throw Exception("Community not found");

        double currentFund = (communityDoc.data()?['totalFund'] ?? 0.0).toDouble();

        if (currentFund < activity.cost) {
          throw Exception("Insufficient funds! Available: ৳$currentFund");
        }

        double newFund = currentFund - activity.cost;

        transaction.update(communityRef, {'totalFund': newFund});
        transaction.set(activityRef, activityWithShares.toMap());
      });

      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Stream<List<ActivityModel>> getActivities(String communityId) {
    return _firestore
        .collection('activities')
        .where('communityId', isEqualTo: communityId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((event) => event.docs
        .map((e) => ActivityModel.fromMap(e.data()))
        .toList());
  }
}