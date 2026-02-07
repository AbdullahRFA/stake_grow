import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stake_grow/core/common/loader.dart';
import 'package:stake_grow/features/loan/presentation/loan_controller.dart';

class CreateLoanScreen extends ConsumerStatefulWidget {
  final String communityId;
  const CreateLoanScreen({super.key, required this.communityId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CreateLoanScreenState();
}

class _CreateLoanScreenState extends ConsumerState<CreateLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final reasonController = TextEditingController();
  DateTime? selectedDate;

  @override
  void dispose() {
    amountController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  void pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)), // 2 Years max
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.teal.shade700,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  void submitRequest() {
    if (_formKey.currentState!.validate()) {
      if (selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a repayment deadline')),
        );
        return;
      }

      final amount = double.tryParse(amountController.text.trim());

      if (amount != null && amount > 0) {
        FocusScope.of(context).unfocus();

        ref.read(loanControllerProvider.notifier).requestLoan(
          communityId: widget.communityId,
          amount: amount,
          reason: reasonController.text.trim(),
          repaymentDate: selectedDate!,
          context: context,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(loanControllerProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50], // Modern clean background
      appBar: AppBar(
        title: const Text(
          'Request Community Loan',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Loader()
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Decorative Header Section
              _buildHeaderSection(),
              const SizedBox(height: 32),

              // 2. High-Contrast Amount Input Section
              _buildLabel("HOW MUCH DO YOU NEED?"),
              _buildAmountInputCard(),
              const SizedBox(height: 32),

              // 3. Purpose/Reason Input (High Visibility)
              _buildLabel("PURPOSE OF LOAN"),
              TextFormField(
                controller: reasonController,
                maxLines: 3,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                decoration: _inputDecoration(
                  hint: "E.g. Medical emergency, Educational fees, or Small business capital...",
                  icon: Icons.edit_document,
                ),
                validator: (val) => val == null || val.isEmpty ? 'Purpose is required' : null,
              ),
              const SizedBox(height: 28),

              // 4. Interactive Deadline Card
              _buildLabel("REPAYMENT DEADLINE"),
              _buildDatePickerCard(),
              const SizedBox(height: 32),

              // 5. Compliance/Rules Box
              _buildPenaltyNoticeCard(),
              const SizedBox(height: 40),

              // 6. Action Button
              _buildSubmitButton(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Component Builders ---

  Widget _buildHeaderSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withOpacity(0.1),
                blurRadius: 30,
                spreadRadius: 2,
              )
            ],
          ),
          child: Hero(
            tag: 'loan_icon',
            child: Icon(Icons.handshake_rounded, size: 48, color: Colors.teal.shade700),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "Community Financial Support",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 0.5),
        ),
      ],
    );
  }

  Widget _buildAmountInputCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.teal.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("৳", style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Colors.teal.shade800)),
          const SizedBox(width: 12),
          IntrinsicWidth(
            child: TextFormField(
              controller: amountController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              autofocus: true,
              style: TextStyle(fontSize: 46, fontWeight: FontWeight.w900, color: Colors.teal.shade900),
              decoration: const InputDecoration(
                hintText: "0.00",
                hintStyle: TextStyle(color: Colors.black12),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              inputFormatters: [LengthLimitingTextInputFormatter(7)],
              validator: (val) {
                if (val == null || val.isEmpty) return 'Required';
                if (double.tryParse(val) == null || double.parse(val) <= 0) return 'Invalid amount';
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerCard() {
    return InkWell(
      onTap: pickDate,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey.shade200, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.calendar_month_rounded, color: Colors.blue.shade700, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedDate == null ? "Select deadline..." : DateFormat('EEEE, dd MMM yyyy').format(selectedDate!),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: selectedDate == null ? Colors.grey.shade400 : Colors.black87,
                    ),
                  ),
                  if (selectedDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "Must repay within ${selectedDate!.difference(DateTime.now()).inDays + 1} days",
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade800, fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildPenaltyNoticeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50.withOpacity(0.8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.red.shade100, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.privacy_tip_rounded, size: 20, color: Colors.red.shade800),
              const SizedBox(width: 10),
              Text("LOAN REPAYMENT POLICY", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.red.shade900, fontSize: 13, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 14),
          _buildRuleItem("1-5 Days Late", "5% Penalty added to principal."),
          _buildRuleItem("6-10 Days Late", "10% Penalty added to principal."),
          const Padding(
            padding: EdgeInsets.only(top: 10, left: 24),
            child: Text(
              "▶ After 10 days, local committee rules apply.",
              style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: ElevatedButton(
        onPressed: submitRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: const Text('SUBMIT LOAN REQUEST', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
      ),
    );
  }

  // --- Helper Methods ---

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.blueGrey),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.normal),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(bottom: 45), // Adjust icon for multiline
        child: Icon(icon, color: Colors.teal.shade700, size: 22),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.all(22),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(color: Colors.teal.shade400, width: 2.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  Widget _buildRuleItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 16, color: Colors.red.shade400),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.4),
                children: [
                  TextSpan(text: "$title: ", style: const TextStyle(fontWeight: FontWeight.w900)),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}