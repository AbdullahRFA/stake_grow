import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ✅ এই লাইনটা মিসিং ছিল
import 'package:go_router/go_router.dart';
import 'package:stake_grow/features/auth/presentation/auth_controller.dart';
import 'package:stake_grow/features/auth/presentation/screens/login_screen.dart';
import 'package:stake_grow/features/auth/presentation/screens/signup_screen.dart';
import 'package:stake_grow/features/community/presentation/screens/home_screen.dart';

import '../features/activity/presentation/screens/create_activity_screen.dart';
import '../features/community/presentation/screens/activity_history_screen.dart';
import '../features/community/presentation/screens/create_community_screen.dart';

import 'package:stake_grow/features/community/domain/community_model.dart';
import 'package:stake_grow/features/community/presentation/screens/community_dashboard_screen.dart';

import '../features/community/presentation/screens/investment_history_screen.dart';
import '../features/community/presentation/screens/join_community_screen.dart';
import '../features/community/presentation/screens/transaction_history_screen.dart';
import '../features/community/presentation/screens/user_dashboard_screen.dart';
import '../features/donation/presentation/screens/create_donation_screen.dart';
import '../features/investment/presentation/screens/create_investment_screen.dart';
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
          // ✅ UPDATE: Handle Map Argument
          String communityId;
          bool isMonthlyDisabled = false;

          if (state.extra is Map<String, dynamic>) {
            final map = state.extra as Map<String, dynamic>;
            communityId = map['communityId'];
            isMonthlyDisabled = map['isMonthlyDisabled'] ?? false;
          } else {
            // Fallback for older calls
            communityId = state.extra as String;
          }

          return CreateDonationScreen(
            communityId: communityId,
            isMonthlyDisabled: isMonthlyDisabled, // ✅ Pass to screen
          );
        },
      ),
      GoRoute(
        path: '/create-loan',
        builder: (context, state) {
          final communityId = state.extra as String;
          return CreateLoanScreen(communityId: communityId);
        },
      ),
      GoRoute(
        path: '/create-investment',
        builder: (context, state) {
          final communityId = state.extra as String;
          return CreateInvestmentScreen(communityId: communityId);
        },
      ),
      GoRoute(
        path: '/create-activity',
        builder: (context, state) {
          final communityId = state.extra as String;
          return CreateActivityScreen(communityId: communityId);
        },
      ),
      GoRoute(
        path: '/transaction-history',
        builder: (context, state) {
          // ✅ UPDATE: স্ট্রিং বা ম্যাপ দুই ধরনের আর্গুমেন্ট হ্যান্ডেল করা
          String communityId;
          int initialIndex = 0;

          if (state.extra is Map<String, dynamic>) {
            final map = state.extra as Map<String, dynamic>;
            communityId = map['communityId'];
            initialIndex = map['initialIndex'] ?? 0;
          } else {
            // যদি পুরনো নিয়মে শুধু স্ট্রিং আসে
            communityId = state.extra as String;
          }

          return TransactionHistoryScreen(
            communityId: communityId,
            initialIndex: initialIndex,
          );
        },
      ),
      GoRoute(
        path: '/join-community',
        builder: (context, state) => const JoinCommunityScreen(),
      ),
      GoRoute(
        path: '/investment-history',
        builder: (context, state) {
          final communityId = state.extra as String;
          return InvestmentHistoryScreen(communityId: communityId);
        },
      ),
      GoRoute(
        path: '/activity-history',
        builder: (context, state) {
          final communityId = state.extra as String;
          return ActivityHistoryScreen(communityId: communityId);
        },
      ),
      // GoRoute(
      //   path: '/user-dashboard',
      //   builder: (context, state) {
      //     final community = state.extra as CommunityModel;
      //     return UserDashboardScreen(community: community);
      //   },
      // ),
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