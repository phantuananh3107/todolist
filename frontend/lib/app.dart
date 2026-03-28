import 'package:flutter/material.dart';

import 'screens/auth/login_screen.dart';
import 'theme/app_theme.dart';

class TodoSmartApp extends StatelessWidget {
  const TodoSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Todo',
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}
