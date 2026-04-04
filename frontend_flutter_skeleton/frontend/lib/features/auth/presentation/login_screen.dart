import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../controller/auth_controller.dart';
import 'widgets/auth_footer.dart';
import 'widgets/auth_header.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    final authController = context.read<AuthController>();

    final success = await authController.login(
      email: emailController.text.trim(),
      password: passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authController.errorMessage ?? 'Đăng nhập thất bại'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  const AuthHeader(
                    title: 'Welcome back',
                    subtitle: 'Đăng nhập để quản lý công việc của bạn',
                  ),
                  const SizedBox(height: 28),
                  AppTextField(
                    controller: emailController,
                    label: 'Email',
                    hintText: 'Nhập email của bạn',
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: passwordController,
                    label: 'Password',
                    hintText: 'Nhập mật khẩu',
                    obscureText: obscurePassword,
                    validator: Validators.password,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  AppButton(
                    text: 'Login',
                    isLoading: authController.isLoading,
                    icon: Icons.login,
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: 12),
                  AuthFooter(
                    text: 'Chưa có tài khoản?',
                    actionText: 'Đăng ký',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.register);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}