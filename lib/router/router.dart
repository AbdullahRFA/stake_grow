import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ✅ এই লাইনটা মিসিং ছিল
import 'package:go_router/go_router.dart';
import 'package:stake_grow/features/auth/presentation/auth_controller.dart';
import 'package:stake_grow/features/auth/presentation/screens/login_screen.dart';
import 'package:stake_grow/features/auth/presentation/screens/signup_screen.dart';
import 'package:stake_grow/features/community/presentation/screens/home_screen.dart';

// গ্লোবাল নেভিগেটর কি (Key)
final navigatorKey = GlobalKey<NavigatorState>();

// রাউটার প্রভাইডার
final routerProvider = Provider<GoRouter>((ref) {
  // ১. অথেনটিকেশন স্টেট শোনা (লগিন নাকি লগআউট?)
  final authState = ref.watch(authStateChangeProvider);

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,

    // ২. রাউট লিস্ট
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
    ],

    // ৩. রিডাইরেক্ট লজিক
    redirect: (context, state) {
      if (authState.isLoading || authState.hasError) return null;

      final isAuthenticated = authState.value != null;
      final isLoggingIn = state.uri.toString() == '/login';
      final isSigningUp = state.uri.toString() == '/signup';

      // ক) ইউজার লগিন নেই, কিন্তু হোম পেজে যাওয়ার চেষ্টা করছে -> লগিনে পাঠাও
      if (!isAuthenticated && !isLoggingIn && !isSigningUp) {
        return '/login';
      }
      // খ) ইউজার লগিন আছে, কিন্তু আবার লগিন পেজে ঘুরছে -> হোমে পাঠাও
      if (isAuthenticated && (isLoggingIn || isSigningUp)) {
        return '/';
      }
// গ) অন্যথায়, যেখানে যেতে চায় সেখানেই যেতে দাও
      return null;
    },
  );
});