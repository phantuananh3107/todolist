import 'package:flutter/material.dart';

import '../screens/notifications/notifications_screen.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_refresh_bus.dart';

class NotificationButton extends StatefulWidget {
  const NotificationButton({super.key, this.compact = false});

  final bool compact;

  @override
  State<NotificationButton> createState() => _NotificationButtonState();
}

class _NotificationButtonState extends State<NotificationButton> {
  int _badgeCount = 0;

  @override
  void initState() {
    super.initState();
    AppRefreshBus.notifications.addListener(_loadBadgeCount);
    _loadBadgeCount();
  }

  @override
  void dispose() {
    AppRefreshBus.notifications.removeListener(_loadBadgeCount);
    super.dispose();
  }

  Future<void> _loadBadgeCount() async {
    try {
      final unreadItems = await ApiService.fetchUnreadNotifications();
      List reminders = const [];
      try {
        reminders = await ApiService.fetchReminders();
      } catch (_) {}
      if (!mounted) return;
      final now = DateTime.now();
      final upcomingCount = reminders.where((item) {
        try {
          return item.remindTime.isAfter(now.subtract(const Duration(minutes: 1)));
        } catch (_) {
          return true;
        }
      }).length;
      setState(() => _badgeCount = unreadItems.length + upcomingCount);
    } catch (_) {
      try {
        final reminders = await ApiService.fetchReminders();
        if (!mounted) return;
        final now = DateTime.now();
        final upcomingCount = reminders.where((item) => item.remindTime.isAfter(now.subtract(const Duration(minutes: 1)))).length;
        setState(() => _badgeCount = upcomingCount);
      } catch (_) {
        if (!mounted) return;
        setState(() => _badgeCount = 0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            tooltip: 'Thông báo',
            visualDensity: compact ? VisualDensity.compact : null,
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
              AppRefreshBus.bumpNotifications();
            },
            icon: Icon(Icons.notifications_none_rounded, size: compact ? 20 : 22),
          ),
          if (_badgeCount > 0)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    _badgeCount > 9 ? '9+' : '$_badgeCount',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 10),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
