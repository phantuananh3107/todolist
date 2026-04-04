import 'package:flutter/material.dart';

import '../../../data/models/statistics_model.dart';
import '../../../data/repositories/statistics_repository.dart';
import '../../../shared/enums/task_status.dart';
import 'task_controller.dart';

class StatisticsController extends ChangeNotifier {
  final StatisticsRepository? repository;

  StatisticsController({
    this.repository,
  });

  String _filterType = 'day';
  bool _isLoading = false;
  String? _errorMessage;
  StatisticsModel? _remoteStats;

  String get filterType => _filterType;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  StatisticsModel? get remoteStats => _remoteStats;

  void changeFilter(String value) {
    _filterType = value;
    notifyListeners();
  }

  StatisticsModel buildFromTasks(TaskController taskController) {
    final tasks = taskController.tasks;

    final total = tasks.length;
    final completed = tasks.where((e) => e.status == TaskStatus.done).length;
    final doing = tasks.where((e) => e.status == TaskStatus.doing).length;
    final todo = tasks.where((e) => e.status == TaskStatus.todo).length;
    final overdue = tasks.where((e) => e.status == TaskStatus.overdue).length;

    return StatisticsModel.fromTasks(
      totalTasks: total,
      completedTasks: completed,
      doingTasks: doing,
      todoTasks: todo,
      overdueTasks: overdue,
      filterType: _filterType,
    );
  }

  Future<void> fetchRemoteStatistics() async {
    if (repository == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _remoteStats = await repository!.getStatistics(
        filterType: _filterType,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}