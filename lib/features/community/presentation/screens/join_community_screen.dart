import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stake_grow/core/common/loader.dart';
import 'package:stake_grow/features/community/presentation/community_controller.dart';

class JoinCommunityScreen extends ConsumerStatefulWidget {
  const JoinCommunityScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _JoinCommunityScreenState();
}

class _JoinCommunityScreenState extends ConsumerState<JoinCommunityScreen> {
  final inviteCodeController = TextEditingController();

  @override
  void dispose() {
    inviteCodeController.dispose();
    super.dispose();
  }

  void join() {
    if (inviteCodeController.text.trim().isNotEmpty) {
      ref.read(communityControllerProvider.notifier).joinCommunity(
        inviteCodeController.text.trim(),
        context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(communityControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Join with Code')),
      body: isLoading
          ? const Loader()
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Enter the 6-digit Invite Code shared by your community admin.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: inviteCodeController,
              decoration: const InputDecoration(
                labelText: 'Invite Code',
                hintText: 'e.g. a1b2c3',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.vpn_key),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: join,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent, // জয়েইনিং এর জন্য আলাদা কালার
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(15),
                ),
                child: const Text('Join Community'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}