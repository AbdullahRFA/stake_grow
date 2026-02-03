import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stake_grow/features/activity/domain/activity_model.dart';
import 'package:stake_grow/features/community/domain/community_model.dart'; // Import CommunityModel
import 'package:stake_grow/features/community/presentation/transaction_providers.dart';
import 'package:stake_grow/features/donation/domain/donation_model.dart';
import 'package:stake_grow/features/investment/domain/investment_model.dart';
import 'package:stake_grow/features/loan/domain/loan_model.dart';
import 'package:stake_grow/features/loan/presentation/loan_controller.dart';

class UserStats {
  final double totalDonated; // Liquid Balance
  final double totalLifetimeContributed; // Gross Deposits
  final double contributionPercentage; // Ownership %

  final double lockedInInvestment;
  final double lockedInLoan;
  final double totalExpenseShare;

  final double activeInvestmentProfitExpectation;

  final double monthlyDonated;
  final double randomDonated;
  final double monthlyPercent;
  final double randomPercent;
  final List<DonationModel> monthlyList;
  final List<DonationModel> randomList;
  final List<DonationModel> allMyDeposits;

  final List<LoanModel> pendingLoans;
  final List<LoanModel> activeLoans;
  final List<LoanModel> repaidLoans;
  final List<LoanModel> myFundedLoans;
  final List<ActivityModel> myImpactActivities;

  final double activeLoanAmount;
  final bool isCurrentMonthPaid;

  UserStats({
    required this.totalDonated,
    required this.totalLifetimeContributed,
    required this.contributionPercentage,
    required this.lockedInInvestment,
    required this.lockedInLoan,
    required this.totalExpenseShare,
    required this.activeInvestmentProfitExpectation,
    required this.monthlyDonated,
    required this.randomDonated,
    required this.monthlyPercent,
    required this.randomPercent,
    required this.monthlyList,
    required this.randomList,
    required this.allMyDeposits,
    required this.pendingLoans,
    required this.activeLoans,
    required this.repaidLoans,
    required this.myFundedLoans,
    required this.myImpactActivities,
    required this.activeLoanAmount,
    required this.isCurrentMonthPaid,
  });
}

