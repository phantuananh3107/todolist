import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/auth_navigation.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/section_card.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  int _filterIndex = 0;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final users = await ApiService.fetchAdminUsers(keyword: _searchController.text.trim());
      if (!mounted) return;
      setState(() {
        _users = users;
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không tải được danh sách người dùng.')));
    }
  }

  Future<void> _toggleLock(Map<String, dynamic> user) async {
    final idRaw = user['id'];
    final id = idRaw is int ? idRaw : int.tryParse(idRaw.toString());
    if (id == null) return;
    try {
      if (user['isActive'] == true) {
        await ApiService.lockUser(id);
      } else {
        await ApiService.unlockUser(id);
      }
      await _load();
    } catch (e) {
      if (ApiService.isUnauthorized(e)) {
        if (!mounted) return;
        await handleUnauthorized(context);
      }
    }
  }

  int _taskCount(Map<String, dynamic> user) {
    final categories = (user['categories'] as List<dynamic>? ?? const []);
    return categories.fold<int>(0, (sum, item) => sum + (((item as Map<String, dynamic>)['taskCount'] ?? 0) as num).toInt());
  }

  List<Map<String, dynamic>> get _visibleUsers {
    final items = [..._users];
    if (_filterIndex == 1) return items.where((e) => e['isActive'] == true).toList();
    if (_filterIndex == 2) return items.where((e) => e['isActive'] != true).toList();
    return items;
  }

  void _openUserDetail(Map<String, dynamic> user) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => _UserDetailScreen(user: user, onToggleLock: () => _toggleLock(user))));
  }

  @override
  Widget build(BuildContext context) {
    final visibleUsers = _visibleUsers;
    final active = _users.where((e) => e['isActive'] == true).length;
    final locked = _users.where((e) => e['isActive'] != true).length;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
          children: [
            const ScreenHeader(
              eyebrow: 'Admin',
              title: 'User Management',
              subtitle: 'Mình đang bám danh sách user kiểu mobile card. Những thao tác chỉnh sâu hơn vẫn sẽ nối backend sau.',
              icon: Icons.people_alt_rounded,
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _searchController,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm người dùng',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(onPressed: _load, icon: const Icon(Icons.arrow_forward_rounded)),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _SummaryCard(label: 'Tổng người dùng', value: '${_users.length}', accent: const Color(0xFFFFF2EA), color: AppColors.primaryDark)),
              const SizedBox(width: 12),
              Expanded(child: _SummaryCard(label: 'Đang hoạt động', value: '$active', accent: const Color(0xFFEAF8F0), color: AppColors.success)),
              const SizedBox(width: 12),
              Expanded(child: _SummaryCard(label: 'Đã khóa', value: '$locked', accent: const Color(0xFFFFECEA), color: AppColors.danger)),
            ]),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(label: const Text('Tất cả'), selected: _filterIndex == 0, onSelected: (_) => setState(() => _filterIndex = 0)),
                ChoiceChip(label: const Text('Đang hoạt động'), selected: _filterIndex == 1, onSelected: (_) => setState(() => _filterIndex = 1)),
                ChoiceChip(label: const Text('Đã khóa'), selected: _filterIndex == 2, onSelected: (_) => setState(() => _filterIndex = 2)),
              ],
            ),
            const SizedBox(height: 18),
            if (_loading)
              const Padding(padding: EdgeInsets.symmetric(vertical: 80), child: Center(child: CircularProgressIndicator()))
            else if (visibleUsers.isEmpty)
              EmptyStateCard(
                icon: Icons.group_off_rounded,
                title: 'Không có tài khoản phù hợp',
                message: 'Mình chưa thấy user nào khớp với bộ lọc hiện tại.',
                actionLabel: 'Xóa bộ lọc',
                onAction: () {
                  setState(() {
                    _filterIndex = 0;
                    _searchController.clear();
                  });
                  _load();
                },
              )
            else ...[
              ...visibleUsers.map((user) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _UserCard(
                      user: user,
                      taskCount: _taskCount(user),
                      onOpen: () => _openUserDetail(user),
                      onToggleLock: () => _toggleLock(user),
                    ),
                  )),
              const SizedBox(height: 10),
              SectionCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Text('Ghi chú quản trị'),
                  SizedBox(height: 12),
                  _TodoLine(text: 'Edit user profile đang ở mức giao diện để bám figma trước.'),
                  SizedBox(height: 8),
                  _TodoLine(text: 'Reset password từ admin cần API riêng nên mình đang để action note.'),
                  SizedBox(height: 8),
                  _TodoLine(text: 'Delete user vẫn để note để tránh xóa nhầm trong lúc demo.'),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.taskCount, required this.onOpen, required this.onToggleLock});

  final Map<String, dynamic> user;
  final int taskCount;
  final VoidCallback onOpen;
  final VoidCallback onToggleLock;

  @override
  Widget build(BuildContext context) {
    final isActive = user['isActive'] == true;
    return SectionCard(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(28),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFFFECE8),
                  child: Text(
                    ((user['username'] ?? 'U').toString()).substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.success : AppColors.danger,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text((user['username'] ?? '').toString(), style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text((user['email'] ?? '').toString(), style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Tag(text: '$taskCount tasks', background: const Color(0xFFEAF1FF), color: AppColors.info),
                      _Tag(text: isActive ? 'Hoạt động' : 'Đã khóa', background: isActive ? const Color(0xFFEAF8F0) : const Color(0xFFFFECEA), color: isActive ? AppColors.success : AppColors.danger),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Switch.adaptive(value: isActive, onChanged: (_) => onToggleLock(), activeColor: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _UserDetailScreen extends StatelessWidget {
  const _UserDetailScreen({required this.user, required this.onToggleLock});

  final Map<String, dynamic> user;
  final Future<void> Function() onToggleLock;

  int get taskCount {
    final categories = (user['categories'] as List<dynamic>? ?? const []);
    return categories.fold<int>(0, (sum, item) => sum + (((item as Map<String, dynamic>)['taskCount'] ?? 0) as num).toInt());
  }

  int get completedEstimate => (taskCount * 0.62).round();
  int get overdueEstimate => (taskCount * 0.1).round();

  @override
  Widget build(BuildContext context) {
    final isActive = user['isActive'] == true;
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        children: [
          Center(
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 54,
                      backgroundColor: const Color(0xFFFFECE8),
                      child: Text(((user['username'] ?? 'U').toString()).substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                    ),
                    Positioned(
                      right: -4,
                      bottom: 4,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(color: isActive ? AppColors.primary : AppColors.danger, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                        child: Icon(isActive ? Icons.lock_open_rounded : Icons.lock_rounded, size: 14, color: Colors.white),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 18),
                Text((user['username'] ?? '').toString(), style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text((user['email'] ?? '').toString(), style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.subText)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(children: [
            Expanded(child: _MiniStat(value: '$taskCount', label: 'TOTAL TASKS')),
            const SizedBox(width: 12),
            Expanded(child: _MiniStat(value: '$completedEstimate', label: 'COMPLETED')),
            const SizedBox(width: 12),
            Expanded(child: _MiniStat(value: '$overdueEstimate', label: 'OVERDUE')),
          ]),
          const SizedBox(height: 20),
          Text('MANAGEMENT ACTIONS', style: Theme.of(context).textTheme.bodySmall?.copyWith(letterSpacing: 1.2, color: AppColors.subText, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.edit_rounded,
            title: 'Edit User Profile',
            subtitle: 'Mình đang dựng giao diện trước, phần lưu thật sẽ nối backend sau.',
            primary: true,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mình đang dựng giao diện sửa hồ sơ trước.'))),
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.restart_alt_rounded,
            title: 'Reset Password',
            subtitle: 'Phần reset mật khẩu mình cần backend riêng nên đang để note trước.',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phần reset mật khẩu sẽ nối backend sau.'))),
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: isActive ? Icons.lock_rounded : Icons.lock_open_rounded,
            title: isActive ? 'Lock User Account' : 'Unlock User Account',
            subtitle: isActive ? 'Thao tác này đang chạy thật với backend hiện tại.' : 'Thao tác này đang chạy thật với backend hiện tại.',
            onTap: () async {
              await onToggleLock();
              if (context.mounted) Navigator.pop(context);
            },
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.delete_outline_rounded,
            title: 'Delete User Account',
            subtitle: 'Mình đang để note trước để tránh xóa nhầm trong lúc demo.',
            danger: true,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mình chưa nối backend xóa tài khoản.'))),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.onTap, this.primary = false, this.danger = false});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool primary;
  final bool danger;
  @override
  Widget build(BuildContext context) {
    final bg = primary ? AppColors.primary : (danger ? const Color(0xFFFFF2F0) : Colors.white);
    final fg = primary ? Colors.white : (danger ? AppColors.danger : AppColors.text);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), border: Border.all(color: primary ? Colors.transparent : AppColors.border)),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: primary ? Colors.white.withOpacity(0.18) : (danger ? const Color(0xFFFFE2DD) : const Color(0xFFFFF2EA)), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: primary ? Colors.white : (danger ? AppColors.danger : AppColors.primaryDark)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: fg)),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: primary ? Colors.white.withOpacity(0.92) : AppColors.subText)),
            ])),
            Icon(Icons.chevron_right_rounded, color: fg),
          ]),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(color: const Color(0xFFFFF6F4), borderRadius: BorderRadius.circular(22)),
      child: Column(children: [
        Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 28, color: AppColors.primaryDark)),
        const SizedBox(height: 6),
        Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.subText, fontWeight: FontWeight.w800, letterSpacing: 0.7)),
      ]),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value, required this.accent, required this.color});
  final String label;
  final String value;
  final Color accent;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: color)),
      ]),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.background, required this.color});
  final String text;
  final Color background;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _TodoLine extends StatelessWidget {
  const _TodoLine({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.text))),
    ]);
  }
}
