import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stake_grow/core/utils/utils.dart';
import 'package:stake_grow/features/auth/data/auth_repository.dart'; // Import Auth Repo
import 'package:stake_grow/features/donation/data/donation_repository.dart';
import 'package:stake_grow/features/donation/domain/donation_model.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';

final donationControllerProvider = StateNotifierProvider<DonationController, bool>((ref) {
  final donationRepo = ref.watch(donationRepositoryProvider);
  final authRepo = ref.watch(authRepositoryProvider); // ✅ Inject Auth Repo
  return DonationController(donationRepository: donationRepo, authRepository: authRepo, ref: ref);
});

class DonationController extends StateNotifier<bool> {
  final DonationRepository _donationRepository;
  final AuthRepository _authRepository; // ✅ Added
  final Ref _ref;

  DonationController({
    required DonationRepository donationRepository,
    required AuthRepository authRepository, // ✅ Added
    required Ref ref,
  })  : _donationRepository = donationRepository,
        _authRepository = authRepository,
        _ref = ref,
        super(false);

  void makeDonation({
    required String communityId,
    required double amount,
    required String type,
    required BuildContext context,
  }) async {
    state = true;
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // ✅ FIX: Fetch actual user name from Firestore to avoid "Member"
      // If Firestore read fails, fallback to Auth DisplayName, then 'Member'
      String userName = user.displayName ?? 'Member';

      final userModel = await _authRepository.getUserData(user.uid);
      if (userModel != null) {
        userName = userModel.name;
      }

      final donationId = const Uuid().v1();

      final donation = DonationModel(
        id: donationId,
        communityId: communityId,
        senderId: user.uid,
        senderName: userName, // ✅ Using fetched name
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
          Navigator.pop(context);
        },
      );
    } else {
      state = false;
      showSnackBar(context, "User not logged in");
    }
  }
}