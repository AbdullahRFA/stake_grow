import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stake_grow/core/common/loader.dart';
import 'package:stake_grow/features/auth/data/auth_repository.dart';
import 'package:stake_grow/features/community/presentation/transaction_providers.dart';
import 'package:stake_grow/features/investment/domain/investment_model.dart';
import 'package:stake_grow/features/investment/presentation/investment_controller.dart';

// ✅ PDF Imports
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class InvestmentHistoryScreen extends ConsumerWidget {
  final String communityId;
  const InvestmentHistoryScreen({super.key, required this.communityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investmentsAsync = ref.watch(communityInvestmentsProvider(communityId));
    final communityAsync = ref.watch(communityDetailsProvider(communityId));
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Community Investments')),
      body: investmentsAsync.when(
        loading: () => const Loader(),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (investments) {
          return communityAsync.when(
            loading: () => const Loader(),
            error: (e, s) => Center(child: Text('Error loading community info: $e')),
            data: (community) {
              final isAdmin = currentUser != null && currentUser.uid == community.adminId;

              if (investments.isEmpty) return const Center(child: Text('No investments yet.'));

              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: investments.length,
                itemBuilder: (context, index) {
                  final invest = investments[index];
                  final isActive = invest.status == 'active';

                  double myShare = 0.0;
                  if (currentUser != null && invest.userShares.containsKey(currentUser.uid)) {
                    myShare = invest.userShares[currentUser.uid]!;
                  }
                  double mySharePct = invest.investedAmount == 0 ? 0 : (myShare / invest.investedAmount) * 100;
                  double myProfitLoss = 0.0;
                  if (!isActive && invest.actualProfitLoss != null) {
                    myProfitLoss = (mySharePct / 100) * invest.actualProfitLoss!;
                  }

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          // 1. Header
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
                            title: Text(invest.projectName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            subtitle: Text("Status: ${isActive ? 'Running ⏳' : 'Closed 🏁'}",
                                style: TextStyle(color: isActive ? Colors.orange : Colors.grey)),
                            trailing: (isActive && isAdmin)
                                ? IconButton(
                              icon: const Icon(Icons.input, color: Colors.blue),
                              onPressed: () => _showReturnDialog(context, ref, invest),
                              tooltip: "Record Return",
                            )
                                : null,
                          ),

                          const Divider(),

                          // 2. Detailed Info Table
                          _buildDetailRow("Description", invest.details),
                          _buildDetailRow("Invested Amount", "৳${invest.investedAmount}"),
                          if(isActive) _buildDetailRow("Exp. Profit", "৳${invest.expectedProfit}"),
                          _buildDetailRow("Start Date", DateFormat('dd MMM yyyy').format(invest.startDate)),

                          if(!isActive && invest.endDate != null) ...[
                            _buildDetailRow("End Date", DateFormat('dd MMM yyyy').format(invest.endDate!)),
                            _buildDetailRow("Return Amount", "৳${invest.returnAmount}", color: Colors.blue),
                            _buildDetailRow(
                                "Net P/L",
                                "৳${invest.actualProfitLoss} (${((invest.actualProfitLoss!/invest.investedAmount)*100).toStringAsFixed(1)}%)",
                                color: invest.actualProfitLoss! >= 0 ? Colors.green : Colors.red,
                                isBold: true
                            ),
                          ],

                          const SizedBox(height: 10),

                          // 3. My Stake Summary
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    const Text("My Stake", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    Text("৳${myShare.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text("${mySharePct.toStringAsFixed(1)}%", style: const TextStyle(fontSize: 11, color: Colors.teal)),
                                  ],
                                ),
                                if (!isActive)
                                  Column(
                                    children: [
                                      Text(myProfitLoss >= 0 ? "My Profit" : "My Loss", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      Text("৳${myProfitLoss.toStringAsFixed(0)}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: myProfitLoss >= 0 ? Colors.green : Colors.red)),
                                    ],
                                  )
                              ],
                            ),
                          ),

                          // 4. Report Button
                          if (!isActive) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _generatePdf(context, ref, invest),
                                icon: const Icon(Icons.picture_as_pdf),
                                label: const Text("Download Report 📄"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ]
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

  Widget _buildDetailRow(String label, String value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(child: Text(value, style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black87
          ))),
        ],
      ),
    );
  }

  // ✅ PDF Generation Logic
  void _generatePdf(BuildContext context, WidgetRef ref, InvestmentModel invest) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    try {
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.nunitoExtraLight();

      // Fetch Names
      Map<String, String> stakeholderNames = {};
      final authRepo = ref.read(authRepositoryProvider);

      for(String uid in invest.userShares.keys) {
        final user = await authRepo.getUserData(uid);
        stakeholderNames[uid] = user?.name ?? "Member";
      }

      final isProfit = invest.actualProfitLoss! >= 0;
      final statusColor = isProfit ? PdfColors.green : PdfColors.red;
      final currency = "BDT";

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: font),
          build: (pw.Context context) {
            return [
              // Header
              pw.Header(
                  level: 0,
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("Investment Closure Report", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                        pw.Text(DateFormat('dd MMM yyyy').format(DateTime.now()), style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
                      ]
                  )
              ),

              pw.SizedBox(height: 20),

              // Project Info
              pw.Text("Executive Summary", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Text("Project Name: ${invest.projectName}"),
              pw.Text("Description: ${invest.details}"),
              pw.Text("Status: ${invest.status.toUpperCase()}"),
              pw.Text("Duration: ${DateFormat('dd MMM yyyy').format(invest.startDate)} - ${DateFormat('dd MMM yyyy').format(invest.endDate!)}"),

              pw.SizedBox(height: 20),

              // ✅ NEW: Stakeholder Contribution Breakdown
              pw.Text("Initial Contribution Breakdown", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text("Total Invested Capital: $currency ${invest.investedAmount}", style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
              pw.SizedBox(height: 5),

              pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    // Header
                    pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                        children: [
                          _pdfCell("Stakeholder Name", isHeader: true),
                          _pdfCell("Contributed Amount", isHeader: true),
                          _pdfCell("Ownership %", isHeader: true),
                        ]
                    ),
                    // Rows
                    ...invest.userShares.entries.map((entry) {
                      final uid = entry.key;
                      final share = entry.value;
                      final pct = (share / invest.investedAmount) * 100;

                      return pw.TableRow(children: [
                        _pdfCell(stakeholderNames[uid] ?? "Unknown"),
                        _pdfCell("$currency ${share.toStringAsFixed(0)}"),
                        _pdfCell("${pct.toStringAsFixed(2)}%"),
                      ]);
                    }).toList(),
                  ]
              ),

              pw.SizedBox(height: 20),

              // Financial Overview
              pw.Text("Financial Statement", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  children: [
                    pw.TableRow(children: [
                      _pdfCell("Total Invested Capital", isHeader: true),
                      _pdfCell("$currency ${invest.investedAmount}"),
                    ]),
                    pw.TableRow(children: [
                      _pdfCell("Total Returned Amount", isHeader: true),
                      _pdfCell("$currency ${invest.returnAmount}"),
                    ]),
                    pw.TableRow(children: [
                      _pdfCell("Net ${isProfit ? 'Profit' : 'Loss'}", isHeader: true, color: statusColor),
                      _pdfCell("$currency ${invest.actualProfitLoss}", color: statusColor, isBold: true),
                    ]),
                  ]
              ),

              pw.SizedBox(height: 20),

              // Methodology
              pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  color: PdfColors.grey100,
                  child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("Distribution Methodology", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          "The Net Profit or Loss is distributed among stakeholders strictly based on their share percentage at the time of investment. \n"
                              "Formula: (Stakeholder Share / Total Investment) * Net P/L = Allocated Amount.",
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                        ),
                      ]
                  )
              ),

              pw.SizedBox(height: 20),

              // Final Distribution Table
              pw.Text("Final Profit/Loss Distribution", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),

              pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                        children: [
                          _pdfCell("Stakeholder", isHeader: true),
                          _pdfCell("Share %", isHeader: true),
                          _pdfCell(isProfit ? "Profit Share" : "Loss Share", isHeader: true),
                        ]
                    ),
                    ...invest.userShares.entries.map((entry) {
                      final uid = entry.key;
                      final share = entry.value;
                      final pct = (share / invest.investedAmount);
                      final userPl = pct * invest.actualProfitLoss!;

                      return pw.TableRow(children: [
                        _pdfCell(stakeholderNames[uid] ?? "Unknown"),
                        _pdfCell("${(pct*100).toStringAsFixed(2)}%"),
                        _pdfCell("$currency ${userPl.toStringAsFixed(1)}", color: statusColor),
                      ]);
                    }).toList(),
                  ]
              ),

              pw.Spacer(),
              pw.Divider(),
              pw.Center(child: pw.Text("Generated by Stake & Grow Platform", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey))),
            ];
          },
        ),
      );

      Navigator.pop(context); // Close loading
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());

    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("PDF Error: $e")));
    }
  }

  pw.Widget _pdfCell(String text, {bool isHeader = false, PdfColor? color, bool isBold = false}) {
    return pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(
            text,
            style: pw.TextStyle(
              fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color ?? PdfColors.black,
              fontSize: 12,
            )
        )
    );
  }

  void _showReturnDialog(BuildContext context, WidgetRef ref, InvestmentModel invest) {
    final returnController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Record Investment Return"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Project: ${invest.projectName}", style: const TextStyle(fontWeight: FontWeight.bold)),
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
                Navigator.pop(ctx);
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