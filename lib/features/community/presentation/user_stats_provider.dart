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
  final double totalDonated; // এটা এখন Liquid Balance বোঝাবে
  final double totalLifetimeContributed; // মোট কত দিয়েছে (লকড সহ)
  final double contributionPercentage;

  // Investment Stats
  final double lockedInInvestment; // ইনভেস্ট করা টাকা
  final double activeInvestmentProfitExpectation; // প্রত্যাশিত লাভ (অপশনাল)

  final double monthlyDonated;
  final double randomDonated;
  final double monthlyPercent;
  final double randomPercent;
  final List<DonationModel> monthlyList;
  final List<DonationModel> randomList;

  final List<LoanModel> pendingLoans;
  final List<LoanModel> activeLoans;
  final List<LoanModel> repaidLoans;
  final double activeLoanAmount;
  final bool isCurrentMonthPaid;

  UserStats({
    required this.totalDonated,
    required this.totalLifetimeContributed,
    required this.contributionPercentage,
    required this.lockedInInvestment,
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
    required this.activeLoanAmount,
    required this.isCurrentMonthPaid,
  });
}

final userStatsProvider = StreamProvider.family<UserStats, CommunityModel>((ref, community) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream.value(UserStats(
      totalDonated: 0, totalLifetimeContributed: 0, contributionPercentage: 0,
      lockedInInvestment: 0, activeInvestmentProfitExpectation: 0,
      monthlyDonated: 0, randomDonated: 0, monthlyPercent: 0, randomPercent: 0,
      monthlyList: [], randomList: [], pendingLoans: [], activeLoans: [], repaidLoans: [],
      activeLoanAmount: 0, isCurrentMonthPaid: false,
    ));
  }

  final donationRepo = ref.watch(donationRepositoryProvider);
  final loanRepo = ref.watch(loanRepositoryProvider);
  final investRepo = ref.watch(investmentRepositoryProvider);

  return donationRepo.getDonations(community.id).asyncMap((donations) async {
    final myDonations = donations.where((d) => d.senderId == user.uid).toList();

    // 1. Calculate Total Net Contribution (Donations + Profit - Loss)
    double netContribution = myDonations.fold(0, (sum, item) => sum + item.amount);

    // 2. Fetch Active Investments to calculate Locked Amount
    final investments = await investRepo.getInvestments(community.id).first;
    final activeInvestments = investments.where((i) => i.status == 'active').toList();

    double myLockedAmount = 0.0;
    double expectedProfitShare = 0.0;

    for (var invest in activeInvestments) {
      if (invest.userShares.containsKey(user.uid)) {
        double share = invest.userShares[user.uid]!;
        myLockedAmount += share;

        // Expected profit calc
        double shareRatio = share / invest.investedAmount;
        expectedProfitShare += invest.expectedProfit * shareRatio;
      }
    }

    // 3. Liquid Balance (Total - Locked)
    double liquidBalance = netContribution - myLockedAmount;

    // --- Others ---
    final monthlyList = myDonations.where((d) => d.type == 'Monthly').toList();
    final randomList = myDonations.where((d) => d.type == 'Random' || d.type == 'One-time').toList();

    final now = DateTime.now();
    bool isPaid = monthlyList.any((d) => d.timestamp.month == now.month && d.timestamp.year == now.year);

    double monthlyTotal = monthlyList.fold(0, (sum, item) => sum + item.amount);
    double randomTotal = randomList.fold(0, (sum, item) => sum + item.amount);

    double monthlyPct = netContribution == 0 ? 0 : (monthlyTotal / netContribution) * 100;
    double randomPct = netContribution == 0 ? 0 : (randomTotal / netContribution) * 100;

    // Community Total Asset (Liquid + Invested) - for Percentage Calculation
    // community.totalFund is Liquid. Need to add Total Active Investments.
    double totalActiveInvested = activeInvestments.fold(0, (sum, i) => sum + i.investedAmount);
    double totalCommunityAssets = community.totalFund + totalActiveInvested;

    double commPercentage = totalCommunityAssets == 0 ? 0 : (netContribution / totalCommunityAssets) * 100;

    // --- Loans ---
    final loans = await loanRepo.getCommunityLoans(community.id).first;
    final myLoans = loans.where((l) => l.borrowerId == user.uid).toList();
    final pending = myLoans.where((l) => l.status == 'pending').toList();
    final active = myLoans.where((l) => l.status == 'approved').toList();
    final repaid = myLoans.where((l) => l.status == 'repaid').toList();
    double activeDebt = active.fold(0, (sum, item) => sum + item.amount);

    return UserStats(
      totalDonated: liquidBalance, // User sees this decreased when invested
      totalLifetimeContributed: netContribution, // Total ownership
      contributionPercentage: commPercentage,
      lockedInInvestment: myLockedAmount, // New Field
      activeInvestmentProfitExpectation: expectedProfitShare,
      monthlyDonated: monthlyTotal,
      randomDonated: randomTotal,
      monthlyPercent: monthlyPct,
      randomPercent: randomPct,
      monthlyList: monthlyList,
      randomList: randomList,
      pendingLoans: pending,
      activeLoans: active,
      repaidLoans: repaid,
      activeLoanAmount: activeDebt,
      isCurrentMonthPaid: isPaid,
    );
  });
});