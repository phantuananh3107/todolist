import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../controller/auth_controller.dart';
import 'widgets/auth_footer.dart';
import 'widgets/auth_header.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formKey = GlobalKey<FormState>();

  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    final authController = context.read<AuthController>();

    final success = await authController.register(
      username: usernameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng ký thành công, hãy đăng nhập')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authController.errorMessage ?? 'Đăng ký thất bại'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  const AuthHeader(
                    title: 'Create account',
                    subtitle: 'Tạo tài khoản để bắt đầu quản lý công việc',
                    icon: Icons.person_add_alt_1_rounded,
                  ),
                  const SizedBox(height: 28),
                  AppTextField(
                    controller: usernameController,
                    label: 'Username',
                    hintText: 'Nhập username',
                    validator: (value) =>
                        Validators.requiredField(value, label: 'Username'),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: emailController,
                    label: 'Email',
                    hintText: 'Nhập email',
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
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: confirmPasswordController,
                    label: 'Confirm Password',
                    hintText: 'Nhập lại mật khẩu',
                    obscureText: obscureConfirmPassword,
                    validator: (value) => Validators.confirmPassword(
                      value,
                      passwordController.text,
                    ),
                    prefixIcon: const Icon(Icons.lock_person_outlined),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          obscureConfirmPassword = !obscureConfirmPassword;
                        });
                      },
                      icon: Icon(
                        obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  AppButton(
                    text: 'Register',
                    isLoading: authController.isLoading,
                    icon: Icons.app_registration_rounded,
                    onPressed: _handleRegister,
                  ),
                  const SizedBox(height: 12),
                  AuthFooter(
                    text: 'Đã có tài khoản?',
                    actionText: 'Đăng nhập',
                    onTap: () {
                      Navigator.pop(context);
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