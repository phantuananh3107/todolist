import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/auth_navigation.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/section_card.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final stats = await ApiService.fetchAdminStats();
      final categories = <Map<String, dynamic>>[];
      for (final user in stats) {
        for (final category in (user['categories'] as List<dynamic>? ?? const [])) {
          final cat = Map<String, dynamic>.from(category as Map);
          cat['username'] = user['username'];
          cat['email'] = user['email'];
          categories.add(cat);
        }
      }
      categories.sort((a,b) => ((b['taskCount'] ?? 0) as num).compareTo((a['taskCount'] ?? 0) as num));
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _loading = false;
      });
    } catch (e) {
      if (ApiService.isUnauthorized(e)) {
        if (!mounted) return;
        await handleUnauthorized(context);
        return;
      }
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không tải được danh sách category.')));
    }
  }

  void _openCategory(Map<String, dynamic> category) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => _CategoryDetailScreen(category: category, onChanged: _load)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            const ScreenHeader(eyebrow: 'Admin', title: 'Category Library', subtitle: 'Xem chi tiết và xóa mềm category của toàn hệ thống.', icon: Icons.category_rounded),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(padding: EdgeInsets.symmetric(vertical: 80), child: Center(child: CircularProgressIndicator()))
            else if (_categories.isEmpty)
              const EmptyStateCard(icon: Icons.category_outlined, title: 'Chưa có category', message: 'Khi người dùng tạo category, danh sách sẽ hiện tại đây.')
            else
              ..._categories.map((category) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SectionCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => _openCategory(category),
                    leading: CircleAvatar(backgroundColor: const Color(0xFFFFECE8), child: Text(((category['name'] ?? 'C').toString()).substring(0,1).toUpperCase(), style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w800))),
                    title: Text((category['name'] ?? '').toString()),
                    subtitle: Text('${category['username'] ?? ''} • ${(category['taskCount'] ?? 0).toString()} task'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }
}

class _CategoryDetailScreen extends StatelessWidget {
  const _CategoryDetailScreen({required this.category, required this.onChanged});
  final Map<String, dynamic> category;
  final Future<void> Function() onChanged;

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Xóa mềm category?'),
        content: Text('Category "${(category['name'] ?? '').toString()}" và các task liên quan sẽ bị vô hiệu hóa.'),
        actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hủy')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Xóa'))],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      final idRaw = category['id'];
      final id = idRaw is int ? idRaw : int.tryParse(idRaw.toString());
      if (id == null) throw Exception('Thiếu id category');
      await ApiService.softDeleteCategoryAdmin(id);
      await onChanged();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa mềm category.')));
      Navigator.pop(context);
    } catch (e) {
      if (ApiService.isUnauthorized(e)) {
        await handleUnauthorized(context);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể xóa category.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = (category['tasks'] as List<dynamic>? ?? const []).cast<Map<String,dynamic>>();
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết category')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SectionCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text((category['name'] ?? '').toString(), style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              _InfoRow(label: 'Người tạo', value: (category['username'] ?? '').toString()),
              _InfoRow(label: 'Email', value: (category['email'] ?? '').toString()),
              _InfoRow(label: 'Số task', value: (category['taskCount'] ?? 0).toString()),
            ]),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Task trong category', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              if (tasks.isEmpty)
                const Text('Chưa có task nào.')
              else
                ...tasks.map((task) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    const Icon(Icons.task_alt_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Text((task['title'] ?? '').toString())),
                    Text((task['status'] ?? '').toString(), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.subText)),
                  ]),
                )),
            ]),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => _delete(context),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Xóa category'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label; final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      SizedBox(width: 110, child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.subText))),
      Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
    ]),
  );
}
