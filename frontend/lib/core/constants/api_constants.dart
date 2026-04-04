class ApiConstants {
  static const String apiPrefix = '/api';

  static const String login = '/users/login';
  static const String register = '/users/register';
  static const String logout = '/users/logout';

  static const String tasks = '/tasks';
  static const String categories = '/categories';
  static const String reminders = '/reminders';

  static const String profile = '/users/profile';
  static const String changePassword = '/users/change-password';

  static const String users = '/users';
  static const String adminUsers = '/admin/users';
  static const String adminStatistics = '/admin/statistics';

  static String taskDetail(int id) => '/tasks/$id';
  static String categoryDetail(int id) => '/categories/$id';
  static String reminderDetail(int id) => '/reminders/$id';
  static String remindersByTask(int taskId) => '/tasks/$taskId/reminders';
  static String userDetail(int id) => '/users/$id';
  static String adminUserDetail(int id) => '/admin/users/$id';
  static String toggleUserStatus(int id) => '/admin/users/$id/toggle-status';
}