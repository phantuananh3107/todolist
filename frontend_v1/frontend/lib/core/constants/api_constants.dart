class ApiConstants {
  static const String login = '/users/login';
  static const String register = '/users/register';
  static const String logout = '/users/logout';

  static const String tasks = '/tasks';
  static const String categories = '/categories';
  static const String reminders = '/reminders';

  static String profile(int id) => '/users/profile/$id';
  static String changePassword(int id) => '/users/change-password/$id';

  static const String users = '/users';
  static const String adminUsers = '/admin/users';
  static const String adminTaskStats = '/admin/stats/tasks';

  static String taskDetail(int id) => '/tasks/$id';
  static String categoryDetail(int id) => '/categories/$id';
  static String reminderDetail(int id) => '/reminders/$id';
  static String remindersByTask(int taskId) => '/tasks/$taskId/reminders';
  static String userDetail(int id) => '/users/$id';
  static String adminLockUser(int id) => '/admin/users/$id/lock';
  static String adminUnlockUser(int id) => '/admin/users/$id/unlock';
}
