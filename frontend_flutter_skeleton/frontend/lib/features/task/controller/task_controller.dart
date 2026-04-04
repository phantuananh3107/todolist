import 'package:flutter/material.dart';

import '../../../data/models/task_model.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../shared/enums/task_priority.dart';
import '../../../shared/enums/task_status.dart';

enum TaskSortType {
  newest,
  dueDateAsc,
  dueDateDesc,
}

class TaskController extends ChangeNotifier {
  final TaskRepository repository;

  TaskController({
    required this.repository,
  });

  bool _isLoading = false;
  String? _errorMessage;
  List<TaskModel> _tasks = const [];
  String _searchKeyword = '';

  TaskStatus? _selectedStatus;
  TaskPriority? _selectedPriority;
  TaskSortType _sortType = TaskSortType.newest;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchKeyword => _searchKeyword;
  TaskStatus? get selectedStatus => _selectedStatus;
  TaskPriority? get selectedPriority => _selectedPriority;
  TaskSortType get sortType => _sortType;

  List<TaskModel> get tasks {
    List<TaskModel> result = List.from(_tasks);

    if (_searchKeyword.trim().isNotEmpty) {
      final keyword = _searchKeyword.toLowerCase().trim();
      result = result.where((task) {
        final title = task.title.toLowerCase();
        final description = (task.description ?? '').toLowerCase();
        return title.contains(keyword) || description.contains(keyword);
      }).toList();
    }

    if (_selectedStatus != null) {
      result = result.where((task) => task.status == _selectedStatus).toList();
    }

    if (_selectedPriority != null) {
      result = result.where((task) => task.priority == _selectedPriority).toList();
    }

    switch (_sortType) {
      case TaskSortType.newest:
        result.sort((a, b) {
          final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });
        break;
      case TaskSortType.dueDateAsc:
        result.sort((a, b) {
          final aTime = a.dueDate ?? DateTime(2100);
          final bTime = b.dueDate ?? DateTime(2100);
          return aTime.compareTo(bTime);
        });
        break;
      case TaskSortType.dueDateDesc:
        result.sort((a, b) {
          final aTime = a.dueDate ?? DateTime(1900);
          final bTime = b.dueDate ?? DateTime(1900);
          return bTime.compareTo(aTime);
        });
        break;
    }

    return result;
  }

  Future<void> fetchTasks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tasks = await repository.getTasks();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshTasks() async {
    await fetchTasks();
  }

  void updateSearchKeyword(String value) {
    _searchKeyword = value;
    notifyListeners();
  }

  void clearSearch() {
    _searchKeyword = '';
    notifyListeners();
  }

  void setStatusFilter(TaskStatus? status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void setPriorityFilter(TaskPriority? priority) {
    _selectedPriority = priority;
    notifyListeners();
  }

  void setSortType(TaskSortType sortType) {
    _sortType = sortType;
    notifyListeners();
  }

  void clearFilters() {
    _selectedStatus = null;
    _selectedPriority = null;
    _sortType = TaskSortType.newest;
    notifyListeners();
  }
}