// ✅ FIX: Change argument to String (communityId) to watch stream internally
final userStatsProvider = Provider.family<AsyncValue<UserStats>, String>((ref, communityId) {
  final user = FirebaseAuth.instance.currentUser;

  // 1. WATCH ALL STREAMS (Including Community Details for Total Fund)
  final communityAsync = ref.watch(communityDetailsProvider(communityId));
  final donationsAsync = ref.watch(communityDonationsProvider(communityId));
  final loansAsync = ref.watch(communityLoansProvider(communityId));
  final investmentsAsync = ref.watch(communityInvestmentsProvider(communityId));
  final activitiesAsync = ref.watch(communityActivitiesProvider(communityId));

  // 2. Handle Loading
  if (communityAsync.isLoading || donationsAsync.isLoading || loansAsync.isLoading || investmentsAsync.isLoading || activitiesAsync.isLoading) {
    return const AsyncValue.loading();
  }

  // 3. Handle Errors
  if (communityAsync.hasError) return AsyncValue.error(communityAsync.error!, communityAsync.stackTrace!);

  // 4. Extract Data
  final community = communityAsync.value!;
  final donations = donationsAsync.value ?? [];
  final loans = loansAsync.value ?? [];
  final investments = investmentsAsync.value ?? [];
  final activities = activitiesAsync.value ?? [];

  if (user == null) {
    return AsyncValue.data(UserStats(
      totalDonated: 0, totalLifetimeContributed: 0, contributionPercentage: 0,
      lockedInInvestment: 0, lockedInLoan: 0, totalExpenseShare: 0, activeInvestmentProfitExpectation: 0,
      monthlyDonated: 0, randomDonated: 0, monthlyPercent: 0, randomPercent: 0,
      monthlyList: [], randomList: [], allMyDeposits: [], pendingLoans: [], activeLoans: [], repaidLoans: [], myFundedLoans: [], myImpactActivities: [],
      activeLoanAmount: 0, isCurrentMonthPaid: false,
    ));
  }

  // 5. Calculate Stats

  // --- Donations (Deposits) ---
  final allMyDeposits = donations.where((d) => d.senderId == user.uid).toList();
  // Only Approved deposits count towards balance
  final myApprovedDonations = allMyDeposits.where((d) => d.status == 'approved').toList();
  double netContribution = myApprovedDonations.fold(0, (sum, item) => sum + item.amount);

  // --- Investments ---
  final activeInvestments = investments.where((i) => i.status == 'active').toList();
  double myLockedInInvestment = 0.0;
  double expectedProfitShare = 0.0;
  for (var invest in activeInvestments) {
    if (invest.userShares.containsKey(user.uid)) {
      double share = invest.userShares[user.uid]!;
      myLockedInInvestment += share;
      double shareRatio = share / invest.investedAmount;
      expectedProfitShare += invest.expectedProfit * shareRatio;
    }
  }

  // --- Loans ---
  final myTakenLoans = loans.where((l) => l.borrowerId == user.uid).toList();
  final pending = myTakenLoans.where((l) => l.status == 'pending').toList();
  final activeTaken = myTakenLoans.where((l) => l.status == 'approved').toList();
  final repaid = myTakenLoans.where((l) => l.status == 'repaid').toList();
  double activeDebt = activeTaken.fold(0, (sum, item) => sum + item.amount);

  double myLockedInLoan = 0.0;
  List<LoanModel> fundedLoans = [];
  final allActiveLoans = loans.where((l) => l.status == 'approved').toList();
  for (var loan in allActiveLoans) {
    if (loan.lenderShares.containsKey(user.uid)) {
      myLockedInLoan += loan.lenderShares[user.uid]!;
      fundedLoans.add(loan);
    }
  }

  // --- Expenses (Activities) ---
  double myTotalExpenseShare = 0.0;
  List<ActivityModel> impactActivities = [];
  for (var activity in activities) {
    if (activity.expenseShares.containsKey(user.uid)) {
      double share = activity.expenseShares[user.uid]!;
      myTotalExpenseShare += share;
      impactActivities.add(activity);
    }
  }

  // --- Liquid Balance Calculation ---
  // Formula: Total Approved Deposits - (Investment Lock + Loan Lock + Expense Deduction)
  double liquidBalance = netContribution - myLockedInInvestment - myLockedInLoan - myTotalExpenseShare;

  // --- Breakdown ---
  final monthlyList = myApprovedDonations.where((d) => d.type == 'Monthly').toList();
  final randomList = myApprovedDonations.where((d) => d.type == 'Random' || d.type == 'One-time').toList();
  final now = DateTime.now();
  bool isPaid = monthlyList.any((d) => d.timestamp.month == now.month && d.timestamp.year == now.year);
  double monthlyTotal = monthlyList.fold(0, (sum, item) => sum + item.amount);
  double randomTotal = randomList.fold(0, (sum, item) => sum + item.amount);
  double monthlyPct = netContribution == 0 ? 0 : (monthlyTotal / netContribution) * 100;
  double randomPct = netContribution == 0 ? 0 : (randomTotal / netContribution) * 100;

  // --- Percentage Calculation (The Fix) ---

  // 1. Total Assets = Cash + Active Investments + Active Loans
  // (Total Fund in DB only holds Cash)
  double totalActiveInvested = activeInvestments.fold(0, (sum, i) => sum + i.investedAmount);
  double totalActiveLoaned = allActiveLoans.fold(0, (sum, l) => sum + l.amount);

  double totalCommunityAssets = community.totalFund + totalActiveInvested + totalActiveLoaned;

  // 2. My Remaining Equity = What I put in - What I spent on expenses
  // (We do NOT subtract locks here, because locks are still part of my equity, just not liquid)
  double myRemainingEquity = netContribution - myTotalExpenseShare;

  // print(liquidBalance);
  // print(myRemainingEquity);
  // print(totalCommunityAssets);
  // print(myLockedInInvestment);
  // print(myLockedInLoan);
  // print(myTotalExpenseShare);
  // print(expectedProfitShare);
  // print(netContribution);

  // 3. True Ownership Percentage
  double commPercentage = totalCommunityAssets == 0
      ? 0
      : (liquidBalance / community.totalFund) * 100;

  // print(commPercentage);

  return AsyncValue.data(UserStats(
    totalDonated: liquidBalance,
    totalLifetimeContributed: netContribution,
    contributionPercentage: commPercentage, // ✅ Now Correct
    lockedInInvestment: myLockedInInvestment,
    lockedInLoan: myLockedInLoan,
    totalExpenseShare: myTotalExpenseShare,
    activeInvestmentProfitExpectation: expectedProfitShare,
    monthlyDonated: monthlyTotal,
    randomDonated: randomTotal,
    monthlyPercent: monthlyPct,
    randomPercent: randomPct,
    monthlyList: monthlyList,
    randomList: randomList,
    allMyDeposits: allMyDeposits,
    pendingLoans: pending,
    activeLoans: activeTaken,
    repaidLoans: repaid,
    myFundedLoans: fundedLoans,
    myImpactActivities: impactActivities,
    activeLoanAmount: activeDebt,
    isCurrentMonthPaid: isPaid,
  ));

  print(activeDebt);
});

