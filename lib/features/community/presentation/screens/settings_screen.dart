import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stake_grow/features/auth/data/auth_repository.dart';
import 'package:stake_grow/features/community/domain/community_model.dart';

class SettingsScreen extends ConsumerWidget {
  final CommunityModel community;
  const SettingsScreen({super.key, required this.community});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          // 1. Profile Edit
          ListTile(
            leading: const Icon(Icons.person, color: Colors.teal),
            title: const Text("Edit Profile"),
            subtitle: const Text("Name, Profession, Phone"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              context.push('/edit-profile');
            },
          ),
          const Divider(),

          // 2. Member Management
          ListTile(
            leading: const Icon(Icons.group, color: Colors.blue),
            title: const Text("Member List"),
            subtitle: const Text("View and manage members"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              context.push('/member-list', extra: community);
            },
          ),
          const Divider(),

          // 3. Log Out
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Log Out"),
            onTap: () {
              ref.read(authRepositoryProvider).logOut();
              context.go('/login'); // Redirect to login
            },
          ),
        ],
      ),
    );
  }
}