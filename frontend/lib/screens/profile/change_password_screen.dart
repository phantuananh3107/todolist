import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../utils/auth_navigation.dart';
import '../../widgets/section_card.dart';
import '../../widgets/soft_action_button.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, required this.userId});

  final int userId;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _oldController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await ApiService.changePassword(
        userId: widget.userId,
        oldPassword: _oldController.text.trim(),
        newPassword: _newController.text.trim(),
        confirmPassword: _confirmController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đổi mật khẩu thành công')));
      Navigator.pop(context, true);
    } catch (e) {
      if (ApiService.isUnauthorized(e)) {
        if (!mounted) return;
        await handleUnauthorized(context);
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không thể đổi mật khẩu: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đổi mật khẩu')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cập nhật bảo mật', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Sử dụng mật khẩu đủ mạnh để bảo vệ tài khoản của bạn tốt hơn.', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 18),
                TextField(controller: _oldController, obscureText: true, decoration: const InputDecoration(labelText: 'Mật khẩu cũ', prefixIcon: Icon(Icons.lock_outline_rounded))),
                const SizedBox(height: 14),
                TextField(controller: _newController, obscureText: true, decoration: const InputDecoration(labelText: 'Mật khẩu mới', prefixIcon: Icon(Icons.lock_reset_rounded))),
                const SizedBox(height: 14),
                TextField(controller: _confirmController, obscureText: true, decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu mới', prefixIcon: Icon(Icons.verified_user_outlined))),
                const SizedBox(height: 20),
                SoftActionButton(
                  label: _loading ? 'Đang cập nhật...' : 'Cập nhật mật khẩu',
                  icon: Icons.lock_person_rounded,
                  onPressed: _loading ? null : _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
