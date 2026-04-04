import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../controller/admin_controller.dart';
import 'user_list_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminController>().fetchStatistics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminController>();
    final stats = controller.statistics;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            onPressed: controller.fetchStatistics,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (controller.isLoading) {
            return const AppLoading(message: 'Đang tải thống kê admin...');
          }

          if (controller.errorMessage != null) {
            return AppErrorState(
              message: controller.errorMessage!,
              onRetry: controller.fetchStatistics,
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _AdminStatCard(
                      title: 'Total Users',
                      value: stats.totalUsers.toString(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AdminStatCard(
                      title: 'Total Tasks',
                      value: stats.totalTasks.toString(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _AdminStatCard(
                      title: 'Active Users',
                      value: stats.activeUsers.toString(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AdminStatCard(
                      title: 'Inactive Users',
                      value: stats.inactiveUsers.toString(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UserListScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.people_alt_outlined),
                label: const Text('Manage Users'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final String title;
  final String value;

  const _AdminStatCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}