import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/section_card.dart';
import '../../widgets/soft_action_button.dart';
import '../../utils/auth_navigation.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'demo@gmail.com');
  final _passwordController = TextEditingController(text: '123456');
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await ApiService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final role = ApiService.normalizeRole(result['role']?.toString());
      await ApiService.saveAuth(
        (result['accessToken'] ?? '') as String,
        _emailController.text.trim(),
        username: result['username']?.toString(),
        role: role,
      );
      if (!mounted) return;
      await redirectToRoleShell(context, role);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Không thể đăng nhập. Hãy kiểm tra backend hoặc thông tin tài khoản.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFBFA), Color(0xFFF7F7F5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 16),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppColors.buttonShadow,
                ),
                child: const Icon(Icons.checklist_rounded, color: Colors.white, size: 34),
              ),
              const SizedBox(height: 26),
              Text('Đăng nhập', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 10),
              Text(
                'Tài khoản user sẽ vào khu vực quản lý công việc. Tài khoản admin sẽ vào khu vực quản trị ngay sau khi đăng nhập.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 22),
              SectionCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) return 'Vui lòng nhập email';
                          if (!text.contains('@')) return 'Email không hợp lệ';
                          return null;
                        },
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.mail_outline_rounded), hintText: 'you@example.com'),
                      ),
                      const SizedBox(height: 16),
                      Text('Mật khẩu', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscure,
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'Vui lòng nhập mật khẩu' : null,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          hintText: 'Nhập mật khẩu',
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _obscure = !_obscure),
                            icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(_error!, style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
                        ),
                      ],
                      const SizedBox(height: 18),
                      SoftActionButton(
                        label: _loading ? 'Đang đăng nhập...' : 'Tiếp tục',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: _loading ? null : _login,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: const Text('Chưa có tài khoản? Tạo tài khoản mới'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
