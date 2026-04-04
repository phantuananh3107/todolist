import '../datasources/reminder_remote_data_source.dart';
import '../models/create_reminder_request_model.dart';
import '../models/reminder_model.dart';

class ReminderRepository {
  final ReminderRemoteDataSource remoteDataSource;

  ReminderRepository({
    required this.remoteDataSource,
  });

  Future<List<ReminderModel>> getRemindersByTask(int taskId) async {
    return remoteDataSource.getRemindersByTask(taskId);
  }

  Future<void> createReminder({
    required int taskId,
    required String remindTime,
  }) async {
    await remoteDataSource.createReminder(
      CreateReminderRequestModel(
        taskId: taskId,
        remindTime: remindTime,
      ),
    );
  }

  Future<void> deleteReminder(int reminderId) async {
    await remoteDataSource.deleteReminder(reminderId);
  }
}