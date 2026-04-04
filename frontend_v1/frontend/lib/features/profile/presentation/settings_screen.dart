import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_loading.dart';
import '../controller/settings_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsController>().loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SettingsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: controller.isLoading
          ? const AppLoading(message: 'Đang tải cài đặt...')
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.notifications_outlined),
                        title: const Text('Enable Notifications'),
                        subtitle: const Text('Bật/tắt nhắc việc trong ứng dụng'),
                        value: controller.enableNotifications,
                        onChanged: controller.updateEnableNotifications,
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: const Icon(Icons.dark_mode_outlined),
                        title: const Text('Dark Mode'),
                        subtitle: const Text('Lưu lựa chọn giao diện tối'),
                        value: controller.enableDarkMode,
                        onChanged: controller.updateEnableDarkMode,
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: const Icon(Icons.lock_person_outlined),
                        title: const Text('Remember Login'),
                        subtitle: const Text('Ghi nhớ đăng nhập trên thiết bị'),
                        value: controller.rememberLogin,
                        onChanged: controller.updateRememberLogin,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}