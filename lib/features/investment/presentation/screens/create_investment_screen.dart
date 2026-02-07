import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stake_grow/core/common/loader.dart';
import 'package:stake_grow/features/investment/presentation/investment_controller.dart';

class CreateInvestmentScreen extends ConsumerStatefulWidget {
  final String communityId;
  const CreateInvestmentScreen({super.key, required this.communityId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CreateInvestmentScreenState();
}

class _CreateInvestmentScreenState
    extends ConsumerState<CreateInvestmentScreen> {
  final _formKey = GlobalKey<FormState>();
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
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();

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
      backgroundColor: Colors.grey[50], // Modern clean background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Investment Project',
          style: TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: isLoading
          ? const Loader()
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Hero Header Section
              _buildHeaderSection(),
              const SizedBox(height: 32),

              // 2. Project Name Input (High Visibility)
              _buildLabel("PROJECT IDENTIFICATION"),
              _buildTextField(
                controller: titleController,
                hint: "e.g. Poultry Farm, Stock Market, etc.",
                icon: Icons.business_center_rounded,
                validator: (val) => val == null || val.isEmpty
                    ? 'Project name is required'
                    : null,
              ),
              const SizedBox(height: 18),
              _buildTextField(
                controller: detailsController,
                hint: "Provide specific goals and description...",
                icon: Icons.description_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // 3. Financials Hero Card
              _buildLabel("FINANCIAL PROJECTIONS"),
              _buildFinancialCard(),
              const SizedBox(height: 40),

              // 4. Action Button
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
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.15),
                blurRadius: 30,
                spreadRadius: 2,
              )
            ],
          ),
          child: Icon(Icons.rocket_launch_rounded,
              size: 48, color: Colors.orange.shade800),
        ),
        const SizedBox(height: 16),
        const Text(
          "Start a New Venture",
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Text(
          "Track community capital and projected returns.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildFinancialCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text("TOTAL INVESTMENT COST",
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey,
                  letterSpacing: 1.2)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("৳",
                  style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.orange.shade800)),
              const SizedBox(width: 12),
              IntrinsicWidth(
                child: TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  autofocus: true,
                  style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      color: Colors.orange.shade900),
                  decoration: const InputDecoration(
                    hintText: "0.00",
                    hintStyle: TextStyle(color: Colors.black12),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Required';
                    if (double.tryParse(val) == null) return 'Invalid amount';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1),
          ),
          _buildProfitInput(),
        ],
      ),
    );
  }

  Widget _buildProfitInput() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(14)),
          child: Icon(Icons.trending_up_rounded,
              color: Colors.green.shade700, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("EXPECTED PROFIT (ESTIMATED)",
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5)),
              TextFormField(
                controller: profitController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black87),
                decoration: const InputDecoration(
                  hintText: "Optional (৳)",
                  hintStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.grey),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: ElevatedButton(
        onPressed: submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade800,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: const Text(
          'LAUNCH INVESTMENT',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: EdgeInsets.only(bottom: maxLines > 1 ? 45 : 0),
            child: Icon(icon, color: Colors.orange.shade700, size: 22),
          ),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.normal),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(22),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(color: Colors.orange.shade400, width: 2.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
        ),
      ),
    );
  }
}