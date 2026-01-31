import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(activityControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Activity / Expense')),
      body: isLoading
          ? const Loader()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Activity Title',
                hintText: 'e.g. Relief Distribution',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: costController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Cost',
                prefixText: '৳ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: const InputDecoration(
                labelText: 'Activity Type',
                border: OutlineInputBorder(),
              ),
              items: ['Social Work', 'Event', 'Maintenance', 'Other']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => selectedType = val!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: detailsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Details / Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent, // খরচের জন্য লালচে ভাব
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(15),
                ),
                child: const Text('Confirm Expense'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}