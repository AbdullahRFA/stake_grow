import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stake_grow/core/failure.dart';
import 'package:stake_grow/core/type_defs.dart';
import 'package:stake_grow/features/auth/domain/user_model.dart'; // ✅ Use absolute import
import 'package:stake_grow/features/community/domain/community_model.dart';

final communityRepositoryProvider = Provider((ref) {
  return CommunityRepository(firestore: FirebaseFirestore.instance);
});

class CommunityRepository {
  final FirebaseFirestore _firestore;

  CommunityRepository({required FirebaseFirestore firestore}) : _firestore = firestore;

  // ✅ Create Community
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

  // ✅ Get User's Communities
  Stream<List<CommunityModel>> getUserCommunities(String uid) {
    return _firestore
        .collection('communities')
        .where('members', arrayContains: uid)
        .snapshots()
        .map((event) => event.docs.map((e) => CommunityModel.fromMap(e.data())).toList());
  }

  // ✅ Join Community
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

  // ✅ 1. LEAVE COMMUNITY
  FutureEither<void> leaveCommunity(String communityId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final commRef = _firestore.collection('communities').doc(communityId);
        final userRef = _firestore.collection('users').doc(userId);

        transaction.update(commRef, {
          'members': FieldValue.arrayRemove([userId]),
          'mods': FieldValue.arrayRemove([userId]), // Remove from mods if they leave
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

  // ✅ 2. DELETE COMMUNITY (Main Admin Only)
  FutureEither<void> deleteCommunity(String communityId) async {
    try {
      await _firestore.collection('communities').doc(communityId).delete();
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  // ✅ 3. EDIT COMMUNITY NAME (Main Admin Only)
  FutureEither<void> editCommunity(String communityId, String newName) async {
    try {
      await _firestore.collection('communities').doc(communityId).update({'name': newName});
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  // ✅ 4. TOGGLE ADMIN ROLE (Promote/Demote)
  // This handles your requirement:
  // - shouldBeMod = true: Assigns admin role
  // - shouldBeMod = false: Removes admin role (Demote)
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

  // ✅ 5. REMOVE MEMBER (Kick)
  FutureEither<void> removeMember(String communityId, String memberId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final commRef = _firestore.collection('communities').doc(communityId);
        final userRef = _firestore.collection('users').doc(memberId);

        transaction.update(commRef, {
          'members': FieldValue.arrayRemove([memberId]),
          'mods': FieldValue.arrayRemove([memberId]), // Ensure admin privileges are removed too
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

  // ✅ Get Community Members Details
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

  // ✅ Transfer Ownership (Main Admin)
  FutureEither<void> updateCommunityAdmin(String communityId, String newAdminId) async {
    try {
      await _firestore.collection('communities').doc(communityId).update({'adminId': newAdminId});
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}