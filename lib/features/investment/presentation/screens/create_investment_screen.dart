import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stake_grow/core/common/loader.dart';
import 'package:stake_grow/features/investment/presentation/investment_controller.dart';

class CreateInvestmentScreen extends ConsumerStatefulWidget {
  final String communityId;
  const CreateInvestmentScreen({super.key, required this.communityId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CreateInvestmentScreenState();
}

class _CreateInvestmentScreenState extends ConsumerState<CreateInvestmentScreen> {
  final titleController = TextEditingController();
  final detailsController = TextEditingController();
  final amountController = TextEditingController();
  final profitController = TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    detailsController.dispose();
    amountController.dispose();
    profitController.dispose();
    super.dispose();
  }

  void submit() {
    if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
      final amount = double.tryParse(amountController.text.trim());
      final profit = double.tryParse(profitController.text.trim()) ?? 0.0;

      if (amount != null && amount > 0) {
        ref.read(investmentControllerProvider.notifier).createInvestment(
          communityId: widget.communityId,
          projectName: titleController.text.trim(),
          details: detailsController.text.trim(),
          amount: amount,
          expectedProfit: profit,
          context: context,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(investmentControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Investment Project')),
      body: isLoading
          ? const Loader()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Project Name',
                hintText: 'e.g. Fish Farming Project',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Investment Amount (Cost)',
                prefixText: '৳ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: profitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Expected Profit (Optional)',
                prefixText: '৳ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: detailsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Project Details',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade800, // Investment কালার
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(15),
                ),
                child: const Text('Confirm Investment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}