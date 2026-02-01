import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stake_grow/features/community/domain/community_model.dart';
import 'package:stake_grow/features/donation/data/donation_repository.dart';
import 'package:stake_grow/features/loan/data/loan_repository.dart';

// 1. Updated Stats Model
class UserStats {
  final double totalDonated;
  final double contributionPercentage; // (My Total / Community Total)
  final String loanStatus;

  // New Breakdown Fields
  final double monthlyDonated;
  final double randomDonated;
  final double monthlyPercent; // (Monthly / My Total)
  final double randomPercent;  // (Random / My Total)

  UserStats({
    required this.totalDonated,
    required this.contributionPercentage,
    required this.loanStatus,
    required this.monthlyDonated,
    required this.randomDonated,
    required this.monthlyPercent,
    required this.randomPercent,
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
    ));
  }

  final donationRepo = ref.watch(donationRepositoryProvider);
  final loanRepo = ref.watch(loanRepositoryProvider);

  return donationRepo.getDonations(community.id).asyncMap((donations) async {
    // A. My Donations Filter
    final myDonations = donations.where((d) => d.senderId == user.uid).toList();

    // B. Breakdown Calculation
    double myTotal = myDonations.fold(0, (sum, item) => sum + item.amount);

    double monthlyTotal = myDonations
        .where((d) => d.type == 'Monthly')
        .fold(0, (sum, item) => sum + item.amount);

    double randomTotal = myDonations
        .where((d) => d.type == 'Random') // অথবা 'One-time' যা আপনি ব্যবহার করেছেন
        .fold(0, (sum, item) => sum + item.amount);

    // Percentages of personal total
    double monthlyPct = myTotal == 0 ? 0 : (monthlyTotal / myTotal) * 100;
    double randomPct = myTotal == 0 ? 0 : (randomTotal / myTotal) * 100;

    // Contribution to Community Percentage
    double commPercentage = community.totalFund == 0
        ? 0
        : (myTotal / community.totalFund) * 100;

    // C. Loan Status (Latest Loan)
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
    );
  });
});