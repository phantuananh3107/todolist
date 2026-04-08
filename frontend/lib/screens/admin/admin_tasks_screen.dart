import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/auth_navigation.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/section_card.dart';

class AdminTasksScreen extends StatefulWidget {
  const AdminTasksScreen({super.key});

  @override
  State<AdminTasksScreen> createState() => _AdminTasksScreenState();
}

class _AdminTasksScreenState extends State<AdminTasksScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _tasks = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final stats = await ApiService.fetchAdminStats();
      final tasks = <Map<String, dynamic>>[];
      for (final user in stats) {
        for (final category in (user['categories'] as List<dynamic>? ?? const [])) {
          final cat = Map<String, dynamic>.from(category as Map);
          for (final task in (cat['tasks'] as List<dynamic>? ?? const [])) {
            final item = Map<String, dynamic>.from(task as Map);
            item['username'] = user['username'];
            item['email'] = user['email'];
            item['categoryName'] = cat['name'];
            item['categoryId'] = cat['id'];
            tasks.add(item);
          }
        }
      }
      tasks.sort((a,b) => (a['dueDate'] ?? '').toString().compareTo((b['dueDate'] ?? '').toString()));
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không tải được danh sách task.')));
    }
  }

  void _openTask(Map<String, dynamic> task) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => _TaskDetailScreen(task: task, onChanged: _load)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            const ScreenHeader(eyebrow: 'Admin', title: 'Task Library', subtitle: 'Xem chi tiết và xóa mềm task của toàn hệ thống.', icon: Icons.task_alt_rounded),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(padding: EdgeInsets.symmetric(vertical: 80), child: Center(child: CircularProgressIndicator()))
            else if (_tasks.isEmpty)
              const EmptyStateCard(icon: Icons.task_alt_rounded, title: 'Chưa có task', message: 'Khi người dùng tạo task, danh sách sẽ hiện tại đây.')
            else
              ..._tasks.map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SectionCard(
                  child: InkWell(
                    onTap: () => _openTask(task),
                    borderRadius: BorderRadius.circular(24),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text((task['title'] ?? '').toString(), style: Theme.of(context).textTheme.titleMedium)),
                        _Pill(text: (task['status'] ?? 'TODO').toString(), color: AppColors.info, bg: const Color(0xFFEAF1FF)),
                      ]),
                      const SizedBox(height: 6),
                      Text((task['description'] ?? '').toString(), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        _Pill(text: (task['categoryName'] ?? 'No category').toString(), color: AppColors.primaryDark, bg: const Color(0xFFFFF2EA)),
                        _Pill(text: (task['priority'] ?? 'MEDIUM').toString(), color: AppColors.warning, bg: const Color(0xFFFFF6E5)),
                        _Pill(text: (task['username'] ?? '').toString(), color: AppColors.purple, bg: const Color(0xFFF4EEFF)),
                      ]),
                    ]),
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }
}

class _TaskDetailScreen extends StatelessWidget {
  const _TaskDetailScreen({required this.task, required this.onChanged});
  final Map<String, dynamic> task;
  final Future<void> Function() onChanged;

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Xóa mềm task?'),
        content: Text('Task "${(task['title'] ?? '').toString()}" sẽ bị ẩn khỏi hệ thống.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      final idRaw = task['id'];
      final id = idRaw is int ? idRaw : int.tryParse(idRaw.toString());
      if (id == null) throw Exception('Thiếu id task');
      await ApiService.softDeleteTaskAdmin(id);
      await onChanged();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa mềm task.')));
      Navigator.pop(context);
    } catch (e) {
      if (ApiService.isUnauthorized(e)) {
        await handleUnauthorized(context);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể xóa task.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết task')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SectionCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text((task['title'] ?? '').toString(), style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text((task['description'] ?? '').toString()),
              const SizedBox(height: 16),
              _InfoRow(label: 'Người tạo', value: (task['username'] ?? '').toString()),
              _InfoRow(label: 'Email', value: (task['email'] ?? '').toString()),
              _InfoRow(label: 'Category', value: (task['categoryName'] ?? '').toString()),
              _InfoRow(label: 'Priority', value: (task['priority'] ?? '').toString()),
              _InfoRow(label: 'Status', value: (task['status'] ?? '').toString()),
              _InfoRow(label: 'Due date', value: (task['dueDate'] ?? '').toString()),
            ]),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => _delete(context),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Xóa task'),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color, required this.bg});
  final String text; final Color color; final Color bg;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
    child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
  );
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
