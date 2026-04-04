import '../datasources/task_remote_data_source.dart';
import '../models/create_task_request_model.dart';
import '../models/task_model.dart';
import '../models/update_task_request_model.dart';

class TaskRepository {
  final TaskRemoteDataSource remoteDataSource;

  TaskRepository({
    required this.remoteDataSource,
  });

  Future<List<TaskModel>> getTasks() async {
    return remoteDataSource.getTasks();
  }

  Future<void> createTask(CreateTaskRequestModel request) async {
    await remoteDataSource.createTask(request);
  }

  Future<void> updateTask({
    required int taskId,
    required UpdateTaskRequestModel request,
  }) async {
    await remoteDataSource.updateTask(
      taskId: taskId,
      request: request,
    );
  }

  Future<void> deleteTask(int taskId) async {
    await remoteDataSource.deleteTask(taskId);
  }
}