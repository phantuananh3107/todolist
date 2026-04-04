import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../controller/admin_controller.dart';

class UserDetailScreen extends StatefulWidget {
  final int userId;

  const UserDetailScreen({
    super.key,
    required this.userId,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminController>().fetchUserDetail(widget.userId);
    });
  }

  Future<void> _toggleStatus() async {
    final controller = context.read<AdminController>();
    final success = await controller.toggleUserStatus(widget.userId);

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? 'Cập nhật trạng thái thất bại'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminController>();
    final user = controller.selectedUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Detail'),
      ),
      body: Builder(
        builder: (context) {
          if (controller.isLoading && user == null) {
            return const AppLoading(message: 'Đang tải thông tin người dùng...');
          }

          if (controller.errorMessage != null && user == null) {
            return AppErrorState(
              message: controller.errorMessage!,
              onRetry: () => controller.fetchUserDetail(widget.userId),
            );
          }

          if (user == null) {
            return const AppErrorState(
              message: 'Không tìm thấy thông tin người dùng',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _InfoRow(label: 'ID', value: user.id.toString()),
                      _InfoRow(label: 'Username', value: user.username),
                      _InfoRow(label: 'Email', value: user.email),
                      _InfoRow(label: 'Role', value: user.role),
                      _InfoRow(
                        label: 'Created At',
                        value: user.createdAt != null
                            ? DateFormat('dd/MM/yyyy HH:mm')
                                .format(user.createdAt!)
                            : 'N/A',
                      ),
                      _InfoRow(
                        label: 'Status',
                        value: user.isActive ? 'Active' : 'Inactive',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: controller.isSubmitting ? null : _toggleStatus,
                child: Text(
                  user.isActive ? 'Deactivate User' : 'Activate User',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}