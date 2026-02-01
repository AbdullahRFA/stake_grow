import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stake_grow/features/community/domain/community_model.dart';
import 'package:stake_grow/features/donation/data/donation_repository.dart';
import 'package:stake_grow/features/loan/data/loan_repository.dart';

// 1. Stats Model
class UserStats {
  final double totalDonated;
  final double contributionPercentage;
  final String loanStatus;
  final String subscriptionStatus;

  UserStats({
    required this.totalDonated,
    required this.contributionPercentage,
    required this.loanStatus,
    required this.subscriptionStatus,
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
      subscriptionStatus: 'N/A',
    ));
  }

  final donationRepo = ref.watch(donationRepositoryProvider);
  final loanRepo = ref.watch(loanRepositoryProvider);

  // দুটি স্ট্রিমকে কম্বাইন করা (RxDart এর মতো লজিক)
  return donationRepo.getDonations(community.id).asyncMap((donations) async {
    // A. Donation Calculation
    final myDonations = donations.where((d) => d.senderId == user.uid).toList();

    double myTotal = myDonations.fold(0, (sum, item) => sum + item.amount);

    double percentage = community.totalFund == 0
        ? 0
        : (myTotal / community.totalFund) * 100;

    // B. Subscription Status (Monthly Donation Check)
    final now = DateTime.now();
    bool isSubscribed = myDonations.any((d) =>
    d.type == 'Monthly' &&
        d.timestamp.month == now.month &&
        d.timestamp.year == now.year
    );
    String subStatus = isSubscribed ? "Paid for ${now.month}/${now.year}" : "Due for this month";

    // C. Loan Status (Latest Loan)
    // লোন স্ট্রিম আলাদা, তাই এখানে আমরা ফিউচার ব্যবহার করছি (Stream Combine জটিলতা এড়াতে)
    // ছোট অ্যাপের জন্য এটি গ্রহণযোগ্য। প্রোডাকশনে CombineLatestStream ব্যবহার করা ভালো।
    final loansStream = loanRepo.getCommunityLoans(community.id);
    final loans = await loansStream.first; // বর্তমান স্ন্যাপশট নেওয়া

    final myLoans = loans.where((l) => l.borrowerId == user.uid).toList();
    String loanStat = "No Active Loans";

    if (myLoans.isNotEmpty) {
      // লেটেস্ট লোন চেক
      loanStat = myLoans.first.status.toUpperCase();
    }

    return UserStats(
      totalDonated: myTotal,
      contributionPercentage: percentage,
      loanStatus: loanStat,
      subscriptionStatus: subStatus,
    );
  });
});