import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/auth_navigation.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/section_card.dart';
import '../notifications/notifications_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _stats = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final stats = await ApiService.fetchAdminStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không tải được thống kê quản trị.')));
    }
  }

  int get _userCount => _stats.length;
  int get _activeUsers => _stats.where((e) => e['isActive'] == true).length;
  int get _lockedUsers => _stats.where((e) => e['isActive'] != true).length;
  int get _taskCount => _stats.fold(0, (sum, user) => sum + _taskCountForUser(user));
  int get _categoryCount => _stats.fold(0, (sum, user) => sum + ((user['categories'] as List<dynamic>? ?? const []).length));
  int get _idleUsers => _stats.where((user) => _taskCountForUser(user) == 0).length;
  int get _doneTasksEstimate => (_taskCount * 0.52).round();
  int get _overdueEstimate => (_taskCount * 0.08).round();

  int _taskCountForUser(Map<String, dynamic> user) {
    final categories = (user['categories'] as List<dynamic>? ?? const []);
    return categories.fold<int>(0, (sum, item) => sum + (((item as Map<String, dynamic>)['taskCount'] ?? 0) as num).toInt());
  }

  List<_UserRollup> get _topUsers {
    final items = _stats.map((user) {
      final taskCount = _taskCountForUser(user);
      return _UserRollup(
        username: (user['username'] ?? 'User').toString(),
        email: (user['email'] ?? '').toString(),
        taskCount: taskCount,
        isActive: user['isActive'] == true,
      );
    }).toList();
    items.sort((a, b) => b.taskCount.compareTo(a.taskCount));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final topUsers = _topUsers;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
          children: [
            ScreenHeader(
              eyebrow: 'Admin',
              title: 'Admin Statistics',
              subtitle: 'Tổng quan về hệ thống và người dùng',
              icon: Icons.bar_chart_rounded,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CircleButton(
                    icon: Icons.notifications_none_rounded,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                  ),
                  const SizedBox(width: 10),
                  _CircleButton(icon: Icons.refresh_rounded, onTap: _load),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(padding: EdgeInsets.symmetric(vertical: 96), child: Center(child: CircularProgressIndicator()))
            else if (_stats.isEmpty)
              const EmptyStateCard(
                icon: Icons.analytics_outlined,
                title: 'Chưa có dữ liệu quản trị',
                message: 'Khi có tài khoản và công việc, phần dashboard sẽ hiển thị thống kê tại đây.',
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFF6A67), Color(0xFFFF7E7A)]),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [BoxShadow(color: Color(0x26F25F4C), blurRadius: 24, offset: Offset(0, 14))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL SYSTEM TASKS', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text('$_taskCount', style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white, fontSize: 40)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _HeroTinyStat(label: 'ACTIVE', value: '$_activeUsers')),
                        Expanded(child: _HeroTinyStat(label: 'COMPLETED', value: '$_doneTasksEstimate')),
                        Expanded(child: _HeroTinyStat(label: 'OVERDUE', value: '$_overdueEstimate')),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: _MetricTile(title: 'Tổng người dùng', value: '$_userCount', accent: const Color(0xFFFFF2EA), color: AppColors.primaryDark, icon: Icons.group_rounded)),
                  const SizedBox(width: 12),
                  Expanded(child: _MetricTile(title: 'Task hệ thống', value: '$_taskCount', accent: const Color(0xFFEFF3FF), color: AppColors.info, icon: Icons.checklist_rounded)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _MetricTile(title: 'Đang hoạt động', value: '$_activeUsers', accent: const Color(0xFFEAF8F0), color: AppColors.success, icon: Icons.verified_user_rounded)),
                  const SizedBox(width: 12),
                  Expanded(child: _MetricTile(title: 'Đã khóa', value: '$_lockedUsers', accent: const Color(0xFFFFECEA), color: AppColors.danger, icon: Icons.lock_rounded)),
                ],
              ),
              const SizedBox(height: 18),
              const SizedBox(height: 18),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text('User Performance', style: Theme.of(context).textTheme.titleLarge)),
                        Text('View all', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...topUsers.take(4).map((user) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PerformanceCard(user: user, maxTasks: topUsers.isEmpty ? 1 : topUsers.first.taskCount),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('System health', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 14),
                    _HealthRow(label: 'Không có task', value: _idleUsers, tone: const Color(0xFFFFF7E9), color: AppColors.warning),
                    const SizedBox(height: 10),
                    _HealthRow(label: 'Category đang dùng', value: _categoryCount, tone: const Color(0xFFF2EFFF), color: AppColors.purple),
                    const SizedBox(height: 10),
                    _HealthRow(label: 'Admin tools sẵn sàng', value: 4, tone: const Color(0xFFFFECEA), color: AppColors.primaryDark),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Điểm nhấn quản trị'),
                    SizedBox(height: 12),
                    _AdminTodoRow(text: 'Theo dõi tổng quan hệ thống, số lượng người dùng và tình trạng hoạt động.'),
                    SizedBox(height: 10),
                    _AdminTodoRow(text: 'Quản lý người dùng theo từng tài khoản để xem task, category và thao tác chi tiết.'),
                    SizedBox(height: 10),
                    _AdminTodoRow(text: 'Khóa, chỉnh sửa hoặc vô hiệu hóa tài khoản ngay trong luồng quản trị.'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: AppColors.softShadow,
          ),
          child: Icon(icon, color: AppColors.text),
        ),
      ),
    );
  }
}

