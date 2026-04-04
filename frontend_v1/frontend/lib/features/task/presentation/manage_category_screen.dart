import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../data/models/category_model.dart';
import '../controller/category_controller.dart';

class ManageCategoryScreen extends StatefulWidget {
  const ManageCategoryScreen({super.key});

  @override
  State<ManageCategoryScreen> createState() => _ManageCategoryScreenState();
}

class _ManageCategoryScreenState extends State<ManageCategoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryController>().fetchCategories();
    });
  }

  Future<void> _showCreateCategoryDialog() async {
    final textController = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create Category'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'Nhập tên category',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tạo'),
          ),
        ],
      ),
    );

    if (created != true || !mounted) return;

    final name = textController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tên category không được để trống')),
      );
      return;
    }

    final categoryController = context.read<CategoryController>();
    final success = await categoryController.createCategory(name);

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            categoryController.errorMessage ?? 'Tạo category thất bại',
          ),
        ),
      );
    }
  }

  Future<void> _showEditCategoryDialog(CategoryModel category) async {
    final textController = TextEditingController(text: category.name);

    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Category'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'Nhập tên category mới',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (updated != true || !mounted) return;

    final name = textController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tên category không được để trống')),
      );
      return;
    }

    final controller = context.read<CategoryController>();
    final success = await controller.updateCategory(
      categoryId: category.id,
      name: name,
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? 'Sửa category thất bại'),
        ),
      );
    }
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Bạn có chắc muốn xoá "${category.name}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final controller = context.read<CategoryController>();
    final success = await controller.deleteCategory(category.id);

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? 'Xoá category thất bại'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CategoryController>();
    final List<CategoryModel> categories = controller.categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
      ),
      body: Builder(
        builder: (context) {
          if (controller.isLoading) {
            return const AppLoading(message: 'Đang tải category...');
          }

          if (controller.errorMessage != null && categories.isEmpty) {
            return AppErrorState(
              message: controller.errorMessage!,
              onRetry: controller.fetchCategories,
            );
          }

          if (categories.isEmpty) {
            return const AppEmptyState(
              icon: Icons.category_outlined,
              title: 'Chưa có category nào',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final category = categories[index];
              return Card(
                child: ListTile(
                  title: Text(category.name),
                  subtitle: Text('ID: ${category.id}'),
                  onTap: controller.isSubmitting
                      ? null
                      : () => _showEditCategoryDialog(category),
                  trailing: IconButton(
                    onPressed: controller.isSubmitting
                        ? null
                        : () => _deleteCategory(category),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.isSubmitting ? null : _showCreateCategoryDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}