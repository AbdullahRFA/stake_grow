import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stake_grow/core/utils/utils.dart';
import 'package:stake_grow/features/activity/data/activity_repository.dart';
import 'package:stake_grow/features/activity/domain/activity_model.dart';
import 'package:uuid/uuid.dart';

final activityControllerProvider = StateNotifierProvider<ActivityController, bool>((ref) {
  final repo = ref.watch(activityRepositoryProvider);
  return ActivityController(repo: repo);
});

class ActivityController extends StateNotifier<bool> {
  final ActivityRepository _repo;

  ActivityController({required ActivityRepository repo}) : _repo = repo, super(false);

  void createActivity({
    required String communityId,
    required String title,
    required String details,
    required double cost,
    required String type,
    required BuildContext context,
  }) async {
    state = true;
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final activityId = const Uuid().v1();

      final activity = ActivityModel(
        id: activityId,
        communityId: communityId,
        title: title,
        details: details,
        cost: cost,
        date: DateTime.now(),
        type: type,
      );

      final res = await _repo.createActivity(activity);
      state = false;

      res.fold(
            (l) => showSnackBar(context, l.message),
            (r) {
          showSnackBar(context, 'Activity Expense Recorded! 📉');
          Navigator.pop(context);
        },
      );
    } else {
      state = false;
      showSnackBar(context, 'Access Denied');
    }
  }
}