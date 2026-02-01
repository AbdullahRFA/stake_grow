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

      // ১. অপটিমিস্টিক চেক (ট্রানজেকশনের আগে)
      final snapshot = await communityRef.get();
      if (!snapshot.exists) return left(Failure("Community not found"));

      double currentBalance = (snapshot.data()?['totalFund'] ?? 0.0).toDouble();

      if (currentBalance < activity.cost) {
        return left(Failure("Insufficient funds for this activity! Available: ৳$currentBalance"));
      }

      // ২. ACID Transaction
      await _firestore.runTransaction((transaction) async {
        final freshSnapshot = await transaction.get(communityRef);
        double freshBalance = (freshSnapshot.data()?['totalFund'] ?? 0.0).toDouble();

        if (freshBalance < activity.cost) {
          throw Exception("Insufficient funds!");
        }

        double newFund = freshBalance - activity.cost; // ফান্ড থেকে খরচ কমানো হলো

        transaction.update(communityRef, {'totalFund': newFund});
        transaction.set(activityRef, activity.toMap());
      });

      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
  // খরচের হিসাব দেখার স্ট্রিম
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