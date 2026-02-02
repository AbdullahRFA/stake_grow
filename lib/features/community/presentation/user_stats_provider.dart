import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final double lockedInLoan; // ✅ NEW FIELD

  final double activeInvestmentProfitExpectation;

  final double monthlyDonated;
  final double randomDonated;
  final double monthlyPercent;
  final double randomPercent;
  final List<DonationModel> monthlyList;
  final List<DonationModel> randomList;

  final List<LoanModel> pendingLoans;
  final List<LoanModel> activeLoans;
  final List<LoanModel> repaidLoans;

  // এই লিস্টটি ড্যাশবোর্ডে দেখানোর জন্য যে কোন লোনগুলোতে আমার টাকা আছে
  final List<LoanModel> myFundedLoans; // ✅ NEW FIELD

  final double activeLoanAmount; // আমি যা লোন নিয়েছি
  final bool isCurrentMonthPaid;

  UserStats({
    required this.totalDonated,
    required this.totalLifetimeContributed,
    required this.contributionPercentage,
    required this.lockedInInvestment,
    required this.lockedInLoan, // ✅
    required this.activeInvestmentProfitExpectation,
    required this.monthlyDonated,
    required this.randomDonated,
    required this.monthlyPercent,
    required this.randomPercent,
    required this.monthlyList,
    required this.randomList,
    required this.pendingLoans,
    required this.activeLoans,
    required this.repaidLoans,
    required this.myFundedLoans, // ✅
    required this.activeLoanAmount,
    required this.isCurrentMonthPaid,
  });
}

final userStatsProvider = StreamProvider.family<UserStats, CommunityModel>((ref, community) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    // Return empty stats
    return Stream.value(UserStats(
      totalDonated: 0, totalLifetimeContributed: 0, contributionPercentage: 0,
      lockedInInvestment: 0, lockedInLoan: 0, activeInvestmentProfitExpectation: 0,
      monthlyDonated: 0, randomDonated: 0, monthlyPercent: 0, randomPercent: 0,
      monthlyList: [], randomList: [], pendingLoans: [], activeLoans: [], repaidLoans: [], myFundedLoans: [],
      activeLoanAmount: 0, isCurrentMonthPaid: false,
    ));
  }

  final donationRepo = ref.watch(donationRepositoryProvider);
  final loanRepo = ref.watch(loanRepositoryProvider);
  final investRepo = ref.watch(investmentRepositoryProvider);

  return donationRepo.getDonations(community.id).asyncMap((donations) async {
    final myDonations = donations.where((d) => d.senderId == user.uid).toList();
    double netContribution = myDonations.fold(0, (sum, item) => sum + item.amount);

    // --- Investments Calculation ---
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

    // --- Loans Calculation (Active Lending) ---
    final allLoans = await loanRepo.getCommunityLoans(community.id).first;

    // আমার নেওয়া লোন
    final myTakenLoans = allLoans.where((l) => l.borrowerId == user.uid).toList();
    final pending = myTakenLoans.where((l) => l.status == 'pending').toList();
    final activeTaken = myTakenLoans.where((l) => l.status == 'approved').toList();
    final repaid = myTakenLoans.where((l) => l.status == 'repaid').toList();
    double activeDebt = activeTaken.fold(0, (sum, item) => sum + item.amount);

    // ✅ আমি অন্যদের লোন দিয়েছি (Active Lending)
    double myLockedInLoan = 0.0;
    List<LoanModel> fundedLoans = [];

    // কমিউনিটির সব একটিভ লোন চেক করা
    final allActiveLoans = allLoans.where((l) => l.status == 'approved').toList();

    for (var loan in allActiveLoans) {
      if (loan.lenderShares.containsKey(user.uid)) {
        double share = loan.lenderShares[user.uid]!;
        myLockedInLoan += share;
        fundedLoans.add(loan);
      }
    }

    // ✅ Liquid Balance Calculation
    // Total - (Invested + Lent)
    double liquidBalance = netContribution - myLockedInInvestment - myLockedInLoan;

    // --- Others ---
    final monthlyList = myDonations.where((d) => d.type == 'Monthly').toList();
    final randomList = myDonations.where((d) => d.type == 'Random' || d.type == 'One-time').toList();
    final now = DateTime.now();
    bool isPaid = monthlyList.any((d) => d.timestamp.month == now.month && d.timestamp.year == now.year);
    double monthlyTotal = monthlyList.fold(0, (sum, item) => sum + item.amount);
    double randomTotal = randomList.fold(0, (sum, item) => sum + item.amount);
    double monthlyPct = netContribution == 0 ? 0 : (monthlyTotal / netContribution) * 100;
    double randomPct = netContribution == 0 ? 0 : (randomTotal / netContribution) * 100;

    // Community Total Asset (Liquid + Invested + Loaned Out)
    double totalActiveInvested = activeInvestments.fold(0, (sum, i) => sum + i.investedAmount);
    double totalActiveLoaned = allActiveLoans.fold(0, (sum, l) => sum + l.amount);
    double totalCommunityAssets = community.totalFund + totalActiveInvested + totalActiveLoaned;

    double commPercentage = totalCommunityAssets == 0 ? 0 : (netContribution / totalCommunityAssets) * 100;

    return UserStats(
      totalDonated: liquidBalance, // ✅ Updated Logic
      totalLifetimeContributed: netContribution,
      contributionPercentage: commPercentage,
      lockedInInvestment: myLockedInInvestment,
      lockedInLoan: myLockedInLoan, // ✅
      activeInvestmentProfitExpectation: expectedProfitShare,
      monthlyDonated: monthlyTotal,
      randomDonated: randomTotal,
      monthlyPercent: monthlyPct,
      randomPercent: randomPct,
      monthlyList: monthlyList,
      randomList: randomList,
      pendingLoans: pending,
      activeLoans: activeTaken,
      repaidLoans: repaid,
      myFundedLoans: fundedLoans, // ✅
      activeLoanAmount: activeDebt,
      isCurrentMonthPaid: isPaid,
    );
  });
});