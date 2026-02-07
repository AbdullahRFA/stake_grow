import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stake_grow/core/common/loader.dart';
import 'package:stake_grow/features/activity/presentation/activity_controller.dart';

class CreateActivityScreen extends ConsumerStatefulWidget {
  final String communityId;
  const CreateActivityScreen({super.key, required this.communityId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends ConsumerState<CreateActivityScreen> {
  final titleController = TextEditingController();
  final costController = TextEditingController();
  final detailsController = TextEditingController();
  String selectedType = 'Social Work';

  @override
  void dispose() {
    titleController.dispose();
    costController.dispose();
    detailsController.dispose();
    super.dispose();
  }

  void submit() {
    if (titleController.text.isNotEmpty && costController.text.isNotEmpty) {
      final cost = double.tryParse(costController.text.trim());

      if (cost != null && cost > 0) {
        FocusScope.of(context).unfocus();
        ref.read(activityControllerProvider.notifier).createActivity(
          communityId: widget.communityId,
          title: titleController.text.trim(),
          details: detailsController.text.trim(),
          cost: cost,
          type: selectedType,
          context: context,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid cost greater than 0')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and Cost are required')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(activityControllerProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50], // Modern clean background
      appBar: AppBar(
        title: Text(
          'New Community Activity',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 18),
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
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: Column(
          children: [
            // --- Header Section ---
            _buildHeaderSection(),
            const SizedBox(height: 32),

            // --- Form Card ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Activity Title Field
                  _buildLabel("ACTIVITY IDENTIFICATION"),
                  TextField(
                    controller: titleController,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    decoration: _inputDecoration('e.g. Winter Clothing Drive', Icons.campaign_rounded),
                  ),
                  const SizedBox(height: 20),

                  // Category Selection
                  _buildLabel("ACTIVITY CATEGORY"),
                  _buildCategoryDropdown(),
                  const SizedBox(height: 24),

                  // Hero Cost Card
                  _buildLabel("FINANCIAL IMPACT"),
                  _buildCostInputCard(),
                  const SizedBox(height: 24),

                  // Description Field
                  _buildLabel("LOGISTICS & DETAILS (OPTIONAL)"),
                  TextField(
                    controller: detailsController,
                    maxLines: 3,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: _inputDecoration('Mention venue, purpose, or items bought...', Icons.segment_rounded),
                  ),
                  const SizedBox(height: 40),

                  // Submit Button
                  _buildSubmitButton(),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
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
                color: Colors.redAccent.withOpacity(0.15),
                blurRadius: 30,
                spreadRadius: 2,
              )
            ],
          ),
          child: Icon(Icons.receipt_long_rounded, size: 48, color: Colors.redAccent.shade200),
        ),
        const SizedBox(height: 16),
        Text(
          "Record Community Expense",
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        Text(
          "Maintain transparency in community spending",
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildCostInputCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.02),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.redAccent.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        children: [
          Text("TOTAL COST", style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.redAccent, letterSpacing: 1.2)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("৳", style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.redAccent)),
              const SizedBox(width: 12),
              IntrinsicWidth(
                child: TextField(
                  controller: costController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.black87),
                  decoration: const InputDecoration(
                    hintText: "0.00",
                    hintStyle: TextStyle(color: Colors.black12),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  inputFormatters: [LengthLimitingTextInputFormatter(8)],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200, width: 2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedType,
          isExpanded: true,
          icon: const Icon(Icons.expand_more_rounded, color: Colors.redAccent),
          style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 15),
          items: ['Social Work', 'Event', 'Maintenance', 'Other']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) => setState(() => selectedType = val!),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.redAccent.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: ElevatedButton(
        onPressed: submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        child: Text(
          'PUBLISH ACTIVITY',
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1.2),
        ),
      ),
    );
  }

  // --- Helpers ---

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: Colors.blueGrey),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontWeight: FontWeight.normal, fontSize: 14),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: Icon(icon, color: Colors.redAccent.withOpacity(0.8), size: 22),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.all(20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2.5),
      ),
    );
  }
}