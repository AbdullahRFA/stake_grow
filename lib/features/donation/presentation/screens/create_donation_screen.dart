import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stake_grow/core/common/loader.dart';
import 'package:stake_grow/features/community/presentation/transaction_providers.dart';
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
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CreateDonationScreenState();
}

class _CreateDonationScreenState extends ConsumerState<CreateDonationScreen> {
  final amountController = TextEditingController();
  final trxIdController = TextEditingController();
  final phoneController = TextEditingController();

  String selectedType = 'Random';
  String selectedPaymentMethod = 'Manual (Cash)';

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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Amount cannot be empty')));
      return;
    }

    if (selectedPaymentMethod != 'Manual (Cash)') {
      if (trxIdController.text.trim().isEmpty ||
          phoneController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Transaction ID and Phone Number are required for online payment')),
        );
        return;
      }
    }

    final amount = double.tryParse(amountController.text.trim());
    if (amount != null && amount > 0) {
      // Hide keyboard
      FocusScope.of(context).unfocus();

      ref.read(donationControllerProvider.notifier).makeDonation(
        communityId: widget.communityId,
        amount: amount,
        type: selectedType,
        paymentMethod: selectedPaymentMethod,
        transactionId: selectedPaymentMethod != 'Manual (Cash)'
            ? trxIdController.text.trim()
            : null,
        phoneNumber: selectedPaymentMethod != 'Manual (Cash)'
            ? phoneController.text.trim()
            : null,
        context: context,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid amount greater than 0')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(donationControllerProvider);
    final communityAsync =
    ref.watch(communityDetailsProvider(widget.communityId));
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Make a Deposit',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: isLoading
          ? const Loader()
          : communityAsync.when(
        loading: () => const Loader(),
        error: (e, s) => Center(child: Text("Error: $e")),
        data: (community) {
          // Logic: Check Fixed Subscription
          double fixedAmount = 0.0;
          bool isFixed = false;

          if (user != null &&
              community.monthlySubscriptions.containsKey(user.uid)) {
            fixedAmount = community.monthlySubscriptions[user.uid]!;
            if (fixedAmount > 0) isFixed = true;
          }

          // Auto-fill amount if Monthly & Fixed
          if (selectedType == 'Monthly' && isFixed) {
            amountController.text = fixedAmount.toStringAsFixed(0);
          }

          // If switching back to Random, allow editing (clearing is UX preference, keeping existing value is safer)
          // We handle the readOnly state in the widget tree.

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Amount Card
                _buildAmountSection(isFixed),

                const SizedBox(height: 24),

                // 2. Deposit Type Selector
                const Text("Deposit Type",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
                const SizedBox(height: 10),
                _buildTypeSelector(),

                // Warnings / Info Banners
                if (widget.isMonthlyDisabled)
                  _buildInfoBanner(
                      "Monthly deposit completed for this month. You can still make random deposits.",
                      Colors.green),

                if (selectedType == 'Monthly' && !isFixed)
                  _buildInfoBanner(
                      "Tip: Set a fixed monthly amount in Settings for faster deposits.",
                      Colors.orange),

                const SizedBox(height: 24),

                // 3. Payment Method Selector
                const Text("Payment Method",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
                const SizedBox(height: 10),
                _buildPaymentMethodGrid(),

                // 4. Payment Details (Conditional)
                if (selectedPaymentMethod != 'Manual (Cash)') ...[
                  const SizedBox(height: 24),
                  const Text("Transaction Details",
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey)),
                  const SizedBox(height: 10),
                  _buildPaymentDetailsForm(),
                ],

                const SizedBox(height: 30),

                // 5. Confirm Button
                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: deposit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Confirm Deposit',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Widget Builders ---

  Widget _buildAmountSection(bool isFixed) {
    final bool isLocked = (selectedType == 'Monthly' && isFixed);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
        border: isLocked ? Border.all(color: Colors.teal.withOpacity(0.5)) : null,
      ),
      child: Column(
        children: [
          Text(
            isLocked ? "Fixed Monthly Amount" : "Enter Amount",
            style: TextStyle(
                fontSize: 12,
                color: isLocked ? Colors.teal : Colors.grey[600],
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text("৳",
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal)),
              const SizedBox(width: 8),
              IntrinsicWidth(
                child: TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  readOnly: isLocked,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "0",
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(7), // Max 9,999,999
                  ],
                ),
              ),
            ],
          ),
          if (isLocked)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, size: 12, color: Colors.teal),
                  SizedBox(width: 4),
                  Text("Locked by subscription",
                      style: TextStyle(fontSize: 10, color: Colors.teal)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (!widget.isMonthlyDisabled)
            Expanded(
              child: _buildTypeButton("Monthly", selectedType == 'Monthly'),
            ),
          Expanded(
            child: _buildTypeButton("Random", selectedType == 'Random'),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String type, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedType = type;
          // Clear text if switching to Random so user can input fresh
          if (type == 'Random') amountController.clear();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
              : [],
        ),
        child: Center(
          child: Text(
            type,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.black : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodGrid() {
    final methods = [
      {'name': 'Bkash', 'color': Colors.pink},
      {'name': 'Nagad', 'color': Colors.orange},
      {'name': 'Rocket', 'color': Colors.purple},
      {'name': 'Manual (Cash)', 'color': Colors.green},
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: methods.map((m) {
        final name = m['name'] as String;
        final color = m['color'] as Color;
        final isSelected = selectedPaymentMethod == name;

        return InkWell(
          onTap: () => setState(() => selectedPaymentMethod = name),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: (MediaQuery.of(context).size.width - 50) / 2, // 2 cols
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isSelected ? color : Colors.grey.shade200, width: 2),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: color.withOpacity(0.2),
                  child: Icon(
                    name.contains('Cash')
                        ? Icons.money
                        : Icons.account_balance_wallet,
                    size: 16,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name.replaceAll("Manual ", ""), // Shorten text
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, size: 16, color: color),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentDetailsForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          _buildTextField(
            controller: phoneController,
            label: "Sender Number",
            icon: Icons.phone_android_rounded,
            hint: "e.g. 017xxxxxxxx",
            isPhone: true,
          ),
          const Divider(height: 24),
          _buildTextField(
            controller: trxIdController,
            label: "Transaction ID (TrxID)",
            icon: Icons.receipt_long_rounded,
            hint: "Copy from SMS/App",
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
        required String label,
        required IconData icon,
        required String hint,
        bool isPhone = false}) {
    return TextField(
      controller: controller,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.grey),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        isDense: true,
      ),
    );
  }

  Widget _buildInfoBanner(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: color.withOpacity(0.9), fontSize: 12, height: 1.4)),
          ),
        ],
      ),
    );
  }
}