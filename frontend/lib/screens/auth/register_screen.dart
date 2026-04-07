import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../widgets/section_card.dart';
import '../../widgets/soft_action_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ApiService.register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng ký thành công. Hãy đăng nhập để tiếp tục.')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không thể đăng ký: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          Text('Tạo tài khoản mới', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 10),
          Text('Thiết lập tài khoản để đồng bộ task, lịch, biểu đồ hiệu suất và trợ lý AI.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          SectionCard(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _usernameController,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập username' : null,
                    decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person_outline_rounded)),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emailController,
                    validator: (v) {
                      final text = v?.trim() ?? '';
                      if (text.isEmpty) return 'Nhập email';
                      if (!text.contains('@')) return 'Email không hợp lệ';
                      return null;
                    },
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline_rounded)),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    validator: (v) => (v == null || v.length < 6) ? 'Mật khẩu tối thiểu 6 ký tự' : null,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SoftActionButton(
                    label: _loading ? 'Đang tạo tài khoản...' : 'Tạo tài khoản',
                    icon: Icons.person_add_alt_1_rounded,
                    onPressed: _loading ? null : _register,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
