import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stake_grow/core/common/loader.dart';
import 'package:stake_grow/features/community/presentation/transaction_providers.dart';

class InvestmentHistoryScreen extends ConsumerWidget {
  final String communityId;
  const InvestmentHistoryScreen({super.key, required this.communityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investments = ref.watch(communityInvestmentsProvider(communityId));

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

              // 🔴 FIX: ROI ক্যালকুলেশন যোগ করা হলো
              // ROI = (Profit / Invested Amount) * 100
              double roi = invest.investedAmount == 0
                  ? 0
                  : (invest.expectedProfit / invest.investedAmount) * 100;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.bar_chart, color: Colors.white),
                  ),
                  title: Text(invest.projectName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  // 🔴 FIX: invest.expectedRoi -> roi variable
                  subtitle: Text("Status: ${invest.status.toUpperCase()}\nExpected ROI: ${roi.toStringAsFixed(1)}%"),
                  isThreeLine: true,
                  trailing: Text(
                    '- ৳${invest.investedAmount}',
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}