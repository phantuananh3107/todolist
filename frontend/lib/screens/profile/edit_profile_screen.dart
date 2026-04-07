import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../utils/auth_navigation.dart';
import '../../widgets/section_card.dart';
import '../../widgets/soft_action_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.userId,
    required this.initialUsername,
    required this.initialEmail,
  });

  final int userId;
  final String initialUsername;
  final String initialEmail;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.initialUsername);
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await ApiService.updateProfile(
        userId: widget.userId,
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (ApiService.isUnauthorized(e)) {
        if (!mounted) return;
        await handleUnauthorized(context);
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không thể cập nhật: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cập nhật hồ sơ')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Thông tin cá nhân', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Giữ email và username luôn chính xác để đồng bộ profile tốt hơn.', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 18),
                TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person_outline_rounded))),
                const SizedBox(height: 14),
                TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline_rounded))),
                const SizedBox(height: 20),
                SoftActionButton(
                  label: _loading ? 'Đang lưu...' : 'Lưu thay đổi',
                  icon: Icons.save_rounded,
                  onPressed: _loading ? null : _save,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
