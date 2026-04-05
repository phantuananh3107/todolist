import 'package:flutter/material.dart';
import '../../models/category_item.dart';
import '../../services/api_service.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  List<CategoryItem> categories = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final fetchedCategories = await ApiService.fetchCategories();
      if (!mounted) return;
      setState(() {
        categories = fetchedCategories.where((c) => c.name != 'All').toList();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Color hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    bool saving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Category Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Personal, Work, Shopping',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving ? null : () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter name')));
                  return;
                }
                setState(() => saving = true);
                try {
                  await ApiService.createCategory(name);
                  if (!mounted) return;
                  Navigator.pop(context);
                  _load();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category created')));
                } catch (e) {
                  if (!mounted) return;
                  setState(() => saving = false);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
                }
              },
              child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _editCategory(int categoryId, String currentName) {
    final nameController = TextEditingController(text: currentName);
    bool saving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Category Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving ? null : () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter name')));
                  return;
                }
                setState(() => saving = true);
                try {
                  await ApiService.updateCategory(categoryId, name);
                  if (!mounted) return;
                  Navigator.pop(context);
                  _load();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category updated')));
                } catch (e) {
                  if (!mounted) return;
                  setState(() => saving = false);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
                }
              },
              child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteCategory(int categoryId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ApiService.deleteCategory(categoryId);
                if (!mounted) return;
                _load();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category deleted')));
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories'), elevation: 0),
      body: loading
        ? const Center(child: CircularProgressIndicator())
        : categories.isEmpty
          ? const Center(child: Text('No categories yet'))
          : ListView.builder(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
            itemCount: categories.length,
            itemBuilder: (_, i) {
              final cat = categories[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: hexToColor(cat.color), shape: BoxShape.circle)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          Text('${cat.taskCount} tasks', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey), onPressed: () => _editCategory(cat.id, cat.name)),
                    IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), onPressed: () => _deleteCategory(cat.id)),
                  ],
                ),
              );
            },
          ),
      bottomSheet: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: ElevatedButton(
            onPressed: _showAddCategoryDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 20, color: Colors.white),
                SizedBox(width: 8),
                Text('Add New Category', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

