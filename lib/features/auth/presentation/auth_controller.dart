import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stake_grow/core/utils/utils.dart';
import 'package:stake_grow/features/auth/data/auth_repository.dart';
import 'package:stake_grow/features/auth/domain/user_model.dart';

final authStateChangeProvider = StreamProvider((ref) {
  final authController = ref.watch(authControllerProvider.notifier);
  return authController.authStateChange;
});

final authControllerProvider = StateNotifierProvider<AuthController, bool>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthController(authRepository: authRepository);
});

class AuthController extends StateNotifier<bool> {
  final AuthRepository _authRepository;

  AuthController({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(false);

  Stream<User?> get authStateChange => FirebaseAuth.instance.authStateChanges();

  void signUpWithEmail({
    required BuildContext context,
    required String email,
    required String password,
    required String name,
  }) async {
    state = true;
    final result = await _authRepository.signUpWithEmail(
        email: email,
        password: password,
        name: name
    );
    state = false;
    result.fold(
          (failure) => showSnackBar(context, failure.message),
          (userModel) {
        showSnackBar(context, 'Account created successfully! 🎉');
      },
    );
  }

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
      },
    );
  }

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

  Future<UserModel?> getUserData(String uid) {
    return _authRepository.getUserData(uid);
  }

  // ✅ Forgot Password Logic
  void forgotPassword(String email, BuildContext context) async {
    state = true;
    final res = await _authRepository.forgotPassword(email);
    state = false;
    res.fold(
          (l) => showSnackBar(context, l.message),
          (r) => showSnackBar(context, 'Password reset link sent to your email! 📧'),
    );
  }

  // ✅ Change Password Logic
  void changePassword(String currentPassword, String newPassword, BuildContext context) async {
    state = true;
    final res = await _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword
    );
    state = false;
    res.fold(
          (l) => showSnackBar(context, l.message),
          (r) {
        showSnackBar(context, 'Password changed successfully! 🔒');
        Navigator.pop(context); // Close the dialog
      },
    );
  }
}