import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stake_grow/features/community/domain/community_model.dart';
import 'package:stake_grow/features/community/presentation/community_controller.dart';
import 'package:stake_grow/features/community/presentation/transaction_providers.dart';

class SettingsScreen extends ConsumerWidget {
  final CommunityModel communityData; // Changed name to distinguish from stream data
  const SettingsScreen({super.key, required this.communityData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    // Watch the live community data to get updates on roles/name changes
    final communityAsync = ref.watch(communityDetailsProvider(communityData.id));

    return Scaffold(
      appBar: AppBar(title: const Text("Community Settings")),
      body: communityAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (community) {
          final isMainAdmin = user != null && user.uid == community.adminId;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. Member Management
              ListTile(
                leading: const Icon(Icons.group, color: Colors.blue),
                title: const Text("Member List"),
                subtitle: const Text("View, manage members & assign roles"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  context.push('/member-list', extra: community);
                },
              ),
              const Divider(),

              // 2. Edit Community (Main Admin Only)
              if (isMainAdmin)
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.orange),
                  title: const Text("Edit Community Name"),
                  onTap: () => _showEditDialog(context, ref, community),
                ),

              // 3. Delete Community (Main Admin Only)
              if (isMainAdmin)
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text("Delete Community"),
                  subtitle: const Text("Permanent action. Cannot be undone."),
                  onTap: () => _showDeleteDialog(context, ref, community.id),
                ),

              // 4. Leave Community (Non-Main Admins Only)
              if (!isMainAdmin)
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: Colors.redAccent),
                  title: const Text("Leave Community"),
                  onTap: () => _showLeaveDialog(context, ref, community.id),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, CommunityModel community) {
    final controller = TextEditingController(text: community.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Name"),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: "Name")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              ref.read(communityControllerProvider.notifier).editCommunity(community.id, controller.text.trim(), context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showLeaveDialog(BuildContext context, WidgetRef ref, String communityId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Leave Community?"),
        content: const Text("Are you sure you want to leave? You will need an invite code to join again."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(communityControllerProvider.notifier).leaveCommunity(communityId, context);
            },
            child: const Text("Leave"),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, String communityId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Community?"),
        content: const Text("Warning: This will delete the community permanently for all members. This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(communityControllerProvider.notifier).deleteCommunity(communityId, context);
            },
            child: const Text("DELETE"),
          ),
        ],
      ),
    );
  }
}