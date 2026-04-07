import 'package:flutter/material.dart';

import '../screens/auth/login_screen.dart';
import '../services/api_service.dart';
import 'app_shell_router.dart';

Future<void> handleUnauthorized(BuildContext context, {String? message}) async {
  await ApiService.clearAuth();
  if (!context.mounted) return;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message ?? 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.'),
      ),
    );

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}

Future<void> redirectToRoleShell(BuildContext context, String? role) async {
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    appShellRouteForRole(role),
    (route) => false,
  );
}
