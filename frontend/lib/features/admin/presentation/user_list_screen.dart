import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../data/models/user_model.dart';
import '../controller/admin_controller.dart';
import 'user_detail_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminController>().fetchUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminController>();
    final List<UserModel> users = controller.users;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User List'),
      ),
      body: Builder(
        builder: (context) {
          if (controller.isLoading) {
            return const AppLoading(message: 'Đang tải danh sách người dùng...');
          }

          if (controller.errorMessage != null && users.isEmpty) {
            return AppErrorState(
              message: controller.errorMessage!,
              onRetry: controller.fetchUsers,
            );
          }

          if (users.isEmpty) {
            return const AppEmptyState(
              icon: Icons.people_outline,
              title: 'Không có người dùng nào',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final user = users[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      user.username.isNotEmpty
                          ? user.username[0].toUpperCase()
                          : 'U',
                    ),
                  ),
                  title: Text(user.username),
                  subtitle: Text(user.email),
                  trailing: Text(
                    user.isActive ? 'Active' : 'Inactive',
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserDetailScreen(userId: user.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}