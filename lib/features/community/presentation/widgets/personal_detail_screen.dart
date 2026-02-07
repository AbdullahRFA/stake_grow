import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stake_grow/features/community/domain/community_model.dart';
import 'package:stake_grow/features/community/presentation/user_stats_provider.dart';
import 'package:stake_grow/features/loan/domain/loan_model.dart';
import '../screens/community_dashboard_screen.dart';

class PersonalDetailScreen extends ConsumerWidget {
  final String type;
  final CommunityModel community;
  final UserStats stats;
  final List<LoanModel> allLoans;
  final List<LoanModel> myLoans;

  const PersonalDetailScreen({
    super.key,
    required this.type,
    required this.community,
    required this.stats,
    required this.allLoans,
    required this.myLoans,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = CommunityDashboardScreen(community: community);

    return Scaffold(
      appBar: AppBar(
        title: Text(type),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: _buildSelectedCard(context, ref, dashboard),
      ),
    );
  }

  Widget _buildSelectedCard(BuildContext context, WidgetRef ref, CommunityDashboardScreen dashboard) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    switch (type) {
      case "Donation Breakdown":
        return dashboard.buildSubscriptionCard(context, stats);
      case "Portfolio & Activities":
        return dashboard.buildInvestmentCard(context, stats, community);
      case "Money Locked in Loans":
        return dashboard.buildActiveLendingCard(context, stats, allLoans, uid);
      case "My Expense Contribution":
        return dashboard.buildExpenseImpactCard(context, stats, community.id);
      case "My Loans":
        return dashboard.buildLoanSummaryCard(context, myLoans, ref, isMyLoan: true);
      case "Community Loans":
        return dashboard.buildLoanSummaryCard(context, allLoans, ref, isMyLoan: false);
      default:
        return const Center(child: Text("Data not found"));
    }
  }
}