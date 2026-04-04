import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../models/admin_statistics_model.dart';
import '../models/user_model.dart';

class AdminRemoteDataSource {
  final Dio dio;

  AdminRemoteDataSource({
    required this.dio,
  });

  Future<List<UserModel>> getUsers() async {
    final response = await dio.get(ApiConstants.adminUsers);
    final data = response.data;

    if (data is List) {
      return data
          .map((item) => UserModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    if (data is Map<String, dynamic>) {
      if (data['data'] is List) {
        return (data['data'] as List)
            .map((item) => UserModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      if (data['content'] is List) {
        return (data['content'] as List)
            .map((item) => UserModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }

    return [];
  }

  Future<UserModel> getUserDetail(int userId) async {
    final users = await getUsers();
    return users.firstWhere(
      (user) => user.id == userId,
      orElse: () => throw Exception('Không tìm thấy người dùng'),
    );
  }

  Future<void> toggleUserStatus({
    required int userId,
    required bool isActive,
  }) async {
    final path = isActive
        ? ApiConstants.adminLockUser(userId)
        : ApiConstants.adminUnlockUser(userId);
    await dio.patch(path);
  }

  Future<AdminStatisticsModel> getStatistics() async {
    final users = await getUsers();
    final statsResponse = await dio.get(ApiConstants.adminTaskStats);

    int totalTasks = 0;
    final data = statsResponse.data;
    if (data is List) {
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          totalTasks += (item['totalTasks'] ?? item['taskCount'] ?? 0) as int;
        }
      }
    }

    final activeUsers = users.where((e) => e.isActive).length;
    final inactiveUsers = users.where((e) => !e.isActive).length;

    return AdminStatisticsModel(
      totalUsers: users.length,
      activeUsers: activeUsers,
      inactiveUsers: inactiveUsers,
      totalTasks: totalTasks,
    );
  }
}
