import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_refresh_bus.dart';
import '../../utils/auth_navigation.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/notification_button.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/section_card.dart';
import '../auth/login_screen.dart';
import '../notifications/notifications_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  Map<String, dynamic>? _profile;
  Map<String, int> _taskStats = const {'total': 0, 'done': 0, 'doing': 0};

  @override
  void initState() {
    super.initState();
    AppRefreshBus.tasks.addListener(_loadProfile);
    _loadProfile();
  }

  @override
  void dispose() {
    AppRefreshBus.tasks.removeListener(_loadProfile);
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final profile = await ApiService.fetchProfile();
      if (!mounted) return;
      Map<String, int> stats = const {'total': 0, 'done': 0, 'doing': 0};
      try {
        final tasks = await ApiService.fetchTasks();
        stats = {
          'total': tasks.length,
          'done': tasks.where((e) => e.status == 'DONE').length,
          'doing': tasks.where((e) => e.status == 'DOING').length,
        };
      } catch (_) {}
      setState(() {
        _profile = profile;
        _taskStats = stats;
        _loading = false;
      });
    } catch (e) {
      if (ApiService.isUnauthorized(e)) {
        if (!mounted) return;
        setState(() => _loading = false);
        await handleUnauthorized(context);
        return;
      }
      final email = await ApiService.getEmail();
      final username = await ApiService.getUsername();
      final userId = await ApiService.getUserId();
      final role = await ApiService.getRole();
      if (!mounted) return;
      setState(() {
        _profile = {
          'id': userId ?? 0,
          'username': username ?? 'Người dùng',
          'email': email ?? '',
          'role': role ?? 'USER',
        };
        _taskStats = const {'total': 0, 'done': 0, 'doing': 0};
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được hồ sơ từ backend (${ApiService.baseUrl}).')),
      );
    }
  }

  String _avatarUrl(Map<String, dynamic> profile) {
    for (final key in ['avatarUrl', 'imageUrl', 'profileImage', 'photoUrl']) {
      final value = profile[key]?.toString();
      if (value != null && value.isNotEmpty) return value;
    }
    return '';
  }

  String _initials(Map<String, dynamic> profile) {
    final username = (profile['username'] ?? 'U').toString().trim();
    if (username.isEmpty) return 'U';
    final parts = username.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : profile == null
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: EmptyStateCard(
                    icon: Icons.person_off_outlined,
                    title: 'Chưa có dữ liệu profile',
                    message: 'Hãy đăng nhập lại hoặc thử tải lại thông tin người dùng.',
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                    children: [
                      const ScreenHeader(
                        eyebrow: 'Profile',
                        title: 'Tài khoản',
                        subtitle: 'Không gian cá nhân của bạn',
                        icon: Icons.person_outline_rounded,
                        trailing: NotificationButton(),
                      ),
                      const SizedBox(height: 18),
                      SectionCard(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFFBFA), Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _ProfileAvatar(initials: _initials(profile), imageUrl: _avatarUrl(profile)),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text((profile['username'] ?? 'User').toString(), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24)),
                                      const SizedBox(height: 4),
                                      Text((profile['email'] ?? '').toString(), style: Theme.of(context).textTheme.bodyMedium),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: AppColors.primarySoft,
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              (profile['role'] ?? 'USER').toString().toUpperCase(),
                                              style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w800, fontSize: 12),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceMuted,
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              _avatarUrl(profile).isEmpty ? 'Ảnh đại diện mặc định' : 'Ảnh đại diện đang hiển thị',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.text),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(onPressed: _loadProfile, icon: const Icon(Icons.refresh_rounded)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: _InlineInfoTile(icon: Icons.task_alt_rounded, label: 'Tổng task', value: '${_taskStats['total'] ?? 0}')),
                                const SizedBox(width: 10),
                                Expanded(child: _InlineInfoTile(icon: Icons.timelapse_rounded, label: 'Đang làm', value: '${_taskStats['doing'] ?? 0}')),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _ProfileStatCard(label: 'Tổng task', value: '${_taskStats['total'] ?? 0}', tone: AppColors.primarySoft, valueColor: AppColors.primaryDark)),
                          const SizedBox(width: 10),
                          Expanded(child: _ProfileStatCard(label: 'Đang làm', value: '${_taskStats['doing'] ?? 0}', tone: const Color(0xFFFFF3DF), valueColor: AppColors.warning)),
                          const SizedBox(width: 10),
                          Expanded(child: _ProfileStatCard(label: 'Đã xong', value: '${_taskStats['done'] ?? 0}', tone: const Color(0xFFE8F8EF), valueColor: AppColors.success)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tài khoản của bạn', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 6),
                            Text('Cập nhật hồ sơ, bảo mật tài khoản và theo dõi thông báo gần đây.', style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 14),
                            _ProfileTile(
                              title: 'Cập nhật hồ sơ',
                              subtitle: 'Chỉnh sửa thông tin tài khoản của bạn',
                              icon: Icons.edit_outlined,
                              iconTone: const Color(0xFFFFEFEA),
                              iconColor: AppColors.primary,
                              onTap: () async {
                                final userId = await ApiService.getUserId() ?? (profile['id'] is int ? profile['id'] as int : 0);
                                if (!mounted) return;
                                final updated = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditProfileScreen(
                                      userId: userId,
                                      initialUsername: (profile['username'] ?? '').toString(),
                                      initialEmail: (profile['email'] ?? '').toString(),
                                    ),
                                  ),
                                );
                                if (updated == true) _loadProfile();
                              },
                            ),
                            _ProfileTile(
                              title: 'Đổi mật khẩu',
                              subtitle: 'Cập nhật mật khẩu để bảo vệ tài khoản',
                              icon: Icons.lock_outline_rounded,
                              iconTone: const Color(0xFFFFF4E0),
                              iconColor: AppColors.warning,
                              onTap: () async {
                                final userId = await ApiService.getUserId() ?? (profile['id'] is int ? profile['id'] as int : 0);
                                if (!mounted) return;
                                await Navigator.push(context, MaterialPageRoute(builder: (_) => ChangePasswordScreen(userId: userId)));
                              },
                            ),
                            _ProfileTile(
                              title: 'Thông báo',
                              subtitle: 'Xem các nhắc nhở và cập nhật mới nhất',
                              icon: Icons.notifications_none_rounded,
                              iconTone: const Color(0xFFEFF3FF),
                              iconColor: AppColors.info,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () async {
                          final shouldLogout = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                              title: const Text('Đăng xuất'),
                              content: const Text('Bạn có chắc muốn đăng xuất khỏi tài khoản hiện tại không?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Ở lại')),
                                FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Đăng xuất')),
                              ],
                            ),
                          );
                          if (shouldLogout != true) return;
                          await ApiService.clearAuth();
                          if (!mounted) return;
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Đăng xuất'),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.initials, required this.imageUrl});
  final String initials;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.isNotEmpty;
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        gradient: hasImage ? null : const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
        image: hasImage ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) : null,
        borderRadius: BorderRadius.circular(26),
        boxShadow: AppColors.buttonShadow,
      ),
      alignment: Alignment.center,
      child: hasImage ? null : Text(initials, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.iconTone,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final Object? iconTone;

  @override
  Widget build(BuildContext context) {
    Decoration avatarDecoration;
    if (iconTone is Gradient) {
      avatarDecoration = BoxDecoration(gradient: iconTone as Gradient, borderRadius: BorderRadius.circular(16));
    } else {
      avatarDecoration = BoxDecoration(color: (iconTone as Color?) ?? AppColors.primarySoft, borderRadius: BorderRadius.circular(16));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(22)),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: avatarDecoration,
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.subText),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  const _ProfileStatCard({required this.label, required this.value, required this.tone, required this.valueColor});

  final String label;
  final String value;
  final Color tone;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: valueColor)),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: valueColor.withOpacity(0.88))),
        ],
      ),
    );
  }
}

class _InlineInfoTile extends StatelessWidget {
  const _InlineInfoTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 18, color: AppColors.primaryDark),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
