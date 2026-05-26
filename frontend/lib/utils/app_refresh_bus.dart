import 'package:flutter/foundation.dart';

class AppRefreshBus {
  static final ValueNotifier<int> tasks = ValueNotifier<int>(0);
  static final ValueNotifier<int> notifications = ValueNotifier<int>(0);
  static final ValueNotifier<int> categories = ValueNotifier<int>(0);

  static void bumpTasks() {
    tasks.value++;
    notifications.value++;
  }

  static void bumpNotifications() {
    notifications.value++;
  }

  static void bumpCategories() {
    categories.value++;
    tasks.value++;
  }
}
