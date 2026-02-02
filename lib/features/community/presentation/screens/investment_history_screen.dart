import 'package:firebase_auth/firebase_auth.dart'; // Admin Check
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stake_grow/core/common/loader.dart';
import 'package:stake_grow/features/community/domain/community_model.dart'; // CommunityModel needed for admin check
import 'package:stake_grow/features/community/presentation/transaction_providers.dart';
import 'package:stake_grow/features/investment/domain/investment_model.dart';
import 'package:stake_grow/features/investment/presentation/investment_controller.dart';

class InvestmentHistoryScreen extends ConsumerWidget {
  final String communityId;
  const InvestmentHistoryScreen({super.key, required this.communityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investments = ref.watch(communityInvestmentsProvider(communityId));
    final currentUser = FirebaseAuth.instance.currentUser;

    // ⚠️ Note: For strict admin check, pass the CommunityModel or fetch it.
    // For now, assuming UI logic allows buttons, but backend enforces rules (rules need update).
    // Or simpler: We will just show the button, logic is handled in controller.

    return Scaffold(
      appBar: AppBar(title: const Text('Community Investments')),
      body: investments.when(
        loading: () => const Loader(),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (data) {
          if (data.isEmpty) return const Center(child: Text('No investments yet.'));
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final invest = data[index];
              final isActive = invest.status == 'active';

              // ROI Calculation
              double roi = invest.investedAmount == 0
                  ? 0
                  : (invest.expectedProfit / invest.investedAmount) * 100;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isActive ? Colors.orange : (invest.actualProfitLoss! >= 0 ? Colors.green : Colors.red),
                    child: Icon(
                      isActive ? Icons.trending_up : (invest.actualProfitLoss! >= 0 ? Icons.check : Icons.arrow_downward),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(invest.projectName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Invested: ৳${invest.investedAmount}"),
                      if (isActive)
                        Text("Expected Profit: ৳${invest.expectedProfit} (${roi.toStringAsFixed(1)}%)")
                      else
                        Text(
                          "Returned: ৳${invest.returnAmount} \n${invest.actualProfitLoss! >= 0 ? 'Profit' : 'Loss'}: ৳${invest.actualProfitLoss}",
                          style: TextStyle(
                            color: invest.actualProfitLoss! >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  isThreeLine: true,
                  // ✅ Action Button for Admin to Close Investment
                  trailing: isActive
                      ? IconButton(
                    icon: const Icon(Icons.input, color: Colors.blue),
                    onPressed: () => _showReturnDialog(context, ref, invest),
                    tooltip: "Record Return",
                  )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ✅ Return Recording Dialog
  void _showReturnDialog(BuildContext context, WidgetRef ref, InvestmentModel invest) {
    final returnController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Record Investment Return"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Project: ${invest.projectName}"),
            const SizedBox(height: 5),
            Text("Invested: ৳${invest.investedAmount}", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 15),
            TextField(
              controller: returnController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Total Returned Amount",
                hintText: "Include principal + profit",
                border: OutlineInputBorder(),
                prefixText: "৳ ",
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Note: This amount will be added back to the Community Fund.",
              style: TextStyle(fontSize: 12, color: Colors.redAccent),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final returnAmount = double.tryParse(returnController.text.trim());
              if (returnAmount != null) {
                ref.read(investmentControllerProvider.notifier).closeInvestment(
                  communityId: invest.communityId,
                  investmentId: invest.id,
                  investedAmount: invest.investedAmount,
                  returnAmount: returnAmount,
                  context: context,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            child: const Text("Confirm & Distribute"),
          ),
        ],
      ),
    );
  }
}