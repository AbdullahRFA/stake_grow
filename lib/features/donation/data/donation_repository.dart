import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stake_grow/core/failure.dart';
import 'package:stake_grow/core/type_defs.dart';
import 'package:stake_grow/features/donation/domain/donation_model.dart';

final donationRepositoryProvider = Provider((ref) {
  return DonationRepository(firestore: FirebaseFirestore.instance);
});

class DonationRepository {
  final FirebaseFirestore _firestore;
  DonationRepository({required FirebaseFirestore firestore}) : _firestore = firestore;

  // ⚡ ACID Transaction: Donation + Fund Update
  FutureEither<void> makeDonation(DonationModel donation) async {
    try {
      final communityRef = _firestore.collection('communities').doc(donation.communityId);
      final donationRef = _firestore.collection('donations').doc(donation.id);

      await _firestore.runTransaction((transaction) async {
        // ১. Read: কমিউনিটির বর্তমান ফান্ড চেক করা (Consistency)
        final communityDoc = await transaction.get(communityRef);
        if (!communityDoc.exists) {
          throw Exception("Community does not exist!");
        }

        // ২. Write: নতুন ফান্ড ক্যালকুলেট করে আপডেট করা (Atomicity)
        double currentFund = (communityDoc.data()?['totalFund'] ?? 0.0).toDouble();
        double newFund = currentFund + donation.amount;

        transaction.update(communityRef, {'totalFund': newFund});

        // ৩. Write: ডোনেশন রেকর্ড সেভ করা
        transaction.set(donationRef, donation.toMap());
      });

      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}