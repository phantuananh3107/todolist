import 'package:flutter/material.dart';

import '../../models/reminder_item.dart';
import '../../models/task_item.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_refresh_bus.dart';
import '../../utils/auth_navigation.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/section_card.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];
  List<ReminderItem> _reminders = [];

  @override
  void initState() {
    super.initState();
    AppRefreshBus.notifications.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    AppRefreshBus.notifications.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final notifications = await ApiService.fetchNotifications();
      List<ReminderItem> reminders = [];
      try {
        reminders = await ApiService.fetchReminders();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _items = notifications;
        _reminders = reminders..sort((a, b) => b.remindTime.compareTo(a.remindTime));
        _loading = false;
      });
    } catch (e) {
      if (ApiService.isUnauthorized(e)) {
        if (!mounted) return;
        await handleUnauthorized(context);
        return;
      }
      try {
        final tasks = await ApiService.fetchTasks();
        if (!mounted) return;
        setState(() {
          _items = ApiService.buildDemoNotifications(tasks);
          _reminders = ApiService.buildDemoReminders(tasks);
          _loading = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _items = ApiService.buildDemoNotifications(demoTasks);
          _reminders = ApiService.buildDemoReminders(demoTasks);
          _loading = false;
        });
      }
    }
  }

  Future<void> _markRead(Map<String, dynamic> item) async {
    final rawId = item['id'];
    final id = rawId is int ? rawId : int.tryParse(rawId.toString());
    if (id == null) return;
    final previous = List<Map<String, dynamic>>.from(_items);
    setState(() {
      _items = _items
          .map((e) => e['id'].toString() == id.toString() ? {...e, 'isRead': true} : e)
          .toList();
    });
    try {
      await ApiService.markNotificationRead(id);
      AppRefreshBus.bumpNotifications();
    } catch (e) {
      if (ApiService.isUnauthorized(e)) {
        if (!mounted) return;
        await handleUnauthorized(context);
        return;
      }
      if (!mounted) return;
      setState(() => _items = previous);
    }
  }

  Future<void> _markAllRead() async {
    final unread = _items.where((e) => e['isRead'] != true).toList();
    for (final item in unread) {
      await _markRead(item);
    }
  }

  Future<void> _editReminder(ReminderItem item) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: item.remindTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: item.taskDueDate ?? item.remindTime.add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(item.remindTime));
    if (pickedTime == null) return;
    final next = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
    final previous = List<ReminderItem>.from(_reminders);
    setState(() {
      _reminders = _reminders
          .map((e) => e.id == item.id ? ReminderItem(id: e.id, taskId: e.taskId, taskTitle: e.taskTitle, remindTime: next, taskDueDate: e.taskDueDate) : e)
          .toList()
        ..sort((a, b) => b.remindTime.compareTo(a.remindTime));
    });
    try {
      await ApiService.updateReminder(item.id, next);
      AppRefreshBus.bumpNotifications();
    } catch (e) {
      if (ApiService.isUnauthorized(e)) {
        if (!mounted) return;
        await handleUnauthorized(context);
        return;
      }
      if (!mounted) return;
      setState(() => _reminders = previous);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể cập nhật reminder.')));
    }
  }

  Future<void> _deleteReminder(ReminderItem item) async {
    final previous = List<ReminderItem>.from(_reminders);
    setState(() => _reminders = _reminders.where((e) => e.id != item.id).toList());
    try {
      await ApiService.deleteReminder(item.id);
      AppRefreshBus.bumpNotifications();
    } catch (e) {
      if (ApiService.isUnauthorized(e)) {
        if (!mounted) return;
        await handleUnauthorized(context);
        return;
      }
      if (!mounted) return;
      setState(() => _reminders = previous);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể xóa reminder.')));
    }
  }

  String _formatDateTime(DateTime value) {
    return '${value.day}/${value.month}/${value.year} · ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  DateTime _safeNotificationDate(Map<String, dynamic> item) {
    final raw = item['createdAt']?.toString();
    return DateTime.tryParse(raw ?? '') ?? DateTime.now();
  }

  List<_UnifiedInboxItem> get _mergedItems {
    final reminderItems = _reminders.map((item) => _UnifiedInboxItem.reminder(item)).toList();
    final notificationItems = _items.map((item) => _UnifiedInboxItem.notification(item)).toList();
    final merged = [...reminderItems, ...notificationItems];
    merged.sort((a, b) => b.date.compareTo(a.date));
    return merged;
  }

  @override
  Widget build(BuildContext context) {
    final unread = _items.where((e) => e['isRead'] != true).length + _reminders.length;
    final merged = _mergedItems;
    return Scaffold(
      appBar: AppBar(title: const Text('Thông báo')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          children: [
            const ScreenHeader(
              eyebrow: 'Inbox',
              title: 'Thông báo',
              subtitle: 'Mình gộp reminder và activity vào cùng một luồng để nhìn dễ hơn. Những mục chưa xem sẽ hiện ngay phía trên.',
              icon: Icons.notifications_active_rounded,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: _SummaryCard(label: 'Tổng thông báo', value: '${merged.length}', icon: Icons.notifications_none_rounded, tone: AppColors.primarySoft)),
                const SizedBox(width: 10),
                Expanded(child: _SummaryCard(label: 'Chưa đọc', value: '$unread', icon: Icons.mark_email_unread_outlined, tone: const Color(0xFFFFF3DF))),
              ],
            ),
            const SizedBox(height: 18),
            if (_loading)
              const Padding(padding: EdgeInsets.symmetric(vertical: 90), child: Center(child: CircularProgressIndicator()))
            else if (merged.isEmpty)
              EmptyStateCard(
                icon: Icons.notifications_off_outlined,
                title: 'Chưa có thông báo',
                message: 'Khi có nhắc việc hoặc hoạt động mới, mình sẽ đưa vào đây theo một danh sách chung.',
                actionLabel: 'Làm mới',
                onAction: _load,
              )
            else ...[
              SectionCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Những mục có badge đỏ là chưa đọc. Reminder cũng được tính chung vào thông báo để số liệu đồng nhất hơn.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton(onPressed: unread == 0 ? null : _markAllRead, child: const Text('Đánh dấu tất cả')),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...merged.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _UnifiedInboxCard(
                    item: item,
                    formatDateTime: _formatDateTime,
                    onMarkRead: item.notification == null || item.notification!['isRead'] == true ? null : () => _markRead(item.notification!),
                    onEditReminder: item.reminder == null ? null : () => _editReminder(item.reminder!),
                    onDeleteReminder: item.reminder == null ? null : () => _deleteReminder(item.reminder!),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UnifiedInboxItem {
  _UnifiedInboxItem.reminder(ReminderItem item)
      : reminder = item,
        notification = null,
        date = item.remindTime,
        isUnread = true;

  _UnifiedInboxItem.notification(Map<String, dynamic> item)
      : notification = item,
        reminder = null,
        date = DateTime.tryParse(item['createdAt']?.toString() ?? '') ?? DateTime.now(),
        isUnread = item['isRead'] != true;

  final ReminderItem? reminder;
  final Map<String, dynamic>? notification;
  final DateTime date;
  final bool isUnread;

  bool get isReminder => reminder != null;
}

class _UnifiedInboxCard extends StatelessWidget {
  const _UnifiedInboxCard({
    required this.item,
    required this.formatDateTime,
    this.onMarkRead,
    this.onEditReminder,
    this.onDeleteReminder,
  });

  final _UnifiedInboxItem item;
  final String Function(DateTime value) formatDateTime;
  final VoidCallback? onMarkRead;
  final VoidCallback? onEditReminder;
  final VoidCallback? onDeleteReminder;

  @override
  Widget build(BuildContext context) {
    final unread = item.isUnread;
    final title = item.isReminder
        ? 'Nhắc công việc: ${item.reminder!.taskTitle}'
        : (item.notification?['message']?.toString() ?? 'Thông báo mới');
    final subtitle = item.isReminder
        ? 'Nhắc trong lịch: ${formatDateTime(item.date)}'
        : formatDateTime(item.date);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unread ? const Color(0xFFFFF6F2) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: unread ? const Color(0xFFFFD8CF) : AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: item.isReminder ? const Color(0xFFFFECE8) : const Color(0xFFEAF1FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(item.isReminder ? Icons.notifications_active_rounded : Icons.mark_email_unread_outlined, color: item.isReminder ? AppColors.primary : AppColors.info),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
                    _StateBadge(label: unread ? 'Chưa đọc' : 'Đã đọc', color: unread ? AppColors.primaryDark : AppColors.subText, background: unread ? const Color(0xFFFFE7E0) : const Color(0xFFF2F2F2)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (item.isReminder)
                      _TypePill(label: 'Nhắc việc', color: AppColors.primaryDark, background: const Color(0xFFFFECE8))
                    else
                      _TypePill(label: 'Hoạt động', color: AppColors.info, background: const Color(0xFFEAF1FF)),
                    const Spacer(),
                    if (onMarkRead != null)
                      TextButton(onPressed: onMarkRead, child: const Text('Đánh dấu đã đọc')),
                    if (item.isReminder)
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            onEditReminder?.call();
                          } else {
                            onDeleteReminder?.call();
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Đổi giờ nhắc')),
                          PopupMenuItem(value: 'delete', child: Text('Xóa nhắc việc')),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({required this.label, required this.color, required this.background});

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _StateBadge extends StatelessWidget {
  const _StateBadge({required this.label, required this.color, required this.background});

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value, required this.icon, required this.tone});

  final String label;
  final String value;
  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: tone, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24)),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
