import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stake_grow/features/community/domain/community_model.dart';
import 'package:stake_grow/features/community/presentation/community_controller.dart';
import 'package:stake_grow/features/community/presentation/screens/withdrawal_screen.dart';
import 'package:stake_grow/features/community/presentation/transaction_providers.dart';

class SettingsScreen extends ConsumerWidget {
  final CommunityModel communityData;
  const SettingsScreen({super.key, required this.communityData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final communityAsync = ref.watch(
      communityDetailsProvider(communityData.id),
    );

    return Scaffold(
      backgroundColor: Colors.grey[100], // Soft background
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: communityAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (community) {
          final isMainAdmin = user != null && user.uid == community.adminId;

          // ✅ Get My Subscription Amount
          final mySubscription =
          (user != null &&
              community.monthlySubscriptions.containsKey(user.uid))
              ? community.monthlySubscriptions[user.uid]
              : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Section
                _buildHeader(community, isMainAdmin),

                const SizedBox(height: 24),

                // 2. Personal Commitment Card
                const Text(
                  "MY COMMITMENT",
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.2),
                ),
                const SizedBox(height: 8),
                _buildSubscriptionCard(
                  context,
                  ref,
                  community.id,
                  user!.uid,
                  mySubscription!,
                ),

                const SizedBox(height: 24),

                // 3. General Settings Group
                const Text(
                  "GENERAL",
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.2),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildSettingsTile(
                        icon: Icons.account_balance_rounded,
                        color: Colors.purple,
                        title: "Fund & Withdrawal Policy",
                        subtitle: "Check rules & request funds",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    WithdrawalScreen(community: community)),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        icon: Icons.groups_rounded,
                        color: Colors.blueAccent,
                        title: "Member List",
                        subtitle: "View & manage members",
                        onTap: () {
                          context.push('/member-list', extra: community);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 4. Admin / Danger Zone
                if (isMainAdmin) ...[
                  const Text(
                    "ADMINISTRATION",
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSettingsTile(
                          icon: Icons.edit_rounded,
                          color: Colors.orange,
                          title: "Edit Community Name",
                          onTap: () => _showEditDialog(context, ref, community),
                        ),
                        _buildDivider(),
                        _buildSettingsTile(
                          icon: Icons.delete_forever_rounded,
                          color: Colors.red,
                          title: "Delete Community",
                          subtitle: "Permanent action",
                          isDestructive: true,
                          onTap: () =>
                              _showDeleteDialog(context, ref, community.id),
                        ),
                      ],
                    ),
                  ),
                ],

                // 5. Leave Community (For Non-Admins)
                if (!isMainAdmin) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _buildSettingsTile(
                      icon: Icons.exit_to_app_rounded,
                      color: Colors.redAccent,
                      title: "Leave Community",
                      isDestructive: true,
                      onTap: () => _showLeaveDialog(context, ref, community.id),
                    ),
                  ),
                ],

                const SizedBox(height: 40),
                Center(
                  child: Text(
                    "ID: ${community.id}",
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget: Header with Community Name & Role
  Widget _buildHeader(CommunityModel community, bool isMainAdmin) {
    return Row(
      children: [
        Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.teal.shade100, width: 2),
          ),
          child: Center(
            child: Text(
              community.name[0].toUpperCase(),
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              community.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isMainAdmin
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isMainAdmin ? "MAIN ADMIN" : "MEMBER",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isMainAdmin ? Colors.orange : Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Widget: Subscription Dashboard Card
  Widget _buildSubscriptionCard(BuildContext context, WidgetRef ref, String cId,
      String uId, double amount) {
    final hasSet = amount > 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade400, Colors.teal.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.teal.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasSet ? "Monthly Subscription" : "Setup Subscription",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  hasSet ? "৳${amount.toStringAsFixed(0)}" : "Not Set",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () =>
                _showSubscriptionDialog(context, ref, cId, uId, amount),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.edit, color: Colors.white),
          )
        ],
      ),
    );
  }

  // Widget: Reusable Settings Tile
  Widget _buildSettingsTile({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red : Colors.black87,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 12))
          : null,
      trailing:
      Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 60, color: Colors.grey.shade200);
  }

  // --- Dialogs (Styled) ---

  void _showSubscriptionDialog(BuildContext context, WidgetRef ref,
      String communityId, String userId, double currentAmount) {
    final controller = TextEditingController(
      text: currentAmount > 0 ? currentAmount.toStringAsFixed(0) : "",
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Fixed Monthly Amount"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Enter the amount you commit to pay every month.",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Amount",
                prefixText: "৳ ",
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: () {
              final amount = double.tryParse(controller.text.trim());
              if (amount != null && amount > 0) {
                ref
                    .read(communityControllerProvider.notifier)
                    .updateMonthlySubscription(
                    communityId, userId, amount, context);
              }
            },
            child: const Text("Save Amount"),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
      BuildContext context, WidgetRef ref, CommunityModel community) {
    final controller = TextEditingController(text: community.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Edit Community Name"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Community Name",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(communityControllerProvider.notifier)
                  .editCommunity(community.id, controller.text.trim(), context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  void _showLeaveDialog(
      BuildContext context, WidgetRef ref, String communityId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Leave Community?"),
        content: const Text(
            "Are you sure you want to leave? You will need a new invite code to join again."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Stay")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(communityControllerProvider.notifier)
                  .leaveCommunity(communityId, context);
            },
            child: const Text("Leave"),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, WidgetRef ref, String communityId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Community?"),
        content: const Text(
          "Warning: This will permanently delete the community and all associated data for everyone. This action cannot be undone.",
          style: TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(communityControllerProvider.notifier)
                  .deleteCommunity(communityId, context);
            },
            child: const Text("DELETE PERMANENTLY"),
          ),
        ],
      ),
    );
  }
}