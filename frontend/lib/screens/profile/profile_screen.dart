import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
            child: const Column(
              children: [
                CircleAvatar(radius: 36, backgroundColor: Color(0xFFFAD7C3), child: Icon(Icons.person, size: 40)),
                SizedBox(height: 12),
                Text('Chien Nguyen Canh', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                SizedBox(height: 6),
                Text('chienlqd3@gmail.com'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _Tile(title: 'Update profile', icon: Icons.edit_outlined),
          _Tile(title: 'Change password', icon: Icons.lock_outline_rounded),
          _Tile(title: 'Reminder settings', icon: Icons.notifications_active_outlined),
          _Tile(title: 'Admin dashboard', icon: Icons.admin_panel_settings_outlined),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 18)),
            onPressed: () async {
              await ApiService.clearAuth();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
