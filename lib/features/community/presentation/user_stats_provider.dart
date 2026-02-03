import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stake_grow/features/activity/data/activity_repository.dart';
import 'package:stake_grow/features/activity/domain/activity_model.dart';
import 'package:stake_grow/features/community/domain/community_model.dart';
import 'package:stake_grow/features/donation/data/donation_repository.dart';
import 'package:stake_grow/features/donation/domain/donation_model.dart';
import 'package:stake_grow/features/investment/data/investment_repository.dart';
import 'package:stake_grow/features/investment/domain/investment_model.dart';
import 'package:stake_grow/features/loan/data/loan_repository.dart';
import 'package:stake_grow/features/loan/domain/loan_model.dart';

class UserStats {
  final double totalDonated; // Liquid Balance
  final double totalLifetimeContributed;
  final double contributionPercentage;

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

  // ✅ NEW: List of all my deposit requests (pending/approved/rejected) for UI
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
    required this.allMyDeposits, // ✅
    required this.pendingLoans,
    required this.activeLoans,
    required this.repaidLoans,
    required this.myFundedLoans,
    required this.myImpactActivities,
    required this.activeLoanAmount,
    required this.isCurrentMonthPaid,
  });
}

final userStatsProvider = StreamProvider.family<UserStats, CommunityModel>((ref, community) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream.value(UserStats(
      totalDonated: 0, totalLifetimeContributed: 0, contributionPercentage: 0,
      lockedInInvestment: 0, lockedInLoan: 0, totalExpenseShare: 0, activeInvestmentProfitExpectation: 0,
      monthlyDonated: 0, randomDonated: 0, monthlyPercent: 0, randomPercent: 0,
      monthlyList: [], randomList: [], allMyDeposits: [], pendingLoans: [], activeLoans: [], repaidLoans: [], myFundedLoans: [], myImpactActivities: [],
      activeLoanAmount: 0, isCurrentMonthPaid: false,
    ));
  }

  final donationRepo = ref.watch(donationRepositoryProvider);
  final loanRepo = ref.watch(loanRepositoryProvider);
  final investRepo = ref.watch(investmentRepositoryProvider);
  final activityRepo = ref.watch(activityRepositoryProvider);

  return donationRepo.getDonations(community.id).asyncMap((donations) async {
    // 1. Filter ALL my deposits for history
    final allMyDeposits = donations.where((d) => d.senderId == user.uid).toList();

    // 2. Filter APPROVED deposits for calculations
    final myApprovedDonations = allMyDeposits.where((d) => d.status == 'approved').toList();

    // ✅ Calculate Net Contribution based on APPROVED only
    double netContribution = myApprovedDonations.fold(0, (sum, item) => sum + item.amount);

    // --- Investments ---
    final investments = await investRepo.getInvestments(community.id).first;
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
    final allLoans = await loanRepo.getCommunityLoans(community.id).first;
    final myTakenLoans = allLoans.where((l) => l.borrowerId == user.uid).toList();
    final pending = myTakenLoans.where((l) => l.status == 'pending').toList();
    final activeTaken = myTakenLoans.where((l) => l.status == 'approved').toList();
    final repaid = myTakenLoans.where((l) => l.status == 'repaid').toList();
    double activeDebt = activeTaken.fold(0, (sum, item) => sum + item.amount);

    double myLockedInLoan = 0.0;
    List<LoanModel> fundedLoans = [];
    final allActiveLoans = allLoans.where((l) => l.status == 'approved').toList();
    for (var loan in allActiveLoans) {
      if (loan.lenderShares.containsKey(user.uid)) {
        myLockedInLoan += loan.lenderShares[user.uid]!;
        fundedLoans.add(loan);
      }
    }

    // --- Expenses ---
    final allActivities = await activityRepo.getActivities(community.id).first;
    double myTotalExpenseShare = 0.0;
    List<ActivityModel> impactActivities = [];

    for (var activity in allActivities) {
      if (activity.expenseShares.containsKey(user.uid)) {
        double share = activity.expenseShares[user.uid]!;
        myTotalExpenseShare += share;
        impactActivities.add(activity);
      }
    }

    // Liquid Balance Calculation
    double liquidBalance = netContribution - myLockedInInvestment - myLockedInLoan - myTotalExpenseShare;

    // --- Others (Using Approved List) ---
    final monthlyList = myApprovedDonations.where((d) => d.type == 'Monthly').toList();
    final randomList = myApprovedDonations.where((d) => d.type == 'Random' || d.type == 'One-time').toList();
    final now = DateTime.now();
    bool isPaid = monthlyList.any((d) => d.timestamp.month == now.month && d.timestamp.year == now.year);
    double monthlyTotal = monthlyList.fold(0, (sum, item) => sum + item.amount);
    double randomTotal = randomList.fold(0, (sum, item) => sum + item.amount);
    double monthlyPct = netContribution == 0 ? 0 : (monthlyTotal / netContribution) * 100;
    double randomPct = netContribution == 0 ? 0 : (randomTotal / netContribution) * 100;

    double totalActiveInvested = activeInvestments.fold(0, (sum, i) => sum + i.investedAmount);
    double totalActiveLoaned = allActiveLoans.fold(0, (sum, l) => sum + l.amount);

    double totalCommunityAssets = community.totalFund + totalActiveInvested + totalActiveLoaned;
    double myRemainingEquity = netContribution - myTotalExpenseShare;
    double commPercentage = totalCommunityAssets == 0 ? 0 : (myRemainingEquity / totalCommunityAssets) * 100;

    return UserStats(
      totalDonated: liquidBalance,
      totalLifetimeContributed: netContribution,
      contributionPercentage: commPercentage,
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
      allMyDeposits: allMyDeposits, // ✅ Passing raw list including pending
      pendingLoans: pending,
      activeLoans: activeTaken,
      repaidLoans: repaid,
      myFundedLoans: fundedLoans,
      myImpactActivities: impactActivities,
      activeLoanAmount: activeDebt,
      isCurrentMonthPaid: isPaid,
    );
  });
});