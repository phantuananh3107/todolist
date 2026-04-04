import 'package:flutter/material.dart';

import '../../../data/models/create_task_request_model.dart';
import '../../../data/models/update_task_request_model.dart';
import '../../../data/repositories/task_repository.dart';

class TaskFormController extends ChangeNotifier {
  final TaskRepository repository;

  TaskFormController({
    required this.repository,
  });

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> createTask({
    required String title,
    String? description,
    required String priority,
    required String status,
    String? dueDate,
    int? categoryId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await repository.createTask(
        CreateTaskRequestModel(
          title: title,
          description: description,
          priority: priority,
          status: status,
          dueDate: dueDate,
          categoryId: categoryId,
        ),
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateTask({
    required int taskId,
    required String title,
    String? description,
    required String priority,
    required String status,
    String? dueDate,
    int? categoryId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await repository.updateTask(
        taskId: taskId,
        request: UpdateTaskRequestModel(
          title: title,
          description: description,
          priority: priority,
          status: status,
          dueDate: dueDate,
          categoryId: categoryId,
        ),
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteTask(int taskId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await repository.deleteTask(taskId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}