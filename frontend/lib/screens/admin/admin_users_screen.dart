import 'package:flutter/material.dart';

import '../../models/admin_user_item.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/auth_navigation.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/section_card.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _loading = true;
  List<AdminUserItem> _users = [];
  final _searchController = TextEditingController();
  bool? _activeFilter;

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
        setState(() => _loading = false);
        await handleUnauthorized(context);
        return;
      }
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không tải được danh sách user.')));
    }
  }

  Future<void> _toggleLock(AdminUserItem user) async {
    try {
      if (user.isActive) {
        await ApiService.lockUser(user.id);
      } else {
        await ApiService.unlockUser(user.id);
      }
      _load();
    } catch (e) {
      if (ApiService.isUnauthorized(e)) {
        if (!mounted) return;
        await handleUnauthorized(context);
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không thể cập nhật user: $e')));
    }
  }

  List<AdminUserItem> get _visibleUsers {
    var result = List<AdminUserItem>.from(_users);
    if (_activeFilter != null) {
      result = result.where((user) => user.isActive == _activeFilter).toList();
    }
    result.sort((a, b) => b.taskCount.compareTo(a.taskCount));
    return result;
  }

  int get _activeCount => _users.where((e) => e.isActive).length;
  int get _lockedCount => _users.where((e) => !e.isActive).length;

  @override
  Widget build(BuildContext context) {
    final visibleUsers = _visibleUsers;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
          children: [
            ScreenHeader(
              eyebrow: 'Admin users',
              subtitle: 'Quản trị tài khoản',
              title: 'Danh sách người dùng',
              icon: Icons.groups_rounded,
              trailing: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: AppColors.softShadow),
                child: IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
              ),
            ),
            const SizedBox(height: 18),
            SectionCard(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFBFA), Color(0xFFFFFFFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _load(),
                          decoration: InputDecoration(
                            hintText: 'Tìm theo tên hoặc email',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: IconButton(onPressed: _load, icon: const Icon(Icons.arrow_forward_rounded)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _MiniCountCard(label: 'Tổng user', value: _users.length, tone: const Color(0xFFFFF1DA))),
                      const SizedBox(width: 10),
                      Expanded(child: _MiniCountCard(label: 'Active', value: _activeCount, tone: const Color(0xFFE8F7EF))),
                      const SizedBox(width: 10),
                      Expanded(child: _MiniCountCard(label: 'Locked', value: _lockedCount, tone: const Color(0xFFFFECEA))),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterPill(label: 'Tất cả', selected: _activeFilter == null, onTap: () => setState(() => _activeFilter = null)),
                      _FilterPill(label: 'Đang hoạt động', selected: _activeFilter == true, onTap: () => setState(() => _activeFilter = true)),
                      _FilterPill(label: 'Đã khóa', selected: _activeFilter == false, onTap: () => setState(() => _activeFilter = false)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (visibleUsers.isEmpty)
              EmptyStateCard(
                icon: Icons.people_outline_rounded,
                title: 'Không có người dùng phù hợp',
                message: 'Thử đổi từ khóa tìm kiếm hoặc bộ lọc để xem thêm tài khoản.',
                actionLabel: 'Xóa bộ lọc',
                onAction: () {
                  setState(() {
                    _searchController.clear();
                    _activeFilter = null;
                  });
                  _load();
                },
              )
            else
              ...visibleUsers.map(
                (user) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: SectionCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: user.isActive ? AppColors.primarySoft : const Color(0xFFFFECEA),
                              child: Text(
                                user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U',
                                style: TextStyle(
                                  color: user.isActive ? AppColors.primaryDark : AppColors.danger,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user.username, style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 4),
                                  Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _Tag(text: user.role, background: const Color(0xFFF4EEFF), color: AppColors.purple),
                                      _Tag(text: '${user.taskCount} task', background: AppColors.primarySoft, color: AppColors.primaryDark),
                                      _Tag(text: user.isActive ? 'Active' : 'Locked', background: user.isActive ? const Color(0xFFE8F7EF) : const Color(0xFFFFECEA), color: user.isActive ? AppColors.success : AppColors.danger),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: user.taskCount <= 0 ? 0 : (user.taskCount / 20).clamp(0, 1),
                                  minHeight: 8,
                                  color: user.isActive ? AppColors.primary : AppColors.danger,
                                  backgroundColor: AppColors.surfaceMuted,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.tonal(
                              onPressed: () => _toggleLock(user),
                              child: Text(user.isActive ? 'Lock' : 'Unlock'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
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
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

class _MiniCountCard extends StatelessWidget {
  const _MiniCountCard({required this.label, required this.value, required this.tone});
  final String label;
  final int value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: tone, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$value', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(label, style: TextStyle(color: selected ? AppColors.primaryDark : AppColors.text, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
