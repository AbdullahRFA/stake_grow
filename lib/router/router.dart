import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ✅ এই লাইনটা মিসিং ছিল
import 'package:go_router/go_router.dart';
import 'package:stake_grow/features/auth/presentation/auth_controller.dart';
import 'package:stake_grow/features/auth/presentation/screens/login_screen.dart';
import 'package:stake_grow/features/auth/presentation/screens/signup_screen.dart';
import 'package:stake_grow/features/community/presentation/screens/home_screen.dart';

import '../features/community/presentation/screens/create_community_screen.dart';

import 'package:stake_grow/features/community/domain/community_model.dart';
import 'package:stake_grow/features/community/presentation/screens/community_dashboard_screen.dart';

import '../features/donation/presentation/screens/create_donation_screen.dart';
import '../features/loan/presentation/screens/create_loan_screen.dart';


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
      GoRoute(
        path: '/create-community',
        builder: (context, state) => const CreateCommunityScreen(),
      ),
      GoRoute(
        path: '/community-dashboard',
        builder: (context, state) {
          // আমরা 'extra' প্যারামিটার দিয়ে পুরো কমিউনিটি অবজেক্ট পাস করছি
          final community = state.extra as CommunityModel;
          return CommunityDashboardScreen(community: community);
        },
      ),
      GoRoute(
        path: '/create-donation',
        builder: (context, state) {
          final communityId = state.extra as String;
          return CreateDonationScreen(communityId: communityId);
        },
      ),
      GoRoute(
        path: '/create-loan',
        builder: (context, state) {
          final communityId = state.extra as String;
          return CreateLoanScreen(communityId: communityId);
        },
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