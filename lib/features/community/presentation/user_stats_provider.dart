import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stake_grow/features/community/domain/community_model.dart';
import 'package:stake_grow/features/donation/data/donation_repository.dart';
import 'package:stake_grow/features/donation/domain/donation_model.dart';
import 'package:stake_grow/features/loan/data/loan_repository.dart';
import 'package:stake_grow/features/loan/domain/loan_model.dart';

// 1. Updated Stats Model (With Data Lists)
class UserStats {
  final double totalDonated;
  final double contributionPercentage;
  final String loanStatus;

  final double monthlyDonated;
  final double randomDonated;
  final double monthlyPercent;
  final double randomPercent;

  // ✅ New Lists for Detail View
  final List<DonationModel> monthlyList;
  final List<DonationModel> randomList;
  final List<LoanModel> loanHistory;

  UserStats({
    required this.totalDonated,
    required this.contributionPercentage,
    required this.loanStatus,
    required this.monthlyDonated,
    required this.randomDonated,
    required this.monthlyPercent,
    required this.randomPercent,
    required this.monthlyList,
    required this.randomList,
    required this.loanHistory,
  });
}

// 2. Stats Provider
final userStatsProvider = StreamProvider.family<UserStats, CommunityModel>((ref, community) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream.value(UserStats(
      totalDonated: 0,
      contributionPercentage: 0,
      loanStatus: 'N/A',
      monthlyDonated: 0,
      randomDonated: 0,
      monthlyPercent: 0,
      randomPercent: 0,
      monthlyList: [],
      randomList: [],
      loanHistory: [],
    ));
  }

  final donationRepo = ref.watch(donationRepositoryProvider);
  final loanRepo = ref.watch(loanRepositoryProvider);

  return donationRepo.getDonations(community.id).asyncMap((donations) async {
    // A. My Donations Filter
    final myDonations = donations.where((d) => d.senderId == user.uid).toList();

    // B. Breakdown Calculation
    final monthlyList = myDonations.where((d) => d.type == 'Monthly').toList();
    final randomList = myDonations.where((d) => d.type == 'Random' || d.type == 'One-time').toList();

    double myTotal = myDonations.fold(0, (sum, item) => sum + item.amount);
    double monthlyTotal = monthlyList.fold(0, (sum, item) => sum + item.amount);
    double randomTotal = randomList.fold(0, (sum, item) => sum + item.amount);

    double monthlyPct = myTotal == 0 ? 0 : (monthlyTotal / myTotal) * 100;
    double randomPct = myTotal == 0 ? 0 : (randomTotal / myTotal) * 100;

    double commPercentage = community.totalFund == 0
        ? 0
        : (myTotal / community.totalFund) * 100;

    // C. Loan Status & History
    final loansStream = loanRepo.getCommunityLoans(community.id);
    final loans = await loansStream.first;

    final myLoans = loans.where((l) => l.borrowerId == user.uid).toList();
    String loanStat = "No Active Loans";

    if (myLoans.isNotEmpty) {
      loanStat = myLoans.first.status.toUpperCase();
    }

    return UserStats(
      totalDonated: myTotal,
      contributionPercentage: commPercentage,
      loanStatus: loanStat,
      monthlyDonated: monthlyTotal,
      randomDonated: randomTotal,
      monthlyPercent: monthlyPct,
      randomPercent: randomPct,
      monthlyList: monthlyList,  // ✅ Pass Lists
      randomList: randomList,    // ✅ Pass Lists
      loanHistory: myLoans,      // ✅ Pass Lists
    );
  });
});