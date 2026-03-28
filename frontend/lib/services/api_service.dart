import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/category_item.dart';
import '../models/task_item.dart';

class ApiService {
  ApiService._();

  static const String baseUrl = 'http://10.0.2.2:9090';
  static const String _tokenKey = 'access_token';
  static const String _emailKey = 'email';
  static const String _usernameKey = 'username';

  static Future<void> saveAuth(String token, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_emailKey, email);
  }

  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_usernameKey);
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

  static Future<Map<String, dynamic>> login({required String email, required String password}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(response.body);
  }

  static Future<void> register({required String username, required String email, required String password}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/users/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'email': email, 'password': password}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(response.body);
    }
  }

  static Future<List<TaskItem>> fetchTasks() async {
    final response = await http.get(Uri.parse('$baseUrl/api/tasks'), headers: await _headers());
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((e) => TaskItem.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Fetch tasks failed: ${response.statusCode}');
  }

  static Future<List<CategoryItem>> fetchCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/api/categories'), headers: await _headers());
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((e) => CategoryItem.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Fetch categories failed: ${response.statusCode}');
  }

  static Future<void> createTask(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/tasks'),
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(response.body);
    }
  }

  static Future<void> updateTask(int id, Map<String, dynamic> payload) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/tasks/$id'),
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(response.body);
    }
  }

  static Future<void> deleteTask(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/tasks/$id'), headers: await _headers());
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(response.body);
    }
  }
}

final List<TaskItem> demoTasks = [
  TaskItem(
    id: 1,
    title: 'Finish Q3 Financial Report',
    description: 'Hoàn thành số liệu và bản trình bày cuối cùng.',
    priority: 'HIGH',
    status: 'DOING',
    category: 'Work',
    categoryId: 3,
    dueDate: DateTime.now().add(const Duration(days: 1)),
    isCompleted: false,
  ),
  TaskItem(
    id: 2,
    title: 'Email Marketing Team',
    description: 'Chốt nội dung cho chiến dịch cuối tuần.',
    priority: 'MEDIUM',
    status: 'TODO',
    category: 'Study',
    categoryId: 2,
    dueDate: DateTime.now().add(const Duration(days: 2)),
    isCompleted: false,
  ),
  TaskItem(
    id: 3,
    title: 'Biology Final Prep',
    description: 'Ôn tập chapter 5 và chapter 6.',
    priority: 'HIGH',
    status: 'TODO',
    category: 'Study',
    categoryId: 2,
    dueDate: DateTime.now(),
    isCompleted: false,
  ),
  TaskItem(
    id: 4,
    title: 'Buy groceries',
    description: 'Mua đồ ăn cho 3 ngày tới.',
    priority: 'LOW',
    status: 'DONE',
    category: 'Personal',
    categoryId: 4,
    dueDate: DateTime.now(),
    isCompleted: true,
  ),
];

final List<CategoryItem> demoCategories = [
  CategoryItem(id: 1, name: 'All', taskCount: 4),
  CategoryItem(id: 2, name: 'Study', taskCount: 2),
  CategoryItem(id: 3, name: 'Work', taskCount: 1),
  CategoryItem(id: 4, name: 'Personal', taskCount: 1),
];
