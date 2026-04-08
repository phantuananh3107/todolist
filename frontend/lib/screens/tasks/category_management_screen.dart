import 'package:flutter/material.dart';

import '../../models/category_item.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_refresh_bus.dart';
import '../../utils/auth_navigation.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/section_card.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key, required this.categories});

  final List<CategoryItem> categories;

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  static const _palette = [
    '#FF5C54',
    '#3B82F6',
    '#22C55E',
    '#F97316',
    '#A855F7',
  ];

  late List<CategoryItem> _categories;
  bool _saving = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _categories = widget.categories.where((e) => e.name != 'All').toList();
  }

  Future<Map<String, String>?> _showCategoryDialog({CategoryItem? item}) async {
    final controller = TextEditingController(text: item?.name ?? '');
    String selected = item?.colorHex ?? _palette.first;
    return showDialog<Map<String, String>>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titlePadding: const EdgeInsets.fromLTRB(24, 22, 16, 6),
        title: Row(
          children: [
            Expanded(child: Text(item == null ? 'Add New Category' : 'Edit Category')),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setModalState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Category Name', hintText: 'e.g. Personal, Work, Shopping'),
              ),
              const SizedBox(height: 18),
              Text('Color Tag', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: _palette
                    .map((hex) => GestureDetector(
                          onTap: () => setModalState(() => selected = hex),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: _hex(hex),
                              shape: BoxShape.circle,
                              border: Border.all(color: selected == hex ? Colors.white : Colors.transparent, width: 3),
                              boxShadow: [BoxShadow(color: _hex(hex).withOpacity(.24), blurRadius: 10)],
                            ),
                            child: selected == hex
                                ? Container(
                                    margin: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primary, width: 2)),
                                  )
                                : null,
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, {'name': controller.text.trim(), 'colorHex': selected}),
              child: Text(item == null ? 'Save Category' : 'Update Category'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createCategory() async {
    final data = await _showCategoryDialog();
    if (data == null || (data['name'] ?? '').isEmpty) return;
    setState(() => _saving = true);
    try {
      final category = await ApiService.createCategory(data['name']!, colorHex: data['colorHex']);
      if (!mounted) return;
      setState(() {
        _categories = [..._categories, category];
        _dirty = true;
      });
      AppRefreshBus.bumpCategories();
    } catch (e) {
      if (ApiService.isUnauthorized(e)) {
        if (!mounted) return;
        await handleUnauthorized(context);
        return;
      }
      if (!mounted) return;
      final demo = CategoryItem(id: DateTime.now().millisecondsSinceEpoch, name: data['name']!, taskCount: 0, colorHex: data['colorHex']);
      setState(() {
        _categories = [..._categories, demo];
        _dirty = true;
      });
      AppRefreshBus.bumpCategories();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editCategory(CategoryItem item) async {
    final data = await _showCategoryDialog(item: item);
    if (data == null || (data['name'] ?? '').isEmpty) return;
    final updated = item.copyWith(name: data['name'], colorHex: data['colorHex']);
    final previous = List<CategoryItem>.from(_categories);
    setState(() {
      _categories = _categories.map((e) => e.id == item.id ? updated : e).toList();
      _dirty = true;
    });
    try {
      await ApiService.updateCategory(item.id, updated.name, colorHex: updated.colorHex, previousName: item.name);
      AppRefreshBus.bumpCategories();
    } catch (e) {
      if (ApiService.isUnauthorized(e)) {
        if (!mounted) return;
        await handleUnauthorized(context);
        return;
      }
      if (!mounted) return;
      setState(() => _categories = previous);
    }
  }

  Future<void> _deleteCategory(CategoryItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Xóa "${item.name}" khỏi danh sách?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (confirm != true) return;
    final previous = List<CategoryItem>.from(_categories);
    setState(() {
      _categories = _categories.where((e) => e.id != item.id).toList();
      _dirty = true;
    });
    try {
      await ApiService.deleteCategory(item.id, name: item.name);
      AppRefreshBus.bumpCategories();
    } catch (e) {
      if (ApiService.isUnauthorized(e)) {
        if (!mounted) return;
        await handleUnauthorized(context);
        return;
      }
      if (!mounted) return;
      setState(() => _categories = previous);
    }
  }

  Color _hex(String? hex) {
    final value = (hex ?? '').replaceAll('#', '');
    if (value.length != 6) return AppColors.primary;
    return Color(int.parse('FF$value', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_dirty);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Manage Categories')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _saving ? null : _createCategory,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add New Category'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            const ScreenHeader(title: 'Manage Categories', subtitle: 'Danh mục công việc', icon: Icons.folder_open_rounded),
            const SizedBox(height: 16),
            if (_categories.isEmpty)
              const EmptyStateCard(icon: Icons.folder_off_rounded, title: 'Chưa có category', message: 'Thêm category để sắp xếp công việc.')
            else
              ..._categories.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SectionCard(
                      child: Row(
                        children: [
                          Container(width: 16, height: 16, decoration: BoxDecoration(color: _hex(item.colorHex), shape: BoxShape.circle)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 4),
                                Text('${item.taskCount} tasks', style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                          IconButton(onPressed: () => _editCategory(item), icon: const Icon(Icons.edit_outlined)),
                          IconButton(onPressed: () => _deleteCategory(item), icon: const Icon(Icons.delete_outline_rounded)),
                        ],
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
//