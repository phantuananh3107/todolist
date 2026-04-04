import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../models/statistics_model.dart';

class StatisticsRemoteDataSource {
  final Dio dio;

  StatisticsRemoteDataSource({
    required this.dio,
  });

  Future<StatisticsModel> getStatistics({
    required String filterType,
  }) async {
    final response = await dio.get(
      '${ApiConstants.tasks}/statistics',
      queryParameters: {
        'filter': filterType,
      },
    );

    final data = response.data;

    if (data is Map<String, dynamic>) {
      return StatisticsModel(
        totalTasks: data['totalTasks'] ?? 0,
        completedTasks: data['completedTasks'] ?? 0,
        doingTasks: data['doingTasks'] ?? 0,
        todoTasks: data['todoTasks'] ?? 0,
        overdueTasks: data['overdueTasks'] ?? 0,
        filterType: filterType,
      );
    }

    throw Exception('Dữ liệu thống kê không hợp lệ');
  }
}