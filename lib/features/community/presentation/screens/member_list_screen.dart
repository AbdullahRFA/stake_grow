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
    final isAdmin = currentUser != null && currentUser.uid == community.adminId;

    return Scaffold(
      appBar: AppBar(title: const Text("Community Members")),
      // ✅ FIX: StreamBuilder এর টাইপ বলে দেওয়া হয়েছে
      body: StreamBuilder<List<UserModel>>(
        stream: ref.read(communityControllerProvider.notifier).getCommunityMembers(community.members),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Loader();
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No members found."));
          }

          final members = snapshot.data!;

          return ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              final user = members[index];
              final isMe = user.uid == currentUser?.uid;
              final isUserAdmin = user.uid == community.adminId;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal.shade100,
                  child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : "?"),
                ),
                title: Text(user.name + (isMe ? " (You)" : "")),
                subtitle: Text(
                  isUserAdmin ? "Admin" : (user.profession ?? "Member"),
                  style: TextStyle(
                    color: isUserAdmin ? Colors.red : Colors.grey,
                    fontWeight: isUserAdmin ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: (isAdmin && !isMe)
                    ? PopupMenuButton(
                  onSelected: (value) {
                    if (value == 'remove') {
                      _confirmRemove(context, ref, user.uid, user.name);
                    } else if (value == 'make_admin') {
                      _confirmMakeAdmin(context, ref, user.uid, user.name);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'make_admin',
                      child: Row(
                        children: [
                          Icon(Icons.verified_user, color: Colors.blue),
                          SizedBox(width: 8),
                          Text("Make Admin"),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.remove_circle, color: Colors.red),
                          SizedBox(width: 8),
                          Text("Remove Member"),
                        ],
                      ),
                    ),
                  ],
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