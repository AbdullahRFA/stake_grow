import 'package:flutter/material.dart';
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
      backgroundColor: Colors.grey[50], // Clean light background
      appBar: AppBar(
        title: Text(
          'New Activity / Expense',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: isLoading
          ? const Loader()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // --- Header Icon ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.receipt_long_rounded, size: 40, color: Colors.redAccent.shade200),
            ),
            const SizedBox(height: 10),
            Text(
              "Record Expense",
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            Text(
              "Track community spending & activities",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // --- Form Card ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Field
                  _buildLabel("Activity Title"),
                  TextField(
                    controller: titleController,
                    style: GoogleFonts.poppins(),
                    decoration: _inputDecoration('e.g. Relief Distribution', Icons.title),
                  ),
                  const SizedBox(height: 16),

                  // Cost Field
                  _buildLabel("Total Cost"),
                  TextField(
                    controller: costController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    decoration: _inputDecoration('0.00', Icons.attach_money, prefixText: '৳ '),
                  ),
                  const SizedBox(height: 16),

                  // Activity Type Dropdown
                  _buildLabel("Category"),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedType,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.redAccent),
                        items: ['Social Work', 'Event', 'Maintenance', 'Other']
                            .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e, style: GoogleFonts.poppins()),
                        ))
                            .toList(),
                        onChanged: (val) => setState(() => selectedType = val!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Details Field
                  _buildLabel("Description (Optional)"),
                  TextField(
                    controller: detailsController,
                    maxLines: 3,
                    style: GoogleFonts.poppins(),
                    decoration: _inputDecoration('Additional details...', Icons.description_outlined),
                  ),
                  const SizedBox(height: 30),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: Colors.redAccent.withOpacity(0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Confirm Expense',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helpers ---

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700]),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon, {String? prefixText}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
      prefixIcon: Icon(icon, color: Colors.redAccent.withOpacity(0.7), size: 20),
      prefixText: prefixText,
      prefixStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black87),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}