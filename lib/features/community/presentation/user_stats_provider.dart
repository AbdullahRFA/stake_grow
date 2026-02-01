import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stake_grow/features/community/domain/community_model.dart';
import 'package:stake_grow/features/donation/data/donation_repository.dart';
import 'package:stake_grow/features/donation/domain/donation_model.dart';
import 'package:stake_grow/features/loan/data/loan_repository.dart';
import 'package:stake_grow/features/loan/domain/loan_model.dart';

// 1. Updated Stats Model
class UserStats {
  final double totalDonated;
  final double contributionPercentage;

  // Donation Stats
  final double monthlyDonated;
  final double randomDonated;
  final double monthlyPercent;
  final double randomPercent;
  final List<DonationModel> monthlyList;
  final List<DonationModel> randomList;

  // ✅ New Loan Stats (Categorized)
  final List<LoanModel> pendingLoans;
  final List<LoanModel> activeLoans; // Approved but not repaid
  final List<LoanModel> repaidLoans;
  final double activeLoanAmount; // Total money currently borrowed

  UserStats({
    required this.totalDonated,
    required this.contributionPercentage,
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
  });
}

// 2. Stats Provider
final userStatsProvider = StreamProvider.family<UserStats, CommunityModel>((ref, community) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    // Default Empty State
    return Stream.value(UserStats(
      totalDonated: 0,
      contributionPercentage: 0,
      monthlyDonated: 0,
      randomDonated: 0,
      monthlyPercent: 0,
      randomPercent: 0,
      monthlyList: [],
      randomList: [],
      pendingLoans: [],
      activeLoans: [],
      repaidLoans: [],
      activeLoanAmount: 0,
    ));
  }

  final donationRepo = ref.watch(donationRepositoryProvider);
  final loanRepo = ref.watch(loanRepositoryProvider);

  return donationRepo.getDonations(community.id).asyncMap((donations) async {
    // --- Donation Logic ---
    final myDonations = donations.where((d) => d.senderId == user.uid).toList();
    final monthlyList = myDonations.where((d) => d.type == 'Monthly').toList();
    final randomList = myDonations.where((d) => d.type == 'Random' || d.type == 'One-time').toList();

    double myTotal = myDonations.fold(0, (sum, item) => sum + item.amount);
    double monthlyTotal = monthlyList.fold(0, (sum, item) => sum + item.amount);
    double randomTotal = randomList.fold(0, (sum, item) => sum + item.amount);

    double monthlyPct = myTotal == 0 ? 0 : (monthlyTotal / myTotal) * 100;
    double randomPct = myTotal == 0 ? 0 : (randomTotal / myTotal) * 100;
    double commPercentage = community.totalFund == 0 ? 0 : (myTotal / community.totalFund) * 100;

    // --- ✅ Loan Logic (Updated) ---
    final loansStream = loanRepo.getCommunityLoans(community.id);
    final loans = await loansStream.first;
    final myLoans = loans.where((l) => l.borrowerId == user.uid).toList();

    // Categorize Loans
    final pending = myLoans.where((l) => l.status == 'pending').toList();
    final active = myLoans.where((l) => l.status == 'approved').toList();
    final repaid = myLoans.where((l) => l.status == 'repaid').toList();

    // Calculate Active Debt
    double activeDebt = active.fold(0, (sum, item) => sum + item.amount);

    return UserStats(
      totalDonated: myTotal,
      contributionPercentage: commPercentage,
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
    );
  });
});