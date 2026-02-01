import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stake_grow/core/failure.dart';
import 'package:stake_grow/core/type_defs.dart';
import 'package:stake_grow/features/community/domain/community_model.dart';

// Provider
final communityRepositoryProvider = Provider((ref) {
  return CommunityRepository(firestore: FirebaseFirestore.instance);
});

class CommunityRepository {
  final FirebaseFirestore _firestore;

  CommunityRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  // কমিউনিটি তৈরি করার ফাংশন
  FutureEither<void> createCommunity(CommunityModel community) async {
    try {
      // communities কালেকশন রেফারেন্স
      var communityDoc = _firestore.collection('communities').doc(community.id);

      // users কালেকশন রেফারেন্স (এডমিনের প্রোফাইল আপডেট করার জন্য)
      var userDoc = _firestore.collection('users').doc(community.adminId);

      // ACID Transaction: হয় দুটোই হবে, না হলে কিছুই হবে না
      await _firestore.runTransaction((transaction) async {
        // ১. কমিউনিটি ডকুমেন্ট তৈরি করো
        transaction.set(communityDoc, community.toMap());

        // ২. ইউজারের joinedCommunities লিস্টে এই কমিউনিটির আইডি যোগ করো
        // FieldValue.arrayUnion ব্যবহার করছি যাতে আগের ডাটা না মুছে যায়
        transaction.update(userDoc, {
          'joinedCommunities': FieldValue.arrayUnion([community.id]),
        });
      });

      return right(null); // সফল
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  // ইউজারের কমিউনিটিগুলো লোড করার ফাংশন (Stream)
  // এটি রিয়েল-টাইম আপডেট দিবে
  Stream<List<CommunityModel>> getUserCommunities(String uid) {
    return _firestore
        .collection('communities')
        .where('members', arrayContains: uid) // আমি মেম্বার আছি এমন সব কমিউনিটি দাও
        .snapshots()
        .map((event) {
      List<CommunityModel> communities = [];
      for (var doc in event.docs) {
        communities.add(CommunityModel.fromMap(doc.data()));
      }
      return communities;
    });
  }

// ✅ NEW: ইনভাইট কোড দিয়ে কমিউনিটিতে জয়েন করা
  FutureEither<void> joinCommunity(String inviteCode, String userId) async {
    try {
      // ১. ইনভাইট কোড দিয়ে কমিউনিটি খোঁজা
      final querySnapshot = await _firestore
          .collection('communities')
          .where('inviteCode', isEqualTo: inviteCode)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return left(Failure('Invalid Invite Code! Community not found.'));
      }

      final communityDoc = querySnapshot.docs.first;
      final communityId = communityDoc.id;
      final members = List<String>.from(communityDoc.data()['members']);

      // ২. ইউজার কি অলরেডি মেম্বার?
      if (members.contains(userId)) {
        return left(Failure('You are already a member of this community!'));
      }

      // ৩. ACID Transaction: মেম্বার লিস্ট আপডেট করা
      await _firestore.runTransaction((transaction) async {
        // কমিউনিটির মেম্বার লিস্টে ইউজারকে যোগ করো
        transaction.update(communityDoc.reference, {
          'members': FieldValue.arrayUnion([userId]),
        });

        // ইউজারের প্রোফাইলে কমিউনিটি আইডি যোগ করো
        transaction.update(_firestore.collection('users').doc(userId), {
          'joinedCommunities': FieldValue.arrayUnion([communityId]),
        });
      });

      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}