import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/app_button.dart';
import '../../controller/reminder_controller.dart';

class ReminderBottomSheet extends StatefulWidget {
  final int taskId;
  final DateTime? initialDateTime;
  final VoidCallback? onSaved;

  const ReminderBottomSheet({
    super.key,
    required this.taskId,
    this.initialDateTime,
    this.onSaved,
  });

  @override
  State<ReminderBottomSheet> createState() => _ReminderBottomSheetState();
}

class _ReminderBottomSheetState extends State<ReminderBottomSheet> {
  DateTime? selectedDateTime;

  @override
  void initState() {
    super.initState();
    selectedDateTime = widget.initialDateTime;
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDateTime ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: DateTime(now.year + 5),
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedDateTime ?? now),
    );

    if (pickedTime == null) return;

    setState(() {
      selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _saveReminder() async {
    if (selectedDateTime == null) return;

    final controller = context.read<ReminderController>();
    final success = await controller.createReminder(
      taskId: widget.taskId,
      remindTime: selectedDateTime!,
    );

    if (!mounted) return;

    if (success) {
      widget.onSaved?.call();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? 'Lưu reminder thất bại'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReminderController>();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Wrap(
        children: [
          const Text(
            'Set Reminder',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _pickDateTime,
            child: Text(
              selectedDateTime == null
                  ? 'Choose reminder time'
                  : DateFormat('HH:mm - dd/MM/yyyy').format(selectedDateTime!),
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            text: 'Save Reminder',
            isLoading: controller.isSubmitting,
            icon: Icons.notifications_active_outlined,
            onPressed: selectedDateTime == null ? null : _saveReminder,
          ),
        ],
      ),
    );
  }
}