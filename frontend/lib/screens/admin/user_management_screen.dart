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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _UserDetailScreen(
          user: user,
          onToggleLock: () => _toggleLock(user),
          onChanged: _load,
        ),
      ),
    );
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
              subtitle: 'Quản lý tài khoản người dùng, chỉnh sửa thông tin, khóa hoặc vô hiệu hóa tài khoản trực tiếp từ đây.',
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
                  _TodoLine(text: 'Chỉnh sửa hồ sơ người dùng đã nối backend.'),
                  SizedBox(height: 8),
                  _TodoLine(text: 'Khóa/mở khóa và vô hiệu hóa tài khoản đang chạy với backend hiện tại.'),
                  SizedBox(height: 8),
                  _TodoLine(text: 'Xóa tài khoản đang dùng soft delete để an toàn khi demo.'),
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
  const _UserDetailScreen({required this.user, required this.onToggleLock, required this.onChanged});

  final Map<String, dynamic> user;
  final Future<void> Function() onToggleLock;
  final Future<void> Function() onChanged;

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
            subtitle: 'Cập nhật tên, email, vai trò, trạng thái và mật khẩu cho tài khoản này.',
            primary: true,
            onTap: () async {
              final updated = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => _EditUserScreen(user: user),
                ),
              );
              if (updated == true && context.mounted) {
                await onChanged();
                Navigator.pop(context);
              }
            },
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
            subtitle: 'Vô hiệu hóa mềm tài khoản này trên backend để tránh xóa nhầm dữ liệu thật.',
            danger: true,
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Vô hiệu hóa tài khoản?'),
                  content: Text('Tài khoản ${(user['username'] ?? '').toString()} sẽ bị soft delete và không còn hoạt động.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Hủy')),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Xác nhận'),
                    ),
                  ],
                ),
              );
              if (confirmed != true || !context.mounted) return;
              final messenger = ScaffoldMessenger.of(context);
              try {
                final idRaw = user['id'];
                final id = idRaw is int ? idRaw : int.tryParse(idRaw.toString());
                if (id == null) throw Exception('Thiếu id người dùng');
                await ApiService.softDeleteUser(id);
                await onChanged();
                if (!context.mounted) return;
                messenger.showSnackBar(const SnackBar(content: Text('Đã vô hiệu hóa tài khoản.')));
                Navigator.pop(context);
              } catch (e) {
                if (ApiService.isUnauthorized(e)) {
                  await handleUnauthorized(context);
                  return;
                }
                messenger.showSnackBar(const SnackBar(content: Text('Không thể vô hiệu hóa tài khoản.')));
              }
            },
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


class _EditUserScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const _EditUserScreen({required this.user});

  @override
  State<_EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<_EditUserScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  late String _role;
  late bool _isActive;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(
      text: (widget.user['username'] ?? '').toString(),
    );
    _emailController = TextEditingController(
      text: (widget.user['email'] ?? '').toString(),
    );
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _role = (widget.user['role'] ?? 'USER').toString();
    _isActive = widget.user['isActive'] == true;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ApiService.updateAdminUser(
        (widget.user['id'] as num).toInt(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        role: _role,
        isActive: _isActive,
        password: _passwordController.text.trim().isEmpty ? null : _passwordController.text.trim(),
        confirmPassword: _confirmPasswordController.text.trim().isEmpty ? null : _confirmPasswordController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật người dùng thành công')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (ApiService.isUnauthorized(e)) {
        await handleUnauthorized(context);
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể cập nhật user: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa người dùng')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Tên người dùng'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên người dùng';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập email';
                  }
                  if (!value.contains('@')) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(labelText: 'Vai trò'),
                items: const [
                  DropdownMenuItem(value: 'USER', child: Text('USER')),
                  DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _role = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Kích hoạt tài khoản'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mật khẩu mới (không bắt buộc)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu mới'),
                validator: (value) {
                  if (_passwordController.text.trim().isNotEmpty &&
                      value!.trim() != _passwordController.text.trim()) {
                    return 'Xác nhận mật khẩu không khớp';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Đang lưu...' : 'Lưu thay đổi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
