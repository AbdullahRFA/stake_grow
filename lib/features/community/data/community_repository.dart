import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stake_grow/core/failure.dart';
import 'package:stake_grow/core/type_defs.dart';
import 'package:stake_grow/features/auth/domain/user_model.dart';
import 'package:stake_grow/features/community/domain/community_model.dart';
import 'package:stake_grow/features/community/domain/withdrawal_model.dart';
import 'package:stake_grow/features/donation/domain/donation_model.dart';
import 'package:uuid/uuid.dart';

final communityRepositoryProvider = Provider((ref) {
  return CommunityRepository(firestore: FirebaseFirestore.instance);
});

class CommunityRepository {
  final FirebaseFirestore _firestore;

  CommunityRepository({required FirebaseFirestore firestore}) : _firestore = firestore;

  // ---------------------------------------------------------
  // CORE COMMUNITY FEATURES
  // ---------------------------------------------------------

  FutureEither<void> createCommunity(CommunityModel community) async {
    try {
      var communityDoc = _firestore.collection('communities').doc(community.id);
      var userDoc = _firestore.collection('users').doc(community.adminId);

      await _firestore.runTransaction((transaction) async {
        transaction.set(communityDoc, community.toMap());
        transaction.update(userDoc, {
          'joinedCommunities': FieldValue.arrayUnion([community.id]),
        });
      });
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  // ✅ Restored: Get User Communities
  Stream<List<CommunityModel>> getUserCommunities(String uid) {
    return _firestore
        .collection('communities')
        .where('members', arrayContains: uid)
        .snapshots()
        .map((event) => event.docs.map((e) => CommunityModel.fromMap(e.data())).toList());
  }

  // ✅ Updated: Join Community (With Join Date)
  FutureEither<void> joinCommunity(String inviteCode, String userId) async {
    try {
      final querySnapshot = await _firestore.collection('communities').where('inviteCode', isEqualTo: inviteCode).get();
      if (querySnapshot.docs.isEmpty) return left(Failure('Invalid Invite Code!'));

      final communityDoc = querySnapshot.docs.first;
      final communityId = communityDoc.id;
      final members = List<String>.from(communityDoc.data()['members']);

      if (members.contains(userId)) return left(Failure('Already a member!'));

      await _firestore.runTransaction((transaction) async {
        transaction.update(communityDoc.reference, {
          'members': FieldValue.arrayUnion([userId]),
          'memberJoinDates.$userId': DateTime.now().millisecondsSinceEpoch, // ✅ Save Join Date
        });
        transaction.update(_firestore.collection('users').doc(userId), {
          'joinedCommunities': FieldValue.arrayUnion([communityId]),
        });
      });
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  FutureEither<void> leaveCommunity(String communityId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final commRef = _firestore.collection('communities').doc(communityId);
        final userRef = _firestore.collection('users').doc(userId);

        transaction.update(commRef, {
          'members': FieldValue.arrayRemove([userId]),
          'mods': FieldValue.arrayRemove([userId]),
          'monthlySubscriptions.$userId': FieldValue.delete(),
          'memberJoinDates.$userId': FieldValue.delete(),
        });

        transaction.update(userRef, {
          'joinedCommunities': FieldValue.arrayRemove([communityId]),
        });
      });
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  FutureEither<void> deleteCommunity(String communityId) async {
    try {
      await _firestore.collection('communities').doc(communityId).delete();
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  FutureEither<void> editCommunity(String communityId, String newName) async {
    try {
      await _firestore.collection('communities').doc(communityId).update({'name': newName});
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  FutureEither<void> toggleModRole(String communityId, String userId, bool shouldBeMod) async {
    try {
      await _firestore.collection('communities').doc(communityId).update({
        'mods': shouldBeMod ? FieldValue.arrayUnion([userId]) : FieldValue.arrayRemove([userId]),
      });
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  FutureEither<void> removeMember(String communityId, String memberId) async {
    return leaveCommunity(communityId, memberId); // Reusing logic
  }

  // ✅ Restored: Get Community Members
  Stream<List<UserModel>> getCommunityMembers(List<String> memberIds) {
    return _firestore.collection('users').snapshots().map((snapshot) {
      List<UserModel> members = [];
      for (var doc in snapshot.docs) {
        if (memberIds.contains(doc.id)) {
          members.add(UserModel.fromMap(doc.data()));
        }
      }
      return members;
    });
  }

  FutureEither<void> updateCommunityAdmin(String communityId, String newAdminId) async {
    try {
      await _firestore.collection('communities').doc(communityId).update({'adminId': newAdminId});
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  FutureEither<void> updateMonthlySubscription(String communityId, String userId, double amount) async {
    try {
      await _firestore.collection('communities').doc(communityId).update({
        'monthlySubscriptions.$userId': amount,
      });
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  // ---------------------------------------------------------
  // WITHDRAWAL FEATURES
  // ---------------------------------------------------------

  FutureEither<void> requestWithdrawal(WithdrawalModel withdrawal) async {
    try {
      await _firestore.collection('withdrawals').doc(withdrawal.id).set(withdrawal.toMap());
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Stream<List<WithdrawalModel>> getWithdrawals(String communityId) {
    return _firestore.collection('withdrawals')
        .where('communityId', isEqualTo: communityId)
        .orderBy('requestDate', descending: true)
        .snapshots()
        .map((event) => event.docs.map((e) => WithdrawalModel.fromMap(e.data())).toList());
  }

  FutureEither<void> approveWithdrawal(WithdrawalModel withdrawal) async {
    try {
      final communityRef = _firestore.collection('communities').doc(withdrawal.communityId);
      final withdrawalRef = _firestore.collection('withdrawals').doc(withdrawal.id);

      await _firestore.runTransaction((transaction) async {
        final communityDoc = await transaction.get(communityRef);
        double currentFund = (communityDoc.data()?['totalFund'] ?? 0.0).toDouble();

        if (currentFund < withdrawal.amount) {
          throw Exception("Insufficient community funds to approve this withdrawal.");
        }

        // 1. Deduct Fund
        transaction.update(communityRef, {'totalFund': currentFund - withdrawal.amount});

        // 2. Mark Approved
        transaction.update(withdrawalRef, {
          'status': 'approved',
          'approvedDate': DateTime.now().millisecondsSinceEpoch,
        });

        // 3. Create Negative Donation (Record keeping)
        final donationId = const Uuid().v1();
        final adjustment = DonationModel(
          id: donationId,
          communityId: withdrawal.communityId,
          senderId: withdrawal.userId,
          senderName: withdrawal.userName,
          amount: -withdrawal.amount,
          type: 'Withdrawal',
          timestamp: DateTime.now(),
          status: 'approved',
          paymentMethod: 'System',
        );

        transaction.set(_firestore.collection('donations').doc(donationId), adjustment.toMap());
      });

      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  FutureEither<void> rejectWithdrawal(String id) async {
    try {
      await _firestore.collection('withdrawals').doc(id).update({'status': 'rejected'});
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}