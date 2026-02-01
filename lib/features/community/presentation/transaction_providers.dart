import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stake_grow/features/activity/data/activity_repository.dart';
import 'package:stake_grow/features/donation/data/donation_repository.dart';
import 'package:stake_grow/features/investment/data/investment_repository.dart';

// 1. Donation Stream
final communityDonationsProvider = StreamProvider.family((ref, String id) {
  return ref.watch(donationRepositoryProvider).getDonations(id);
});

// 2. Investment Stream
final communityInvestmentsProvider = StreamProvider.family((ref, String id) {
  return ref.watch(investmentRepositoryProvider).getInvestments(id);
});

// 3. Activity Stream
final communityActivitiesProvider = StreamProvider.family((ref, String id) {
  return ref.watch(activityRepositoryProvider).getActivities(id);
});