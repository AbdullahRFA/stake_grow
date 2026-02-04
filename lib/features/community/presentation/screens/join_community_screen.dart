import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      // Dismiss keyboard
      FocusScope.of(context).unfocus();
      ref.read(communityControllerProvider.notifier).joinCommunity(
        inviteCodeController.text.trim(),
        context,
      );
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      setState(() {
        inviteCodeController.text = data!.text!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(communityControllerProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Loader()
          : Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header Illustration/Icon
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.diversity_3_rounded,
                    size: 60,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 2. Headings
              const Text(
                'Join a Community',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Enter the 6-digit unique code shared by your community admin to start investing.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // 3. Input Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: inviteCodeController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                  decoration: InputDecoration(
                    hintText: 'XYZ-123',
                    hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.normal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 20),
                    prefixIcon: const Icon(Icons.vpn_key_rounded,
                        color: Colors.blueAccent),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.content_paste_rounded,
                          color: Colors.grey),
                      tooltip: 'Paste',
                      onPressed: _pasteFromClipboard,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // 4. Action Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: join,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    elevation: 5,
                    shadowColor: Colors.blueAccent.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Join Now',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}