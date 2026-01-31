import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stake_grow/core/common/loader.dart';
import 'package:stake_grow/features/donation/presentation/donation_controller.dart';

class CreateDonationScreen extends ConsumerStatefulWidget {
  final String communityId;
  const CreateDonationScreen({super.key, required this.communityId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CreateDonationScreenState();
}

class _CreateDonationScreenState extends ConsumerState<CreateDonationScreen> {
  final amountController = TextEditingController();
  String selectedType = 'Random'; // Default

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  void donate() {
    print("Donate button pressed"); // 1. বাটন চাপলে এটা কনসোলে আসবে

    if (amountController.text.isNotEmpty) {
      final amount = double.tryParse(amountController.text.trim());

      if (amount != null && amount > 0) {
        print("Valid amount: $amount. Calling controller..."); // 2. ভ্যালিডেশন পাস

        ref.read(donationControllerProvider.notifier).makeDonation(
          communityId: widget.communityId,
          amount: amount,
          type: selectedType,
          context: context,
        );
      } else {
        print("Invalid amount entered"); // 3. ভুল এমাউন্ট
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid amount greater than 0')),
        );
      }
    } else {
      print("Amount field is empty"); // 4. খালি ফিল্ড
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount cannot be empty')),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(donationControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Make a Donation')),
      body: isLoading
          ? const Loader()
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Contribution Amount',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: '৳ ',
                hintText: '500',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: const InputDecoration(
                labelText: 'Donation Type',
                border: OutlineInputBorder(),
              ),
              items: ['Monthly', 'Random']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  selectedType = val!;
                });
              },
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: donate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(15),
                ),
                child: const Text('Confirm Donation'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}