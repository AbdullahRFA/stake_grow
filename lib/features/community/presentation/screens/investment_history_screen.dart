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

    // Theme Colors
    final primaryColor = Theme.of(context).primaryColor;
    final backgroundColor = Colors.grey[100];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: investmentsAsync.when(
        loading: () => const Loader(),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (investments) {
          return communityAsync.when(
            loading: () => const Loader(),
            error: (e, s) => Center(child: Text('Error loading community info: $e')),
            data: (community) {
              final isAdmin = currentUser != null && currentUser.uid == community.adminId;

              if (investments.isEmpty) {
                return _buildEmptyState();
              }

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 120.0,
                    floating: true,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      title: const Text(
                        'Portfolio & Investments',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.teal.shade700, Colors.teal.shade400],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(12),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final invest = investments[index];
                          return _buildInvestmentCard(context, ref, invest, isAdmin, currentUser);
                        },
                        childCount: investments.length,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.monetization_on_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No investments yet',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a new project to see it here.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentCard(BuildContext context, WidgetRef ref, InvestmentModel invest, bool isAdmin, User? currentUser) {
    final isActive = invest.status == 'active';

    // Calculations
    double myShare = 0.0;
    if (currentUser != null && invest.userShares.containsKey(currentUser.uid)) {
      myShare = invest.userShares[currentUser.uid]!;
    }
    double mySharePct = invest.investedAmount == 0 ? 0 : (myShare / invest.investedAmount) * 100;
    double myProfitLoss = 0.0;
    if (!isActive && invest.actualProfitLoss != null) {
      myProfitLoss = (mySharePct / 100) * invest.actualProfitLoss!;
    }
    final isProfit = myProfitLoss >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // 1. Header with Status and Admin Menu
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
            decoration: BoxDecoration(
              color: isActive ? Colors.orange.shade50 : (isProfit ? Colors.green.shade50 : Colors.red.shade50),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                  ),
                  child: Icon(
                    isActive ? Icons.hourglass_top_rounded : (isProfit ? Icons.check_circle_outline : Icons.trending_down),
                    color: isActive ? Colors.orange : (isProfit ? Colors.green : Colors.red),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invest.projectName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        invest.details,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.orange : (isProfit ? Colors.green : Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isActive ? 'RUNNING' : 'CLOSED',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                // Admin Actions
                if (isActive && isAdmin)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (value) {
                      if (value == 'return') {
                        _showReturnDialog(context, ref, invest);
                      } else if (value == 'edit') {
                        _showEditDialog(context, ref, invest);
                      } else if (value == 'delete') {
                        _showDeleteConfirmDialog(context, ref, invest);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      _buildPopupItem('return', Icons.input, 'Record Return', Colors.blue),
                      _buildPopupItem('edit', Icons.edit, 'Edit Details', Colors.orange),
                      _buildPopupItem('delete', Icons.delete, 'Delete & Refund', Colors.red),
                    ],
                  ),
              ],
            ),
          ),

          // 2. Project Stats Grid
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildStatColumn('Invested', "৳${NumberFormat.compact().format(invest.investedAmount)}", Icons.account_balance_wallet, Colors.blueGrey),
                    const SizedBox(width: 16),
                    _buildStatColumn(
                        isActive ? 'Exp. Profit' : 'Net P/L',
                        isActive ? "৳${NumberFormat.compact().format(invest.expectedProfit)}" : "৳${NumberFormat.compact().format(invest.actualProfitLoss)}",
                        Icons.insights,
                        isActive ? Colors.orange : (invest.actualProfitLoss! >= 0 ? Colors.green : Colors.red)
                    ),
                    const SizedBox(width: 16),
                    _buildStatColumn('Start Date', DateFormat('dd MMM').format(invest.startDate), Icons.calendar_today, Colors.grey),
                  ],
                ),
                if (!isActive && invest.endDate != null) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 24, thickness: 1, color: Colors.black12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Total Returned", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      Text("৳${invest.returnAmount}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14)),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // 3. "My Stake" Personal Dashboard
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("MY STAKE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal, letterSpacing: 1.0)),
                    Text("${mySharePct.toStringAsFixed(1)}% Ownership", style: const TextStyle(fontSize: 11, color: Colors.teal)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Contribution", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text("৳${myShare.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    if (!isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isProfit ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(isProfit ? "My Profit" : "My Loss", style: TextStyle(fontSize: 10, color: isProfit ? Colors.green : Colors.red)),
                            Text(
                              "${isProfit ? '+' : ''}৳${myProfitLoss.toStringAsFixed(0)}",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isProfit ? Colors.green : Colors.red),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // 4. Footer Action (Download PDF)
          if (!isActive)
            InkWell(
              onTap: () => _generatePdf(context, ref, invest),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined, size: 18, color: Colors.teal),
                    const SizedBox(width: 8),
                    const Text("Download Report", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            )
          else
            const SizedBox(height: 8), // Bottom spacer for active cards
        ],
      ),
    );
  }

  // Helper for Stats
  Widget _buildStatColumn(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // Helper for Popup Menu
  PopupMenuItem<String> _buildPopupItem(String value, IconData icon, String text, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  // ✅ New: Show Edit Dialog (Functionality Unchanged, UI Polished)
  void _showEditDialog(BuildContext context, WidgetRef ref, InvestmentModel invest) {
    final titleController = TextEditingController(text: invest.projectName);
    final detailsController = TextEditingController(text: invest.details);
    final profitController = TextEditingController(text: invest.expectedProfit.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Edit Investment"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Project Name", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: profitController, decoration: const InputDecoration(labelText: "Expected Profit (৳)", border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(controller: detailsController, decoration: const InputDecoration(labelText: "Details", border: OutlineInputBorder()), maxLines: 2),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Text(
                "⚠️ Investment Amount cannot be changed to ensure share accuracy.",
                style: TextStyle(fontSize: 11, color: Colors.amber, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: () {
              final updatedInvest = InvestmentModel(
                id: invest.id,
                communityId: invest.communityId,
                projectName: titleController.text.trim(),
                details: detailsController.text.trim(),
                investedAmount: invest.investedAmount,
                expectedProfit: double.tryParse(profitController.text) ?? invest.expectedProfit,
                status: invest.status,
                startDate: invest.startDate,
                userShares: invest.userShares,
                returnAmount: invest.returnAmount,
                actualProfitLoss: invest.actualProfitLoss,
                endDate: invest.endDate,
              );
              ref.read(investmentControllerProvider.notifier).updateInvestment(investment: updatedInvest, context: context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  // ✅ New: Show Delete Confirmation
  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref, InvestmentModel invest) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Investment?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Are you sure you want to delete '${invest.projectName}'?"),
            const SizedBox(height: 10),
            Text(
              "This will refund ৳${invest.investedAmount} back to the Community Fund.",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(investmentControllerProvider.notifier).deleteInvestment(
                  communityId: invest.communityId,
                  investmentId: invest.id,
                  context: context
              );
              Navigator.pop(ctx);
            },
            child: const Text("Delete & Refund"),
          ),
        ],
      ),
    );
  }

  // ✅ PDF Generation Logic (Kept same as before)
  void _generatePdf(BuildContext context, WidgetRef ref, InvestmentModel invest) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    try {
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.nunitoExtraLight();

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

              pw.Text("Executive Summary", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Text("Project Name: ${invest.projectName}"),
              pw.Text("Description: ${invest.details}"),
              pw.Text("Status: ${invest.status.toUpperCase()}"),
              pw.Text("Duration: ${DateFormat('dd MMM yyyy').format(invest.startDate)} - ${DateFormat('dd MMM yyyy').format(invest.endDate!)}"),

              pw.SizedBox(height: 20),

              pw.Text("Initial Contribution Breakdown", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text("Total Invested Capital: $currency ${invest.investedAmount}", style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
              pw.SizedBox(height: 5),

              pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                        children: [
                          _pdfCell("Stakeholder Name", isHeader: true),
                          _pdfCell("Contributed Amount", isHeader: true),
                          _pdfCell("Ownership %", isHeader: true),
                        ]
                    ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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