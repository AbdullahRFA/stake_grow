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

    // Permission Checks
    final isMainAdmin = currentUser != null && currentUser.uid == community.adminId;
    final isCoAdmin = currentUser != null && community.mods.contains(currentUser.uid);
    final canManageMembers = isMainAdmin || isCoAdmin;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Community Members",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: ref.read(communityControllerProvider.notifier).getCommunityMembers(community.members),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Loader();
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final members = snapshot.data!;

          // Sort members: Owner first, then Admins, then regular members
          members.sort((a, b) {
            int getScore(String uid) {
              if (uid == community.adminId) return 3;
              if (community.mods.contains(uid)) return 2;
              return 1;
            }
            return getScore(b.uid).compareTo(getScore(a.uid));
          });

          return Column(
            children: [
              // Stats Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                color: Colors.blueAccent.withOpacity(0.05),
                child: Text(
                  "${members.length} Members",
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final user = members[index];
                    final isMe = user.uid == currentUser?.uid;

                    // Determine Roles
                    final isOwner = user.uid == community.adminId;
                    final isMod = community.mods.contains(user.uid);

                    return _buildMemberCard(
                        context,
                        ref,
                        user,
                        isMe,
                        isOwner,
                        isMod,
                        canManageMembers,
                        isMainAdmin,
                        isCoAdmin
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "No members found.",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(
      BuildContext context,
      WidgetRef ref,
      UserModel user,
      bool isMe,
      bool isOwner,
      bool isMod,
      bool canManageMembers,
      bool isMainAdmin,
      bool isCoAdmin,
      ) {
    // Role Colors
    final Color roleColor = isOwner ? Colors.amber.shade700 : (isMod ? Colors.blueAccent : Colors.grey.shade600);
    final Color avatarBorderColor = isOwner ? Colors.amber : (isMod ? Colors.blueAccent.withOpacity(0.5) : Colors.transparent);
    final String roleLabel = isOwner ? "Owner" : (isMod ? "Admin" : "Member");
    final IconData roleIcon = isOwner ? Icons.workspace_premium : (isMod ? Icons.security : Icons.person_outline);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: avatarBorderColor, width: 2),
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey.shade200,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : "?",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800, fontSize: 20),
                ),
              ),
            ),
            if (isOwner || isMod)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: roleColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(roleIcon, size: 10, color: Colors.white),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                user.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            if (isMe)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: const Text("YOU", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.teal)),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  roleLabel.toUpperCase(),
                  style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        trailing: (!isMe && canManageMembers)
            ? PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) {
            if (value == 'remove') {
              _confirmRemove(context, ref, user.uid, user.name);
            } else if (value == 'make_mod') {
              ref.read(communityControllerProvider.notifier).toggleModRole(community.id, user.uid, true, context);
            } else if (value == 'dismiss_mod') {
              _confirmDemote(context, ref, user.uid, user.name);
            }
          },
          itemBuilder: (context) {
            List<PopupMenuEntry<String>> options = [];

            // ✅ MAIN ADMIN ONLY ACTIONS
            if (isMainAdmin) {
              if (!isMod) {
                options.add(_buildPopupItem('make_mod', Icons.shield_outlined, "Promote to Admin", Colors.blue));
              } else {
                options.add(_buildPopupItem('dismiss_mod', Icons.remove_moderator_outlined, "Dismiss Admin", Colors.orange));
              }
            }

            // ✅ KICK ACTIONS
            if (isMainAdmin || (isCoAdmin && !isMod && !isOwner)) {
              options.add(_buildPopupItem('remove', Icons.person_remove_outlined, "Kick Member", Colors.red));
            }

            return options;
          },
        )
            : null,
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, IconData icon, String text, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  void _confirmRemove(BuildContext context, WidgetRef ref, String memberId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Remove Member"),
        content: Text.rich(
          TextSpan(
            text: "Are you sure you want to remove ",
            style: const TextStyle(fontSize: 14),
            children: [
              TextSpan(text: name, style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: " from the community?"),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              ref.read(communityControllerProvider.notifier).removeMember(community.id, memberId, context);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text("Remove"),
          ),
        ],
      ),
    );
  }

  void _confirmDemote(BuildContext context, WidgetRef ref, String memberId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Dismiss Admin?"),
        content: const Text(
          "Are you sure you want to remove Admin privileges from this user? They will become a regular member.",
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              ref.read(communityControllerProvider.notifier).toggleModRole(community.id, memberId, false, context);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text("Dismiss"),
          ),
        ],
      ),
    );
  }
}