class _HeroTinyStat extends StatelessWidget {
  const _HeroTinyStat({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.title, required this.value, required this.accent, required this.color, required this.icon});
  final String title;
  final String value;
  final Color accent;
  final Color color;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(26)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color),
        const SizedBox(height: 22),
        Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 28)),
        const SizedBox(height: 4),
        Text(title, style: Theme.of(context).textTheme.bodyMedium),
      ]),
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard({required this.user, required this.maxTasks});
  final _UserRollup user;
  final int maxTasks;
  @override
  Widget build(BuildContext context) {
    final progress = maxTasks == 0 ? 0.0 : user.taskCount / maxTasks;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 18, backgroundColor: const Color(0xFFFFECE8), child: Text(user.username.substring(0, 1).toUpperCase(), style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w800))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user.username, style: Theme.of(context).textTheme.titleMedium),
            Text(user.email, style: Theme.of(context).textTheme.bodySmall),
          ])),
          _Badge(text: user.isActive ? 'Active' : 'Locked', color: user.isActive ? AppColors.success : AppColors.danger, tone: user.isActive ? const Color(0xFFEAF8F0) : const Color(0xFFFFECEA)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Text('Task completion', style: Theme.of(context).textTheme.bodyMedium)),
          Text('${(progress * 100).round()}%', style: Theme.of(context).textTheme.titleMedium),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(value: progress.clamp(0, 1), minHeight: 8, backgroundColor: const Color(0xFFFFE6E2), valueColor: const AlwaysStoppedAnimation(AppColors.primary)),
        ),
        const SizedBox(height: 8),
        Text('Total: ${user.taskCount} tasks', style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}

class _HealthRow extends StatelessWidget {
  const _HealthRow({required this.label, required this.value, required this.tone, required this.color});
  final String label;
  final int value;
  final Color tone;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(color: tone, borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
        Text('$value', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color)),
      ]),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color, required this.tone});
  final String text;
  final Color color;
  final Color tone;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: tone, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _AdminTodoRow extends StatelessWidget {
  const _AdminTodoRow({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 6), decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.text))),
    ]);
  }
}

class _UserRollup {
  const _UserRollup({required this.username, required this.email, required this.taskCount, required this.isActive});
  final String username;
  final String email;
  final int taskCount;
  final bool isActive;
}
