import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/category_item.dart';
import '../models/chart_stats.dart';
import '../models/reminder_item.dart';
import '../models/task_item.dart';

class ApiUnauthorizedException implements Exception {
  ApiUnauthorizedException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ApiService {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8080';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8080';
      default:
        return 'http://localhost:8080';
    }
  }

  static const _tokenKey = 'auth_token';
  static const _emailKey = 'auth_email';
  static const _usernameKey = 'auth_username';
  static const _userIdKey = 'auth_user_id';
  static const _roleKey = 'auth_role';

  static String normalizeRole(String? raw) {
    final role = (raw ?? 'USER').toUpperCase();
    if (role.contains('ADMIN')) return 'ADMIN';
    return 'USER';
  }

  static Future<void> saveAuth(
    String token,
    String email, {
    String? username,
    int? userId,
    String? role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_emailKey, email);
    if (username != null) await prefs.setString(_usernameKey, username);
    if (userId != null) await prefs.setInt(_userIdKey, userId);
    if (role != null) await prefs.setString(_roleKey, normalizeRole(role));
  }

  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_roleKey);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  static Future<void> saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
  }

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Exception _httpError(http.Response response) {
    final body = response.body.trim();
    final message = body.isEmpty ? 'HTTP ${response.statusCode}' : body;
    if (response.statusCode == 401) {
      return ApiUnauthorizedException(message);
    }
    return Exception(message);
  }

  static bool isUnauthorized(Object error) => error is ApiUnauthorizedException;

  static Future<Map<String, dynamic>> login({required String email, required String password}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['role'] != null) {
        data['role'] = normalizeRole(data['role']?.toString());
      }
      return data;
    }
    throw _httpError(response);
  }

  static Future<void> register({required String username, required String email, required String password}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/users/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'email': email, 'password': password}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _httpError(response);
    }
  }

  static Future<Map<String, dynamic>> fetchProfile() async {
    final response = await http.get(Uri.parse('$baseUrl/api/users/profile'), headers: await _headers());
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      final idRaw = data['id'];
      final userId = idRaw is int ? idRaw : int.tryParse(idRaw.toString());
      if (userId != null) await prefs.setInt(_userIdKey, userId);
      if (data['username'] != null) await prefs.setString(_usernameKey, data['username'].toString());
      if (data['email'] != null) await prefs.setString(_emailKey, data['email'].toString());
      if (data['role'] != null) await prefs.setString(_roleKey, normalizeRole(data['role'].toString()));
      return data;
    }
    throw _httpError(response);
  }

  static Future<void> updateProfile({required int userId, required String username, required String email}) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/users/profile/$userId'),
      headers: await _headers(),
      body: jsonEncode({'username': username, 'email': email}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _httpError(response);
    }
    await saveAuth(
      await getToken() ?? '',
      email,
      username: username,
      userId: userId,
      role: await getRole(),
    );
  }

  static Future<void> changePassword({
    required int userId,
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/users/change-password/$userId'),
      headers: await _headers(),
      body: jsonEncode({
        'oldPassword': oldPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _httpError(response);
    }
  }

  static Future<ChartStats> fetchTaskStats({String range = 'WEEK', String basis = 'DUE_DATE'}) async {
    final uri = Uri.parse('$baseUrl/api/tasks/stats').replace(queryParameters: {
      'range': range,
      'basis': basis,
    });
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ChartStats.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw _httpError(response);
  }

  static Future<List<TaskItem>> fetchTasks() async {
    final response = await http.get(Uri.parse('$baseUrl/api/tasks'), headers: await _headers());
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((e) => TaskItem.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw _httpError(response);
  }

  static Future<List<CategoryItem>> fetchCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/api/categories'), headers: await _headers());
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((e) => CategoryItem.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw _httpError(response);
  }

  static Future<Map<String, dynamic>?> suggestCategory({required String description}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/categories/suggest'),
      headers: await _headers(),
      body: jsonEncode({'description': description}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        final suggestions = data['suggestions'];
        if (suggestions is List && suggestions.isNotEmpty && suggestions.first is Map<String, dynamic>) {
          return suggestions.first as Map<String, dynamic>;
        }
        return data;
      }
    }
    return null;
  }

  static Future<CategoryItem> createCategory(String name, {String? colorHex}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/categories'),
      headers: await _headers(),
      body: jsonEncode({'name': name, 'colorHex': colorHex}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return CategoryItem.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw _httpError(response);
  }

  static Future<void> updateCategory(int id, String name, {String? colorHex, String? previousName}) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/categories/$id'),
      headers: await _headers(),
      body: jsonEncode({'name': name, 'colorHex': colorHex}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _httpError(response);
    }
  }

  static Future<void> deleteCategory(int id, {String? name}) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/categories/$id'), headers: await _headers());
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _httpError(response);
    }
  }

  static Future<TaskItem> createTask(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/tasks'),
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return TaskItem.fromJson(data);
    }
    throw _httpError(response);
  }

  static Future<void> updateTask(int id, Map<String, dynamic> payload) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/tasks/$id'),
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _httpError(response);
    }
  }

  static Future<void> deleteTask(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/tasks/$id'), headers: await _headers());
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _httpError(response);
    }
  }

  static Future<String> sendChat(List<Map<String, String>> messages) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/chat'),
      headers: await _headers(),
      body: jsonEncode({'messages': messages}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['response'] ?? '').toString();
    }
    throw _httpError(response);
  }

  static String buildTaskContext(List<TaskItem> tasks) {
    if (tasks.isEmpty) return 'Hiện chưa có task nào.';
    final open = tasks.where((e) => e.status != 'DONE').toList()..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final focus = open.take(8).map((task) {
      final due = '${task.dueDate.day}/${task.dueDate.month} ${task.dueDate.hour.toString().padLeft(2, '0')}:${task.dueDate.minute.toString().padLeft(2, '0')}';
      return '- ${task.title} | ${task.status} | ${task.priority} | ${task.category} | hạn $due';
    }).join('\n');
    return 'Danh sách công việc hiện tại:\n$focus';
  }

  static Future<List<ReminderItem>> fetchReminders() async {
    final response = await http.get(Uri.parse('$baseUrl/api/reminders'), headers: await _headers());
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((e) => ReminderItem.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw _httpError(response);
  }

  static Future<void> createReminder({required int taskId, required DateTime remindTime}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/reminders/task/$taskId'),
      headers: await _headers(),
      body: jsonEncode({'taskId': taskId, 'remindTime': remindTime.toIso8601String()}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) throw _httpError(response);
  }

  static Future<void> updateReminder(int id, DateTime remindTime) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/reminders/$id'),
      headers: await _headers(),
      body: jsonEncode({'remindTime': remindTime.toIso8601String()}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) throw _httpError(response);
  }

  static Future<void> deleteReminder(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/reminders/$id'), headers: await _headers());
    if (response.statusCode < 200 || response.statusCode >= 300) throw _httpError(response);
  }

  static Future<List<Map<String, dynamic>>> fetchNotifications() async {
    final response = await http.get(Uri.parse('$baseUrl/api/notifications'), headers: await _headers());
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    throw _httpError(response);
  }

  static Future<List<Map<String, dynamic>>> fetchUnreadNotifications() async {
    final response = await http.get(Uri.parse('$baseUrl/api/notifications/unread'), headers: await _headers());
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    throw _httpError(response);
  }

  static Future<void> markNotificationRead(int id) async {
    final response = await http.patch(Uri.parse('$baseUrl/api/notifications/$id/read'), headers: await _headers());
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _httpError(response);
    }
  }

  static Future<List<Map<String, dynamic>>> fetchAdminUsers({String keyword = '', int page = 1, int limit = 20}) async {
    final uri = Uri.parse('$baseUrl/api/admin/users').replace(queryParameters: {
      'keyword': keyword,
      'page': '$page',
      'limit': '$limit',
    });
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = (data['content'] as List<dynamic>? ?? const []);
      return content.cast<Map<String, dynamic>>();
    }
    throw _httpError(response);
  }

  static Future<List<Map<String, dynamic>>> fetchAdminStats() async {
    final response = await http.get(Uri.parse('$baseUrl/api/admin/stats/tasks'), headers: await _headers());
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    throw _httpError(response);
  }

  static Future<void> lockUser(int id) async {
    final response = await http.patch(Uri.parse('$baseUrl/api/admin/users/$id/lock'), headers: await _headers());
    if (response.statusCode < 200 || response.statusCode >= 300) throw _httpError(response);
  }

  static Future<void> unlockUser(int id) async {
    final response = await http.patch(Uri.parse('$baseUrl/api/admin/users/$id/unlock'), headers: await _headers());
    if (response.statusCode < 200 || response.statusCode >= 300) throw _httpError(response);
  }

  static List<ReminderItem> buildDemoReminders(List<TaskItem> tasks) {
    final now = DateTime.now();
    return tasks.take(4).map((task) {
      final proposed = task.dueDate.subtract(const Duration(minutes: 45));
      final remindAt = proposed.isBefore(now) ? now.add(const Duration(minutes: 20)) : proposed;
      return ReminderItem(
        id: task.id + 9000,
        taskId: task.id,
        taskTitle: task.title,
        remindTime: remindAt,
        taskDueDate: task.dueDate,
      );
    }).toList()..sort((a, b) => a.remindTime.compareTo(b.remindTime));
  }

  static List<Map<String, dynamic>> buildDemoNotifications(List<TaskItem> tasks) {
    final now = DateTime.now();
    return tasks.take(5).toList().asMap().entries.map((entry) {
      final task = entry.value;
      return {
        'id': task.id + 7000,
        'message': 'Nhắc bạn theo dõi công việc "${task.title}".',
        'isRead': entry.key > 1,
        'taskId': task.id,
        'createdAt': now.subtract(Duration(hours: entry.key * 3)).toIso8601String(),
      };
    }).toList();
  }
}

