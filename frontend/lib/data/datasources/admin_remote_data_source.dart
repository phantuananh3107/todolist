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
    final response = await dio.get(ApiConstants.adminUserDetail(userId));

    if (response.data is Map<String, dynamic>) {
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    }

    throw Exception('Dữ liệu user không hợp lệ');
  }

  Future<void> toggleUserStatus(int userId) async {
    await dio.put(ApiConstants.toggleUserStatus(userId));
  }

  Future<AdminStatisticsModel> getStatistics() async {
    final response = await dio.get(ApiConstants.adminStatistics);

    if (response.data is Map<String, dynamic>) {
      return AdminStatisticsModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    }

    throw Exception('Dữ liệu thống kê admin không hợp lệ');
  }
}