import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stake_grow/core/failure.dart';
import 'package:stake_grow/core/type_defs.dart';
import 'package:stake_grow/features/auth/domain/user_model.dart';

// 1. Provider: এটি দিয়ে আমরা পুরো অ্যাপে রিপোজিটরি এক্সেস করব
// Riverpod অটোমেটিক্যালি ডিপেন্ডেন্সি ইনজেকশন হ্যান্ডেল করবে
final authRepositoryProvider = Provider((ref) => AuthRepository(
  auth: FirebaseAuth.instance,
  firestore: FirebaseFirestore.instance,
));

// 2. Interface (চুক্তি): কী কী কাজ আমাদের করতে হবে
abstract class IAuthRepository {
  FutureEither<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  });

  FutureEither<UserModel> loginWithEmail({
    required String email,
    required String password,
  });

  Future<void> logOut();
}

// 3. Implementation (আসল কাজ)
class AuthRepository implements IAuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  @override
  FutureEither<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // A. ফায়ারবেস অথে ইউজার তৈরি করা
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      UserModel userModel;

      // B. যদি ইউজার তৈরি হয়, তার ডাটা মডেলে সাজানো
      if (userCredential.user != null) {
        userModel = UserModel(
          uid: userCredential.user!.uid,
          email: email,
          name: name,
          createdAt: DateTime.now(),
          joinedCommunities: [], // শুরুতে কোনো কমিউনিটি নেই
        );

        // C. ফায়ারস্টোর ডাটাবেসে ইউজারের তথ্য সেভ করা (users কালেকশনে)
        await _firestore
            .collection('users')
            .doc(userModel.uid)
            .set(userModel.toMap());

        // D. সফল হলে ডান দিকে (Right) ডাটা রিটার্ন করা
        return right(userModel);
      } else {
        return left(Failure('User creation failed unexpectedly'));
      }
    } on FirebaseAuthException catch (e) {
      // E. ফায়ারবেস স্পেসিফিক এরর হ্যান্ডলিং
      return left(Failure(e.message ?? 'Firebase Auth Error'));
    } catch (e) {
      // F. অন্যান্য এরর
      return left(Failure(e.toString()));
    }
  }

  @override
  FutureEither<UserModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // A. লগিন চেষ্টা
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // B. ডাটাবেস থেকে ডাটা আনা
        final doc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        // 🔴 FIX: চেক করা ডকুমেন্টটি আদৌ আছে কিনা
        if (!doc.exists || doc.data() == null) {
          return left(Failure('User profile data not found! Please contact support.'));
        }

        // C. ডাটা থাকলে কনভার্ট করা
        UserModel user = UserModel.fromMap(doc.data() as Map<String, dynamic>);
        return right(user);
      }
      return left(Failure('Login failed'));
    } on FirebaseAuthException catch (e) {
      return left(Failure(e.message ?? 'Login Error'));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<void> logOut() async {
    await _auth.signOut();
  }
}