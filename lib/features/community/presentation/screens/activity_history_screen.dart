import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stake_grow/core/common/loader.dart';
import 'package:stake_grow/features/community/presentation/transaction_providers.dart';

class ActivityHistoryScreen extends ConsumerWidget {
  final String communityId;
  const ActivityHistoryScreen({super.key, required this.communityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(communityActivitiesProvider(communityId));

    return Scaffold(
      appBar: AppBar(title: const Text('Community Activities')),
      body: activities.when(
        loading: () => const Loader(),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (data) {
          if (data.isEmpty) return const Center(child: Text('No activities recorded.'));
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final activity = data[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.redAccent,
                    child: Icon(Icons.volunteer_activism, color: Colors.white),
                  ),
                  title: Text(activity.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  // 🔴 FIX: activity.timestamp -> activity.date
                  subtitle: Text(
                      "${activity.type}\n${DateFormat('dd MMM yyyy').format(activity.date)}"),
                  isThreeLine: true,
                  trailing: Text(
                    '- ৳${activity.cost}',
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}