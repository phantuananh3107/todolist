import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/auth_navigation.dart';
import 'admin_dashboard_screen.dart';
import 'admin_profile_screen.dart';
import 'user_management_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int index = 0;

  @override
  void initState() {
    super.initState();
    _ensureAdminShell();
  }

  Future<void> _ensureAdminShell() async {
    final role = ApiService.normalizeRole(await ApiService.getRole());
    if (!mounted || role == 'ADMIN') return;
    await redirectToRoleShell(context, role);
  }

  @override
  Widget build(BuildContext context) {
    final pages = const [
      AdminDashboardScreen(),
      UserManagementScreen(),
      AdminProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: AppColors.softShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (value) => setState(() => index = value),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.space_dashboard_rounded), label: 'Dashboard'),
              NavigationDestination(icon: Icon(Icons.groups_rounded), label: 'Users'),
              NavigationDestination(icon: Icon(Icons.verified_user_rounded), label: 'Admin'),
            ],
          ),
        ),
      ),
    );
  }
}
