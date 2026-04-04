import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../data/models/category_model.dart';
import '../../../data/models/task_model.dart';
import '../controller/category_controller.dart';
import '../controller/task_controller.dart';
import '../controller/task_form_controller.dart';

class EditTaskScreen extends StatefulWidget {
  final TaskModel task;

  const EditTaskScreen({
    super.key,
    required this.task,
  });

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;

  late String selectedPriority;
  late String selectedStatus;
  DateTime? selectedDueDate;
  int? selectedCategoryId;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(text: widget.task.title);
    descriptionController = TextEditingController(
      text: widget.task.description ?? '',
    );

    selectedPriority = widget.task.priority.name.toUpperCase();
    selectedStatus = widget.task.status.name.toUpperCase();
    selectedDueDate = widget.task.dueDate;
    selectedCategoryId = widget.task.categoryId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryController>().fetchCategories();
    });
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDueDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title không được để trống')),
      );
      return;
    }

    final formController = context.read<TaskFormController>();

    final success = await formController.updateTask(
      taskId: widget.task.id,
      title: titleController.text.trim(),
      description: descriptionController.text.trim().isEmpty
          ? null
          : descriptionController.text.trim(),
      priority: selectedPriority,
      status: selectedStatus,
      dueDate: selectedDueDate?.toIso8601String(),
      categoryId: selectedCategoryId,
    );

    if (!mounted) return;

    if (success) {
      await context.read<TaskController>().fetchTasks();
      if (!mounted) return;
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(formController.errorMessage ?? 'Cập nhật task thất bại'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formController = context.watch<TaskFormController>();
    final categoryController = context.watch<CategoryController>();
    final List<CategoryModel> categories = categoryController.categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Task'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Description',
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: selectedPriority,
            decoration: const InputDecoration(
              labelText: 'Priority',
            ),
            items: const [
              DropdownMenuItem(value: 'LOW', child: Text('Low')),
              DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
              DropdownMenuItem(value: 'HIGH', child: Text('High')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedPriority = value;
                });
              }
            },
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: selectedStatus,
            decoration: const InputDecoration(
              labelText: 'Status',
            ),
            items: const [
              DropdownMenuItem(value: 'TODO', child: Text('To-do')),
              DropdownMenuItem(value: 'DOING', child: Text('Doing')),
              DropdownMenuItem(value: 'DONE', child: Text('Done')),
              DropdownMenuItem(value: 'OVERDUE', child: Text('Overdue')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedStatus = value;
                });
              }
            },
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<int>(
            initialValue: selectedCategoryId,
            decoration: const InputDecoration(
              labelText: 'Category',
            ),
            items: categories
                .map(
                  (category) => DropdownMenuItem<int>(
                    value: category.id,
                    child: Text(category.name),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedCategoryId = value;
              });
            },
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: _pickDueDate,
            child: Text(
              selectedDueDate == null
                  ? 'Choose due date'
                  : DateFormat('dd/MM/yyyy').format(selectedDueDate!),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: formController.isLoading ? null : _submit,
            child: formController.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}