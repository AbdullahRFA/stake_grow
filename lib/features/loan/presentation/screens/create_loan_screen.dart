import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // ডেট ফরম্যাটিং এর জন্য
import 'package:stake_grow/core/common/loader.dart';
import 'package:stake_grow/features/loan/presentation/loan_controller.dart';

class CreateLoanScreen extends ConsumerStatefulWidget {
  final String communityId;
  const CreateLoanScreen({super.key, required this.communityId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CreateLoanScreenState();
}

class _CreateLoanScreenState extends ConsumerState<CreateLoanScreen> {
  final amountController = TextEditingController();
  final reasonController = TextEditingController();
  DateTime? selectedDate;

  @override
  void dispose() {
    amountController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  // ডেট পিকার ওপেন করার ফাংশন
  void pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)), // ডিফল্ট ১ মাস পর
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)), // সর্বোচ্চ ৩ বছর
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  void submitRequest() {
    if (amountController.text.isNotEmpty &&
        reasonController.text.isNotEmpty &&
        selectedDate != null) {

      final amount = double.tryParse(amountController.text.trim());

      if (amount != null && amount > 0) {
        ref.read(loanControllerProvider.notifier).requestLoan(
          communityId: widget.communityId,
          amount: amount,
          reason: reasonController.text.trim(),
          repaymentDate: selectedDate!,
          context: context,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(loanControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Request a Loan')),
      body: isLoading
          ? const Loader()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Loan Amount', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: '৳ ',
                border: OutlineInputBorder(),
                hintText: 'e.g. 5000',
              ),
            ),
            const SizedBox(height: 20),

            const Text('Reason for Loan', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Describe why you need this loan...',
              ),
            ),
            const SizedBox(height: 20),

            const Text('Repayment Deadline', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: pickDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedDate == null
                          ? 'Select Date'
                          : DateFormat('dd MMM, yyyy').format(selectedDate!),
                    ),
                    const Icon(Icons.calendar_today, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ✅ Rules Section Added Here
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("⚠️ Late Repayment Rules:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red)),
                  SizedBox(height: 8),
                  Text("▶ ডেড লাইন পার হলে প্রথম ৫ দিনের মধ্য পে করলে :\nমূল টাকার সাথে ৫% জরিমানা যুক্ত হবে।", style: TextStyle(fontSize: 12)),
                  SizedBox(height: 6),
                  Text("▶ ৬ষ্ট দিন থেকে ১০ম দিনের মধ্য পে করলে :\nমূল টাকার উপর ১০% জরিমানা সহ পরিশোধ করতে হবে।", style: TextStyle(fontSize: 12)),
                  SizedBox(height: 8),
                  Text("▶ ১০ম দিন পার হলে কমিটি যেই সিদ্ধান্ত নিবে তার সাথে আমি একমত।", style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(15),
                ),
                child: const Text('Submit Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}