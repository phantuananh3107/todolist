import 'package:flutter/material.dart';

import '../screens/admin/admin_shell.dart';
import '../screens/home/home_shell.dart';

Widget appShellForRole(String? role) {
  final normalized = (role ?? '').toUpperCase();
  if (normalized.contains('ADMIN')) return const AdminShell();
  return const HomeShell();
}

Route<void> appShellRouteForRole(String? role) {
  return MaterialPageRoute<void>(builder: (_) => appShellForRole(role));
}
