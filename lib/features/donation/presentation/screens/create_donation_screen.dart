import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stake_grow/core/common/loader.dart';
import 'package:stake_grow/features/donation/presentation/donation_controller.dart';

class CreateDonationScreen extends ConsumerStatefulWidget {
  final String communityId;
  final bool isMonthlyDisabled; // ✅ NEW PARAMETER

  const CreateDonationScreen({
    super.key,
    required this.communityId,
    this.isMonthlyDisabled = false, // Default false
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CreateDonationScreenState();
}

class _CreateDonationScreenState extends ConsumerState<CreateDonationScreen> {
  final amountController = TextEditingController();
  String selectedType = 'Random';

  @override
  void initState() {
    super.initState();
    // ✅ যদি Monthly ডিজেবল না থাকে, তাহলে ডিফল্ট Monthly সেট করি
    if (!widget.isMonthlyDisabled) {
      selectedType = 'Monthly';
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  void donate() {
    if (amountController.text.isNotEmpty) {
      final amount = double.tryParse(amountController.text.trim());
      if (amount != null && amount > 0) {
        ref.read(donationControllerProvider.notifier).makeDonation(
          communityId: widget.communityId,
          amount: amount,
          type: selectedType,
          context: context,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid amount greater than 0')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount cannot be empty')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(donationControllerProvider);

    // ✅ Dropdown Items Filter Logic
    List<String> donationTypes = ['Monthly', 'Random'];
    if (widget.isMonthlyDisabled) {
      donationTypes.remove('Monthly');
    }

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
              items: donationTypes
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  selectedType = val!;
                });
              },
            ),

            // ✅ Message if Monthly is disabled
            if (widget.isMonthlyDisabled)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Monthly donation for this month is already completed! You can still make random donations.",
                        style: TextStyle(color: Colors.green, fontSize: 12),
                      ),
                    ),
                  ],
                ),
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