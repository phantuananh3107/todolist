import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../models/create_reminder_request_model.dart';
import '../models/reminder_model.dart';

class ReminderRemoteDataSource {
  final Dio dio;

  ReminderRemoteDataSource({
    required this.dio,
  });

  Future<List<ReminderModel>> getRemindersByTask(int taskId) async {
    final response = await dio.get(ApiConstants.remindersByTask(taskId));
    final data = response.data;

    if (data is List) {
      return data
          .map((item) => ReminderModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    if (data is Map<String, dynamic> && data['data'] is List) {
      return (data['data'] as List)
          .map((item) => ReminderModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  Future<void> createReminder(CreateReminderRequestModel request) async {
    await dio.post(
      ApiConstants.reminders,
      data: request.toJson(),
    );
  }

  Future<void> deleteReminder(int reminderId) async {
    await dio.delete(ApiConstants.reminderDetail(reminderId));
  }
}