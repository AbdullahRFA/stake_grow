import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stake_grow/core/utils/utils.dart';
import 'package:stake_grow/features/auth/data/auth_repository.dart';
import 'package:stake_grow/features/auth/domain/user_model.dart';

// 1. User Provider: অ্যাপ চালু হলে চেক করবে ইউজার লগিন আছে কিনা
// এটি একটি Stream, মানে অথেনটিকেশন স্ট্যাটাস পাল্টালে এটিও পাল্টাবে
final authStateChangeProvider = StreamProvider((ref) {
  final authController = ref.watch(authControllerProvider.notifier);
  return authController.authStateChange;
});

// 2. Controller Provider: UI এই প্রভাইডারকে কল করবে
final authControllerProvider = StateNotifierProvider<AuthController, bool>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthController(authRepository: authRepository);
});

// 3. The Controller Class
// StateNotifier<bool> মানে হলো এই ক্লাসটি একটি Boolean স্টেট মেইনটেইন করে
// true = Loading (চাকা ঘুরছে), false = Idle (বসে আছে)
class AuthController extends StateNotifier<bool> {
  final AuthRepository _authRepository;

  AuthController({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(false); // শুরুতে লোডিং false

  // অ্যাপ রিস্টার্ট দিলে ইউজার চেক করার জন্য স্ট্রিম
  Stream<User?> get authStateChange => FirebaseAuth.instance.authStateChanges();

  // Sign Up Function
  void signUpWithEmail({
    required BuildContext context,
    required String email,
    required String password,
    required String name,
  }) async {
    // A. লোডিং শুরু
    state = true;

    // B. রিপোজিটরি কল
    final result = await _authRepository.signUpWithEmail(
        email: email,
        password: password,
        name: name
    );

    // C. লোডিং শেষ
    state = false;

    // D. রেজাল্ট হ্যান্ডলিং (fpdart magic)
    // result.fold(বাম, ডান) -> বামে এরর, ডানে সাকসেস
    result.fold(
          (failure) => showSnackBar(context, failure.message), // এরর হলে স্ন্যাকবার
          (userModel) {
        showSnackBar(context, 'Account created successfully! 🎉');
        // এখানে আমরা পরে নেভিগেশন যোগ করব (Home Page এ যাওয়ার জন্য)
      },
    );
  }

  // Login Function
  void loginWithEmail({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    state = true;
    final result = await _authRepository.loginWithEmail(
        email: email,
        password: password
    );
    state = false;

    result.fold(
          (failure) => showSnackBar(context, failure.message),
          (userModel) {
        showSnackBar(context, 'Welcome back, ${userModel.name}! 👋');
        // নেভিগেশন এখানে হবে
      },
    );
  }
  // ✅ প্রোফাইল আপডেট
  void updateProfile(UserModel user, BuildContext context) async {
    state = true;
    final res = await _authRepository.updateUserData(user);
    state = false;
    res.fold(
          (l) => showSnackBar(context, l.message),
          (r) {
        showSnackBar(context, 'Profile updated successfully!');
        Navigator.pop(context);
      },
    );
  }

  // ✅ গেট ইউজার ডাটা (Edit Profile পেজে ডাটা দেখানোর জন্য)
  Future<UserModel?> getUserData(String uid) {
    return _authRepository.getUserData(uid);
  }
}

