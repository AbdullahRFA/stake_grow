import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stake_grow/core/common/loader.dart';
import 'package:stake_grow/features/community/presentation/transaction_providers.dart';
import 'package:stake_grow/features/investment/domain/investment_model.dart';
import 'package:stake_grow/features/investment/presentation/investment_controller.dart';

class InvestmentHistoryScreen extends ConsumerWidget {
  final String communityId;
  const InvestmentHistoryScreen({super.key, required this.communityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Fetch Investments
    final investmentsAsync = ref.watch(communityInvestmentsProvider(communityId));
    // 2. Fetch Community Details (to check Admin)
    final communityAsync = ref.watch(communityDetailsProvider(communityId));
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Community Investments')),
      body: investmentsAsync.when(
        loading: () => const Loader(),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (investments) {
          // 3. Resolve Community Data
          return communityAsync.when(
            loading: () => const Loader(),
            error: (e, s) => Center(child: Text('Error loading community info: $e')),
            data: (community) {
              // 4. Determine if current user is Admin
              final isAdmin = currentUser != null && currentUser.uid == community.adminId;

              if (investments.isEmpty) return const Center(child: Text('No investments yet.'));

              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: investments.length,
                itemBuilder: (context, index) {
                  final invest = investments[index];
                  final isActive = invest.status == 'active';

                  // ✅ ১. ইউজার স্পেসিফিক শেয়ার ক্যালকুলেশন
                  double myShare = 0.0;
                  if (currentUser != null && invest.userShares.containsKey(currentUser.uid)) {
                    myShare = invest.userShares[currentUser.uid]!;
                  }

                  // শেয়ার পার্সেন্টেজ বের করা
                  double mySharePct = invest.investedAmount == 0
                      ? 0
                      : (myShare / invest.investedAmount) * 100;

                  // ✅ ২. ইউজার স্পেসিফিক লাভ/ক্ষতি ক্যালকুলেশন
                  double myProfitLoss = 0.0;
                  if (!isActive && invest.actualProfitLoss != null) {
                    // (আমার পার্সেন্টেজ / ১০০) * মোট লাভ বা ক্ষতি
                    myProfitLoss = (mySharePct / 100) * invest.actualProfitLoss!;
                  }

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          // হেডার সেকশন (প্রজেক্ট নাম ও স্ট্যাটাস)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: isActive
                                  ? Colors.orange
                                  : (invest.actualProfitLoss != null && invest.actualProfitLoss! >= 0
                                  ? Colors.green
                                  : Colors.red),
                              child: Icon(
                                isActive
                                    ? Icons.trending_up
                                    : (invest.actualProfitLoss != null && invest.actualProfitLoss! >= 0
                                    ? Icons.check
                                    : Icons.arrow_downward),
                                color: Colors.white,
                              ),
                            ),
                            title: Text(invest.projectName,
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                "Total Invested: ৳${invest.investedAmount} \nStatus: ${isActive ? 'Running' : 'Closed'}"),
                            isThreeLine: true,
                            // ✅ Only show action button if User is ADMIN and Investment is ACTIVE
                            trailing: (isActive && isAdmin)
                                ? IconButton(
                              icon: const Icon(Icons.input, color: Colors.blue),
                              onPressed: () => _showReturnDialog(context, ref, invest),
                              tooltip: "Record Return",
                            )
                                : null,
                          ),
                          const Divider(),

                          // ✅ ৩. স্টেকহোল্ডার ভিউ (My Stake & Return)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                // বাম পাশে: আমার শেয়ার
                                Column(
                                  children: [
                                    const Text("My Stake",
                                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    Text("৳${myShare.toStringAsFixed(0)}",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text("(${mySharePct.toStringAsFixed(1)}%)",
                                        style: const TextStyle(fontSize: 11, color: Colors.teal)),
                                  ],
                                ),

                                // ডান পাশে: প্রফিট বা লস
                                if (!isActive)
                                  Column(
                                    children: [
                                      Text(
                                          myProfitLoss >= 0
                                              ? "My Profit Share"
                                              : "My Loss Share",
                                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      const SizedBox(height: 4),
                                      Text(
                                        "৳${myProfitLoss.toStringAsFixed(0)}",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: myProfitLoss >= 0 ? Colors.green : Colors.red),
                                      ),
                                    ],
                                  )
                                else
                                  Column(
                                    children: [
                                      const Text("Est. Return",
                                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      const SizedBox(height: 4),
                                      Text(
                                        "~ ৳${((invest.expectedProfit * mySharePct) / 100).toStringAsFixed(0)}",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.orange),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // ✅ ইনভেস্টমেন্ট রিটার্ন ডায়ালগ (এডমিন একশন)
  void _showReturnDialog(BuildContext context, WidgetRef ref, InvestmentModel invest) {
    final returnController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Record Investment Return"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Project: ${invest.projectName}",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text("Invested: ৳${invest.investedAmount}",
                style: const TextStyle(color: Colors.grey)),
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
              "Note: This amount will be added back to the Community Fund and distributed based on share percentage.",
              style: TextStyle(fontSize: 12, color: Colors.redAccent),
              textAlign: TextAlign.center,
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
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal, foregroundColor: Colors.white),
            child: const Text("Confirm & Distribute"),
          ),
        ],
      ),
    );
  }
}