import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stake_grow/core/utils/utils.dart';
import 'package:stake_grow/features/auth/data/auth_repository.dart';
import 'package:stake_grow/features/donation/data/donation_repository.dart';
import 'package:stake_grow/features/donation/domain/donation_model.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';

final donationControllerProvider = StateNotifierProvider<DonationController, bool>((ref) {
  final donationRepo = ref.watch(donationRepositoryProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  return DonationController(donationRepository: donationRepo, authRepository: authRepo, ref: ref);
});

class DonationController extends StateNotifier<bool> {
  final DonationRepository _donationRepository;
  final AuthRepository _authRepository;
  final Ref _ref;

  DonationController({
    required DonationRepository donationRepository,
    required AuthRepository authRepository,
    required Ref ref,
  })  : _donationRepository = donationRepository,
        _authRepository = authRepository,
        _ref = ref,
        super(false);

  // Request Deposit
  void makeDonation({
    required String communityId,
    required double amount,
    required String type,
    required String paymentMethod,
    String? transactionId,
    String? phoneNumber,
    required BuildContext context,
  }) async {
    state = true;
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
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
        senderName: userName,
        amount: amount,
        type: type,
        timestamp: DateTime.now(),
        status: 'pending',
        paymentMethod: paymentMethod,
        transactionId: transactionId,
        phoneNumber: phoneNumber,
      );

      final res = await _donationRepository.makeDonation(donation);
      state = false;

      res.fold(
            (l) => showSnackBar(context, l.message),
            (r) {
          showSnackBar(context, 'Deposit Request Sent for Verification! ⏳');
          Navigator.pop(context);
        },
      );
    } else {
      state = false;
      showSnackBar(context, "User not logged in");
    }
  }

  // Approve
  void approveDonation(DonationModel donation, BuildContext context) async {
    state = true;
    final res = await _donationRepository.approveDonation(donation);
    state = false;
    res.fold(
          (l) => showSnackBar(context, l.message),
          (r) => showSnackBar(context, 'Deposit Approved & Added to Fund! ✅'),
    );
  }

  // Reject
  void rejectDonation(String donationId, String reason, BuildContext context) async {
    state = true;
    final res = await _donationRepository.rejectDonation(donationId, reason);
    state = false;
    res.fold(
          (l) => showSnackBar(context, l.message),
          (r) => showSnackBar(context, 'Deposit Rejected ❌'),
    );
  }

  // Update
  void updateDonation(DonationModel donation, BuildContext context) async {
    state = true;
    final res = await _donationRepository.updateDonation(donation);
    state = false;
    res.fold(
          (l) => showSnackBar(context, l.message),
          (r) {
        showSnackBar(context, 'Deposit Request Updated! ✅');
        Navigator.pop(context); // Close edit dialog
      },
    );
  }

  // Delete
  void deleteDonation(String donationId, BuildContext context) async {
    state = true;
    final res = await _donationRepository.deleteDonation(donationId);
    state = false;
    res.fold(
          (l) => showSnackBar(context, l.message),
          (r) => showSnackBar(context, 'Deposit Request Deleted! 🗑️'),
    );
  }
}