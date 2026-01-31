import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stake_grow/core/utils/utils.dart';
import 'package:stake_grow/features/auth/presentation/auth_controller.dart';
import 'package:stake_grow/features/community/data/community_repository.dart';
import 'package:stake_grow/features/community/domain/community_model.dart';
import 'package:uuid/uuid.dart';

// 1. Stream Provider: এটি ইউজারের কমিউনিটি লিস্ট রিয়েল-টাইমে মনিটর করবে
final userCommunitiesProvider = StreamProvider((ref) {
  final communityController = ref.watch(communityControllerProvider.notifier);
  return communityController.getUserCommunities();
});

// 2. Controller Provider
final communityControllerProvider = StateNotifierProvider<CommunityController, bool>((ref) {
  final communityRepository = ref.watch(communityRepositoryProvider);
  return CommunityController(communityRepository: communityRepository, ref: ref);
});

class CommunityController extends StateNotifier<bool> {
  final CommunityRepository _communityRepository;
  final Ref _ref; // অন্য প্রভাইডার (যেমন: User) পড়ার জন্য Ref লাগে

  CommunityController({
    required CommunityRepository communityRepository,
    required Ref ref,
  })  : _communityRepository = communityRepository,
        _ref = ref,
        super(false); // লোডিং ফলস

  // কমিউনিটি তৈরি করার ফাংশন
  void createCommunity(String name, BuildContext context) async {
    state = true; // লোডিং শুরু

    // ক) বর্তমান ইউজারের আইডি বের করা
    // authStateChangeProvider থেকে আমরা ইউজার অবজেক্ট পাচ্ছি
    final user = _ref.read(authStateChangeProvider).value;

    if (user != null) {
      // খ) ইউনিক আইডি জেনারেট করা
      final communityId = const Uuid().v1();

      // গ) মডেল সাজানো
      CommunityModel community = CommunityModel(
        id: communityId,
        name: name,
        adminId: user.uid,
        members: [user.uid], // এডমিন নিজেই প্রথম মেম্বার
        totalFund: 0.0,
        inviteCode: const Uuid().v4().substring(0, 6), // ছোট ৬ সংখ্যার ইনভাইট কোড
        createdAt: DateTime.now(),
      );

      // ঘ) রিপোজিটরিতে পাঠানো
      final res = await _communityRepository.createCommunity(community);

      state = false; // লোডিং শেষ

      res.fold(
            (l) => showSnackBar(context, l.message), // এরর হলে
            (r) {
          showSnackBar(context, 'Community Created Successfully! 🚀');
          Navigator.pop(context); // ডায়ালগ বা পেজ বন্ধ করা
        },
      );
    } else {
      state = false;
      showSnackBar(context, 'User not logged in!');
    }
  }

  // স্ট্রিম ফাংশন
  Stream<List<CommunityModel>> getUserCommunities() {
    final user = _ref.read(authStateChangeProvider).value;
    if (user != null) {
      return _communityRepository.getUserCommunities(user.uid);
    }
    return Stream.value([]); // ইউজার না থাকলে খালি লিস্ট
  }
}