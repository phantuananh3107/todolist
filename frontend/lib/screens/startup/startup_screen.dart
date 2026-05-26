import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_shell_router.dart';
import '../auth/login_screen.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    Widget next = const LoginScreen();

    final token = await ApiService.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        final profile = await ApiService.fetchProfile();
        next = appShellForRole(profile['role']?.toString());
      } catch (e) {
        if (ApiService.isUnauthorized(e)) {
          await ApiService.clearAuth();
        } else {
          next = appShellForRole(await ApiService.getRole());
        }
      }
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) => next,
      transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFAF8), Color(0xFFF8F8F6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: AppColors.buttonShadow,
                ),
                child: const Icon(Icons.checklist_rounded, color: Colors.white, size: 42),
              ),
              const SizedBox(height: 24),
              Text('Smart Todo', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('Quản lý công việc, lịch, AI và quản trị trong một trải nghiệm thống nhất.', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 28),
              const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.4)),
            ],
          ),
        ),
      ),
    );
  }
}
