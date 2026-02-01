import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stake_grow/core/utils/utils.dart';
import 'package:stake_grow/features/auth/presentation/auth_controller.dart';
import 'package:stake_grow/features/community/data/community_repository.dart';
import 'package:stake_grow/features/community/domain/community_model.dart';
import 'package:uuid/uuid.dart';

// ✅ UPDATE: এই প্রভাইডারটি এখন স্মার্টলি কাজ করবে
final userCommunitiesProvider = StreamProvider((ref) {
  // ১. অথেনটিকেশন স্টেটের দিকে নজর রাখা (Watch)
  final authState = ref.watch(authStateChangeProvider);

  // ২. যদি ইউজার লগিন থাকে, তবেই ডাটা আনো
  return authState.when(
    data: (user) {
      if (user != null) {
        final repository = ref.watch(communityRepositoryProvider);
        return repository.getUserCommunities(user.uid);
      }
      return Stream.value([]); // ইউজার না থাকলে খালি লিস্ট
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
    // এখানে read ব্যবহার করা ঠিক আছে কারণ এটি বাটনে চাপ দিলে কল হয়
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

// আগের getUserCommunities ফাংশনটি এখন আর এখানে দরকার নেই,
// কারণ আমরা সরাসরি প্রভাইডারের ভেতরেই লজিক লিখে দিয়েছি।


// ✅ NEW: Join Function
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
          Navigator.pop(context); // সফল হলে স্ক্রিন বন্ধ হবে
        },
      );
    } else {
      state = false;
      showSnackBar(context, 'User not logged in!');
    }
  }
}