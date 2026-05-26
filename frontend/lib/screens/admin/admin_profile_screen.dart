import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/auth_navigation.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/section_card.dart';
import '../auth/login_screen.dart';
import '../profile/change_password_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final profile = await ApiService.fetchProfile();
      if (!mounted) return;
      if (ApiService.normalizeRole(profile['role']?.toString()) != 'ADMIN') {
        await redirectToRoleShell(context, profile['role']?.toString());
        return;
      }
      setState(() {
        _profile = profile;
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final userIdRaw = profile?['id'];
    final userId = userIdRaw is int ? userIdRaw : int.tryParse((userIdRaw ?? '').toString()) ?? 0;
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                children: [
                  const ScreenHeader(
                    eyebrow: 'Admin',
                    title: 'Hồ sơ quản trị',
                    subtitle: 'Thiết lập tài khoản quản trị và quản lý không gian vận hành riêng.',
                    icon: Icons.admin_panel_settings_rounded,
                  ),
                  const SizedBox(height: 18),
                  SectionCard(
                    child: Row(
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.purple, AppColors.primary]),
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: AppColors.buttonShadow,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            ((profile?['username'] ?? 'A').toString().isNotEmpty ? (profile?['username'] ?? 'A').toString()[0] : 'A').toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text((profile?['username'] ?? 'Admin').toString(), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24)),
                            const SizedBox(height: 4),
                            Text((profile?['email'] ?? '').toString(), style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(color: const Color(0xFFF4EEFF), borderRadius: BorderRadius.circular(999)),
                              child: const Text('ADMIN WORKSPACE', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.w800, fontSize: 12)),
                            ),
                          ]),
                        ),
                        IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Khu vực quản trị riêng', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 10),
                      Text(
                        'Admin đăng nhập sẽ vào giao diện quản trị riêng, tách khỏi điều hướng của người dùng để quản lý tài khoản và thống kê hệ thống rõ ràng hơn.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Công cụ nhanh', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        _AdminActionTile(
                          title: 'Đổi mật khẩu admin',
                          subtitle: 'Cập nhật lại mật khẩu để bảo vệ quyền quản trị hệ thống',
                          icon: Icons.lock_outline_rounded,
                          tone: const Color(0xFFFFF3DF),
                          iconColor: AppColors.warning,
                          onTap: userId <= 0
                              ? null
                              : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => ChangePasswordScreen(userId: userId)),
                                  ),
                        ),
                        _AdminActionTile(
                          title: 'Làm mới hồ sơ',
                          subtitle: 'Cập nhật lại quyền và thông tin tài khoản quản trị',
                          icon: Icons.refresh_rounded,
                          tone: const Color(0xFFEAF3FF),
                          iconColor: AppColors.info,
                          onTap: _load,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () async {
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          title: const Text('Đăng xuất quản trị'),
                          content: const Text('Bạn có chắc muốn đăng xuất khỏi workspace quản trị không?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Ở lại')),
                            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Đăng xuất')),
                          ],
                        ),
                      );
                      if (shouldLogout != true) return;
                      await ApiService.clearAuth();
                      if (!mounted) return;
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
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


class _AdminActionTile extends StatelessWidget {
  const _AdminActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tone,
    required this.iconColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color tone;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
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
                width: 50,
                height: 50,
                decoration: BoxDecoration(color: tone, borderRadius: BorderRadius.circular(16)),
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
