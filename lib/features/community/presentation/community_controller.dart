import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stake_grow/core/utils/utils.dart';
import 'package:stake_grow/features/auth/domain/user_model.dart';
import 'package:stake_grow/features/auth/presentation/auth_controller.dart';
import 'package:stake_grow/features/community/data/community_repository.dart';
import 'package:stake_grow/features/community/domain/community_model.dart';
import 'package:stake_grow/features/community/domain/withdrawal_model.dart';
import 'package:uuid/uuid.dart';

final userCommunitiesProvider = StreamProvider((ref) {
  final authState = ref.watch(authStateChangeProvider);
  return authState.when(
    data: (user) {
      if (user != null) {
        final repository = ref.watch(communityRepositoryProvider);
        return repository.getUserCommunities(user.uid);
      }
      return Stream.value([]);
    },
    error: (error, stackTrace) => Stream.value([]),
    loading: () => Stream.value([]),
  );
});

final communityControllerProvider = StateNotifierProvider<CommunityController, bool>((ref) {
  final communityRepository = ref.watch(communityRepositoryProvider);
  return CommunityController(communityRepository: communityRepository, ref: ref);
});

class CommunityController extends StateNotifier<bool> {
  final CommunityRepository _communityRepository;
  final Ref _ref;

  CommunityController({
    required CommunityRepository communityRepository,
    required Ref ref,
  })  : _communityRepository = communityRepository,
        _ref = ref,
        super(false);

  void createCommunity(String name, BuildContext context) async {
    state = true;
    final user = _ref.read(authStateChangeProvider).value;

    if (user != null) {
      final communityId = const Uuid().v1();

      CommunityModel community = CommunityModel(
        id: communityId,
        name: name,
        adminId: user.uid,
        mods: [],
        members: [user.uid],
        totalFund: 0.0,
        inviteCode: const Uuid().v4().substring(0, 6),
        createdAt: DateTime.now(),
        monthlySubscriptions: {},
        // ✅ FIX: Initialize Admin's Join Date
        memberJoinDates: {user.uid: DateTime.now().millisecondsSinceEpoch},
      );

      final res = await _communityRepository.createCommunity(community);
      state = false;

      res.fold(
            (l) => showSnackBar(context, l.message),
            (r) {
          showSnackBar(context, 'Community Created Successfully! 🚀');
          Navigator.pop(context);
        },
      );
    } else {
      state = false;
      showSnackBar(context, 'User not logged in!');
    }
  }

  void joinCommunity(String inviteCode, BuildContext context) async {
    state = true;
    final user = _ref.read(authStateChangeProvider).value;

    if (user != null) {
      final res = await _communityRepository.joinCommunity(inviteCode, user.uid);
      state = false;

      res.fold(
            (l) => showSnackBar(context, l.message),
            (r) {
          showSnackBar(context, 'Joined Community Successfully! 🎉');
          Navigator.pop(context);
        },
      );
    } else {
      state = false;
      showSnackBar(context, 'User not logged in!');
    }
  }

  Stream<List<UserModel>> getCommunityMembers(List<String> memberIds) {
    return _communityRepository.getCommunityMembers(memberIds);
  }

  void removeMember(String communityId, String memberId, BuildContext context) async {
    final res = await _communityRepository.removeMember(communityId, memberId);
    res.fold(
          (l) => showSnackBar(context, l.message),
          (r) => showSnackBar(context, 'Member removed successfully!'),
    );
  }

  void updateAdmin(String communityId, String newAdminId, BuildContext context) async {
    final res = await _communityRepository.updateCommunityAdmin(communityId, newAdminId);
    res.fold(
          (l) => showSnackBar(context, l.message),
          (r) {
        showSnackBar(context, 'Ownership transferred successfully!');
        Navigator.pop(context);
      },
    );
  }

  void leaveCommunity(String communityId, BuildContext context) async {
    final user = _ref.read(authStateChangeProvider).value;
    if (user == null) return;

    final res = await _communityRepository.leaveCommunity(communityId, user.uid);
    res.fold(
          (l) => showSnackBar(context, l.message),
          (r) {
        showSnackBar(context, 'You have left the community.');
        context.go('/');
      },
    );
  }

  void deleteCommunity(String communityId, BuildContext context) async {
    final res = await _communityRepository.deleteCommunity(communityId);
    res.fold(
          (l) => showSnackBar(context, l.message),
          (r) {
        showSnackBar(context, 'Community Deleted Successfully.');
        context.go('/');
      },
    );
  }

  void editCommunity(String communityId, String newName, BuildContext context) async {
    final res = await _communityRepository.editCommunity(communityId, newName);
    res.fold(
          (l) => showSnackBar(context, l.message),
          (r) {
        showSnackBar(context, 'Community Name Updated!');
        Navigator.pop(context);
      },
    );
  }

  void toggleModRole(String communityId, String userId, bool shouldBeMod, BuildContext context) async {
    final res = await _communityRepository.toggleModRole(communityId, userId, shouldBeMod);
    res.fold(
          (l) => showSnackBar(context, l.message),
          (r) => showSnackBar(context, shouldBeMod ? 'User Promoted to Admin' : 'User Demoted to Member'),
    );
  }

  void updateMonthlySubscription(String communityId, String userId, double amount, BuildContext context) async {
    final res = await _communityRepository.updateMonthlySubscription(communityId, userId, amount);
    res.fold(
          (l) => showSnackBar(context, l.message),
          (r) {
        showSnackBar(context, 'Monthly Subscription Fixed to ৳$amount');
        Navigator.pop(context);
      },
    );
  }

  void requestWithdrawal(WithdrawalModel withdrawal, BuildContext context) async {
    state = true;
    final res = await _communityRepository.requestWithdrawal(withdrawal);
    state = false;
    res.fold(
          (l) => showSnackBar(context, l.message),
          (r) {
        showSnackBar(context, 'Withdrawal Request Submitted Successfully!');
        Navigator.pop(context);
      },
    );
  }

  void approveWithdrawal(WithdrawalModel withdrawal, BuildContext context) async {
    final res = await _communityRepository.approveWithdrawal(withdrawal);
    res.fold(
          (l) => showSnackBar(context, l.message),
          (r) => showSnackBar(context, 'Withdrawal Approved & Funds Disbursed.'),
    );
  }

  void rejectWithdrawal(String id, BuildContext context) async {
    final res = await _communityRepository.rejectWithdrawal(id);
    res.fold(
          (l) => showSnackBar(context, l.message),
          (r) => showSnackBar(context, 'Withdrawal Request Rejected.'),
    );
  }
}