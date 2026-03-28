import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _email = '';
  String _username = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final email = await ApiService.getEmail();
    final username = await ApiService.getUsername();
    if (!mounted) return;
    setState(() {
      _email = email ?? 'user@example.com';
      _username = username ?? 'User';
    });
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature — tính năng đang phát triển')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(28)),
            child: Column(
              children: [
                const CircleAvatar(
                    radius: 36,
                    backgroundColor: Color(0xFFFAD7C3),
                    child: Icon(Icons.person, size: 40)),
                const SizedBox(height: 12),
                Text(_username,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(_email),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _Tile(
            title: 'Update profile',
            icon: Icons.edit_outlined,
            onTap: () => _showComingSoon('Update profile'),
          ),
          _Tile(
            title: 'Change password',
            icon: Icons.lock_outline_rounded,
            onTap: () => _showComingSoon('Change password'),
          ),
          _Tile(
            title: 'Reminder settings',
            icon: Icons.notifications_active_outlined,
            onTap: () => _showComingSoon('Reminder settings'),
          ),
          _Tile(
            title: 'Admin dashboard',
            icon: Icons.admin_panel_settings_outlined,
            onTap: () => _showComingSoon('Admin dashboard'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 18)),
            onPressed: () async {
              await ApiService.clearAuth();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.title, required this.icon, this.onTap});
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
