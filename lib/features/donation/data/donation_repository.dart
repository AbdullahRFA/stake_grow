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

  // 1. Make Deposit Request (No Fund Update yet)
  FutureEither<void> makeDonation(DonationModel donation) async {
    try {
      // Just save the document with 'pending' status
      await _firestore.collection('donations').doc(donation.id).set(donation.toMap());
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  // 2. Approve Deposit (Transaction: Update Fund + Change Status)
  FutureEither<void> approveDonation(DonationModel donation) async {
    try {
      final communityRef = _firestore.collection('communities').doc(donation.communityId);
      final donationRef = _firestore.collection('donations').doc(donation.id);

      await _firestore.runTransaction((transaction) async {
        // Read Community Fund
        final communityDoc = await transaction.get(communityRef);
        if (!communityDoc.exists) throw Exception("Community does not exist!");

        double currentFund = (communityDoc.data()?['totalFund'] ?? 0.0).toDouble();
        double newFund = currentFund + donation.amount;

        // Write: Update Fund
        transaction.update(communityRef, {'totalFund': newFund});

        // Write: Update Donation Status
        transaction.update(donationRef, {'status': 'approved'});
      });

      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  // 3. Reject Deposit (Change Status only)
  FutureEither<void> rejectDonation(String donationId, String reason) async {
    try {
      await _firestore.collection('donations').doc(donationId).update({
        'status': 'rejected',
        'rejectionReason': reason,
      });
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  // 4. Update Deposit (For User editing pending request)
  FutureEither<void> updateDonation(DonationModel donation) async {
    try {
      await _firestore.collection('donations').doc(donation.id).update(donation.toMap());
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  // 5. Delete Deposit (For User deleting pending request)
  FutureEither<void> deleteDonation(String donationId) async {
    try {
      await _firestore.collection('donations').doc(donationId).delete();
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Stream<List<DonationModel>> getDonations(String communityId) {
    return _firestore
        .collection('donations')
        .where('communityId', isEqualTo: communityId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((event) => event.docs
        .map((e) => DonationModel.fromMap(e.data()))
        .toList());
  }
}