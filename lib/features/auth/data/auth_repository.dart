import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stake_grow/core/failure.dart';
import 'package:stake_grow/core/type_defs.dart';
import 'package:stake_grow/features/auth/domain/user_model.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository(
  auth: FirebaseAuth.instance,
  firestore: FirebaseFirestore.instance,
));

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

  // ✅ NEW METHODS
  FutureEither<void> forgotPassword(String email);
  FutureEither<void> changePassword({required String currentPassword, required String newPassword});
}

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
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(name);

        UserModel userModel = UserModel(
          uid: userCredential.user!.uid,
          email: email,
          name: name,
          createdAt: DateTime.now(),
          joinedCommunities: [],
        );

        await _firestore
            .collection('users')
            .doc(userModel.uid)
            .set(userModel.toMap());

        return right(userModel);
      } else {
        return left(Failure('User creation failed unexpectedly'));
      }
    } on FirebaseAuthException catch (e) {
      return left(Failure(e.message ?? 'Firebase Auth Error'));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  FutureEither<UserModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final doc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!doc.exists || doc.data() == null) {
          return left(Failure('User profile data not found! Please contact support.'));
        }

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

  FutureEither<void> updateUserData(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update(user.toMap());
      if (_auth.currentUser != null && user.name != _auth.currentUser!.displayName) {
        await _auth.currentUser!.updateDisplayName(user.name);
      }
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Future<UserModel?> getUserData(String uid) async {
    var doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  // ✅ Forgot Password Implementation
  @override
  FutureEither<void> forgotPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return right(null);
    } on FirebaseAuthException catch (e) {
      return left(Failure(e.message ?? 'Failed to send reset email'));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  // ✅ Change Password Implementation
  @override
  FutureEither<void> changePassword({required String currentPassword, required String newPassword}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return left(Failure('User not logged in'));

      final cred = EmailAuthProvider.credential(email: user.email!, password: currentPassword);

      // Re-authenticate user to ensure fresh credentials
      await user.reauthenticateWithCredential(cred);

      // Update Password
      await user.updatePassword(newPassword);

      return right(null);
    } on FirebaseAuthException catch (e) {
      return left(Failure(e.message ?? 'Failed to change password'));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}