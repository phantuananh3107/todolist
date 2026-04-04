import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../models/create_task_request_model.dart';
import '../models/task_model.dart';
import '../models/update_task_request_model.dart';

class TaskRemoteDataSource {
  final Dio dio;

  TaskRemoteDataSource({
    required this.dio,
  });

  Future<List<TaskModel>> getTasks() async {
    final response = await dio.get(ApiConstants.tasks);
    final data = response.data;

    if (data is List) {
      return data
          .map((item) => TaskModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    if (data is Map<String, dynamic>) {
      if (data['data'] is List) {
        return (data['data'] as List)
            .map((item) => TaskModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      if (data['content'] is List) {
        return (data['content'] as List)
            .map((item) => TaskModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }

    return [];
  }

  Future<TaskModel> getTaskDetail(int taskId) async {
    final response = await dio.get(ApiConstants.taskDetail(taskId));

    if (response.data is Map<String, dynamic>) {
      return TaskModel.fromJson(response.data as Map<String, dynamic>);
    }

    throw Exception('Dữ liệu task detail không hợp lệ');
  }

  Future<void> createTask(CreateTaskRequestModel request) async {
    await dio.post(
      ApiConstants.tasks,
      data: request.toJson(),
    );
  }

  Future<void> updateTask({
    required int taskId,
    required UpdateTaskRequestModel request,
  }) async {
    await dio.patch(
      ApiConstants.taskDetail(taskId),
      data: request.toJson(),
    );
  }

  Future<void> deleteTask(int taskId) async {
    await dio.delete(ApiConstants.taskDetail(taskId));
  }
}
