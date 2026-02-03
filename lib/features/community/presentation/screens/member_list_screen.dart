import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stake_grow/core/common/loader.dart';
import 'package:stake_grow/features/auth/domain/user_model.dart';
import 'package:stake_grow/features/community/domain/community_model.dart';
import 'package:stake_grow/features/community/presentation/community_controller.dart';



class MemberListScreen extends ConsumerWidget {
  final CommunityModel community;
  const MemberListScreen({super.key, required this.community});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = FirebaseAuth.instance.currentUser;
    // Main Admin Check
    final isMainAdmin = currentUser != null && currentUser.uid == community.adminId;
    // Co-Admin Check (for kicking members, if you want Co-Admins to kick others)
    final isCoAdmin = currentUser != null && community.mods.contains(currentUser.uid);
    final canManageMembers = isMainAdmin || isCoAdmin;

    return Scaffold(
      appBar: AppBar(title: const Text("Community Members")),
      body: StreamBuilder<List<UserModel>>(
        stream: ref.read(communityControllerProvider.notifier).getCommunityMembers(community.members),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Loader();
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("No members found."));

          final members = snapshot.data!;

          return ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              final user = members[index];
              final isMe = user.uid == currentUser?.uid;

              // Role Checks
              final isOwner = user.uid == community.adminId;
              final isMod = community.mods.contains(user.uid);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isOwner ? Colors.orange : (isMod ? Colors.blue : Colors.teal.shade100),
                  child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : "?"),
                ),
                title: Text(user.name + (isMe ? " (You)" : "")),
                subtitle: Text(
                  isOwner ? "Owner (Main Admin)" : (isMod ? "Admin" : "Member"),
                  style: TextStyle(
                    color: isOwner ? Colors.orange : (isMod ? Colors.blue : Colors.grey),
                    fontWeight: (isOwner || isMod) ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: (!isMe && canManageMembers) // Only Admins can manage others
                    ? PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'remove') {
                      _confirmRemove(context, ref, user.uid, user.name);
                    } else if (value == 'make_mod') {
                      ref.read(communityControllerProvider.notifier).toggleModRole(community.id, user.uid, true, context);
                    } else if (value == 'dismiss_mod') {
                      ref.read(communityControllerProvider.notifier).toggleModRole(community.id, user.uid, false, context);
                    }
                  },
                  itemBuilder: (context) {
                    List<PopupMenuEntry<String>> options = [];

                    // Only Main Admin can assign/dismiss mods
                    if (isMainAdmin) {
                      if (!isMod) {
                        options.add(const PopupMenuItem(
                          value: 'make_mod',
                          child: Row(children: [Icon(Icons.security, color: Colors.blue), SizedBox(width: 8), Text("Make Admin")]),
                        ));
                      } else {
                        options.add(const PopupMenuItem(
                          value: 'dismiss_mod',
                          child: Row(children: [Icon(Icons.remove_moderator, color: Colors.orange), SizedBox(width: 8), Text("Dismiss Admin")]),
                        ));
                      }
                    }

                    // Main Admin can remove anyone (except self). Co-Admins can remove Members (not other Admins).
                    if (isMainAdmin || (isCoAdmin && !isMod && !isOwner)) {
                      options.add(const PopupMenuItem(
                        value: 'remove',
                        child: Row(children: [Icon(Icons.remove_circle, color: Colors.red), SizedBox(width: 8), Text("Kick Member")]),
                      ));
                    }

                    return options;
                  },
                )
                    : null,
              );
            },
          );
        },
      ),
    );
  }

  void _confirmRemove(BuildContext context, WidgetRef ref, String memberId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remove Member"),
        content: Text("Are you sure you want to remove $name?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              ref.read(communityControllerProvider.notifier).removeMember(community.id, memberId, context);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Remove"),
          ),
        ],
      ),
    );
  }

  void _confirmMakeAdmin(BuildContext context, WidgetRef ref, String memberId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Transfer Ownership"),
        content: Text("Make $name the new Admin? You will lose admin privileges."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              ref.read(communityControllerProvider.notifier).updateAdmin(community.id, memberId, context);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }
}