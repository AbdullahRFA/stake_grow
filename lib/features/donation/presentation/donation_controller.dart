import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stake_grow/core/utils/utils.dart';
import 'package:stake_grow/features/auth/presentation/auth_controller.dart';
import 'package:stake_grow/features/donation/data/donation_repository.dart';
import 'package:stake_grow/features/donation/domain/donation_model.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';

final donationControllerProvider = StateNotifierProvider<DonationController, bool>((ref) {
  final donationRepo = ref.watch(donationRepositoryProvider);
  return DonationController(donationRepository: donationRepo, ref: ref);
});

class DonationController extends StateNotifier<bool> {
  final DonationRepository _donationRepository;
  final Ref _ref;

  DonationController({required DonationRepository donationRepository, required Ref ref})
      : _donationRepository = donationRepository,
        _ref = ref,
        super(false);

  void makeDonation({
    required String communityId,
    required double amount,
    required String type,
    required BuildContext context,
  }) async {
    state = true;
    // final user = _ref.read(authStateChangeProvider).value;
    // ✅ UPDATE: সরাসরি Firebase Auth থেকে ইউজার নিচ্ছি (Safe way)
    final user = FirebaseAuth.instance.currentUser;

    print("User found: ${user?.uid}"); // ডিবাগ প্রিন্ট

    if (user != null) {
      final donationId = const Uuid().v1();

      final donation = DonationModel(
        id: donationId,
        communityId: communityId,
        senderId: user.uid,
        senderName: user.displayName ?? 'Member', // Firebase Auth নাম
        amount: amount,
        type: type,
        timestamp: DateTime.now(),
      );

      final res = await _donationRepository.makeDonation(donation);
      state = false;

      res.fold(
            (l) => showSnackBar(context, l.message),
            (r) {
          showSnackBar(context, 'Donation Successful! 🎉');
          Navigator.pop(context); // পেজ বন্ধ করে ড্যাশবোর্ডে ফিরে যাওয়া
        },
      );
    } else {
      state = false;
      showSnackBar(context, "User not logged in");
    }
  }
}