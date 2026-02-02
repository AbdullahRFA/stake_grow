import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stake_grow/core/utils/utils.dart';
import 'package:stake_grow/features/auth/domain/user_model.dart'; // ✅ Added Import
import 'package:stake_grow/features/auth/presentation/auth_controller.dart';
import 'package:stake_grow/features/community/data/community_repository.dart';
import 'package:stake_grow/features/community/domain/community_model.dart';
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
        members: [user.uid],
        totalFund: 0.0,
        inviteCode: const Uuid().v4().substring(0, 6),
        createdAt: DateTime.now(),
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

  // ✅ মেথডগুলো এখন ক্লাসের ভেতরে নিয়ে আসা হয়েছে

  // ১. মেম্বারদের তথ্য লোড করা (Stream)
  Stream<List<UserModel>> getCommunityMembers(List<String> memberIds) {
    return _communityRepository.getCommunityMembers(memberIds);
  }

  // ২. মেম্বার রিমুভ করা
  void removeMember(String communityId, String memberId, BuildContext context) async {
    final res = await _communityRepository.removeMember(communityId, memberId);
    res.fold(
          (l) => showSnackBar(context, l.message),
          (r) => showSnackBar(context, 'Member removed successfully!'),
    );
  }

  // ৩. এডমিন পরিবর্তন করা
  void updateAdmin(String communityId, String newAdminId, BuildContext context) async {
    final res = await _communityRepository.updateCommunityAdmin(communityId, newAdminId);
    res.fold(
          (l) => showSnackBar(context, l.message),
          (r) {
        showSnackBar(context, 'Ownership transferred successfully!');
        Navigator.pop(context); // ডায়ালগ বন্ধ
      },
    );
  }
}