final List<TaskItem> demoTasks = [
  TaskItem(
    id: 1,
    title: 'Finish Q3 Financial Report',
    description: 'Hoàn thành số liệu và bản trình bày cuối cùng.',
    priority: 'HIGH',
    status: 'DOING',
    category: 'Công việc',
    categoryId: 3,
    dueDate: DateTime.now().add(const Duration(days: 1, hours: 3)),
  ),
  TaskItem(
    id: 2,
    title: 'Email Marketing Team',
    description: 'Chốt nội dung cho chiến dịch cuối tuần.',
    priority: 'MEDIUM',
    status: 'TODO',
    category: 'Học tập',
    categoryId: 1,
    dueDate: DateTime.now().add(const Duration(days: 2, hours: 1)),
  ),
  TaskItem(
    id: 3,
    title: 'Update portfolio case study',
    description: 'Bổ sung hình ảnh và kết quả cuối cùng.',
    priority: 'LOW',
    status: 'DONE',
    category: 'Cá nhân',
    categoryId: 2,
    dueDate: DateTime.now().subtract(const Duration(days: 1)),
  ),
];

final List<CategoryItem> demoCategories = [
  CategoryItem(id: 0, name: 'All', taskCount: demoTasks.length),
  CategoryItem(id: 1, name: 'Học tập', taskCount: 1, colorHex: '#3B82F6'),
  CategoryItem(id: 2, name: 'Cá nhân', taskCount: 1, colorHex: '#A855F7'),
  CategoryItem(id: 3, name: 'Công việc', taskCount: 1, colorHex: '#F97316'),
];

List<String> localAiCategorySuggestion(String title, String description, List<CategoryItem> categories) {
  final content = '${title.toLowerCase()} ${description.toLowerCase()}';
  final names = categories.where((e) => e.name != 'All').map((e) => e.name).toList();
  String pick(String fallback) => names.firstWhere((e) => e.toLowerCase() == fallback.toLowerCase(), orElse: () => names.isNotEmpty ? names.first : fallback);

  if (content.contains('học') || content.contains('study') || content.contains('exam') || content.contains('ôn tập')) {
    return [pick('Học tập'), '92'];
  }
  if (content.contains('meeting') || content.contains('báo cáo') || content.contains('client') || content.contains('dự án') || content.contains('work')) {
    return [pick('Công việc'), '89'];
  }
  if (content.contains('mua') || content.contains('gia đình') || content.contains('cá nhân') || content.contains('sức khỏe') || content.contains('personal')) {
    return [pick('Cá nhân'), '87'];
  }
  return [names.isNotEmpty ? names.first : 'General', '76'];
}
