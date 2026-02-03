import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stake_grow/core/common/loader.dart';
import 'package:stake_grow/features/donation/presentation/donation_controller.dart';

class CreateDonationScreen extends ConsumerStatefulWidget {
  final String communityId;
  final bool isMonthlyDisabled;

  const CreateDonationScreen({
    super.key,
    required this.communityId,
    this.isMonthlyDisabled = false,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CreateDonationScreenState();
}

class _CreateDonationScreenState extends ConsumerState<CreateDonationScreen> {
  final amountController = TextEditingController();
  final trxIdController = TextEditingController(); // ✅
  final phoneController = TextEditingController(); // ✅

  String selectedType = 'Random';
  String selectedPaymentMethod = 'Manual (Cash)'; // ✅

  @override
  void initState() {
    super.initState();
    if (!widget.isMonthlyDisabled) {
      selectedType = 'Monthly';
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    trxIdController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void deposit() {
    if (amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Amount cannot be empty')));
      return;
    }

    // Validation for Online Payment
    if (selectedPaymentMethod != 'Manual (Cash)') {
      if (trxIdController.text.trim().isEmpty || phoneController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction ID and Phone Number are required for online payment')),
        );
        return;
      }
    }

    final amount = double.tryParse(amountController.text.trim());
    if (amount != null && amount > 0) {
      ref.read(donationControllerProvider.notifier).makeDonation(
        communityId: widget.communityId,
        amount: amount,
        type: selectedType,
        paymentMethod: selectedPaymentMethod, // ✅
        transactionId: selectedPaymentMethod != 'Manual (Cash)' ? trxIdController.text.trim() : null, // ✅
        phoneNumber: selectedPaymentMethod != 'Manual (Cash)' ? phoneController.text.trim() : null, // ✅
        context: context,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount greater than 0')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(donationControllerProvider);
    List<String> donationTypes = ['Monthly', 'Random'];
    if (widget.isMonthlyDisabled) {
      donationTypes.remove('Monthly');
    }

    // Payment Methods
    List<String> paymentMethods = ['Bkash', 'Rocket', 'Nagad', 'Manual (Cash)'];

    return Scaffold(
      appBar: AppBar(title: const Text('Make a Deposit')), // ✅ Renamed
      body: isLoading
          ? const Loader()
          : SingleChildScrollView( // Changed to ScrollView to avoid overflow
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Deposit Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                labelText: 'Deposit Type',
                border: OutlineInputBorder(),
              ),
              items: donationTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => selectedType = val!),
            ),

            if (widget.isMonthlyDisabled)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Monthly deposit for this month is already completed! You can still make random deposits.",
                  style: TextStyle(color: Colors.green, fontSize: 12),
                ),
              ),

            const SizedBox(height: 20),

            // ✅ Payment Method Dropdown
            DropdownButtonFormField<String>(
              value: selectedPaymentMethod,
              decoration: const InputDecoration(
                labelText: 'Payment Method',
                border: OutlineInputBorder(),
              ),
              items: paymentMethods.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => selectedPaymentMethod = val!),
            ),

            // ✅ Conditional Fields for Online Payment
            if (selectedPaymentMethod != 'Manual (Cash)') ...[
              const SizedBox(height: 16),
              const Text('Payment Details', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 8),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Sender Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: trxIdController,
                decoration: const InputDecoration(
                  labelText: 'Transaction ID (TrxID)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.receipt_long),
                ),
              ),
            ],

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: deposit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(15),
                ),
                child: const Text('Confirm Deposit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}