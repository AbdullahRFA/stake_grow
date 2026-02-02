import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stake_grow/features/community/domain/community_model.dart';

class SettingsScreen extends ConsumerWidget {
  final CommunityModel community;
  const SettingsScreen({super.key, required this.community});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text("Community Settings")),
      body: ListView(
        children: [
          // ✅ Only Member List is here now
          ListTile(
            leading: const Icon(Icons.group, color: Colors.blue),
            title: const Text("Member List"),
            subtitle: const Text("View and manage members"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              context.push('/member-list', extra: community);
            },
          ),
        ],
      ),
    );
  }
}