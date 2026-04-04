import '../../shared/enums/task_priority.dart';
import '../../shared/enums/task_status.dart';

class TaskModel {
  final int id;
  final String title;
  final String? description;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime? dueDate;
  final int? userId;
  final int? categoryId;
  final DateTime? createdAt;
  final bool isActive;

  const TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.priority,
    required this.status,
    this.dueDate,
    this.userId,
    this.categoryId,
    this.createdAt,
    this.isActive = true,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
  return TaskModel(
    id: json['id'] ?? 0,
    title: json['title'] ?? '',
    description: json['description'],
    priority: _mapPriority(json['priority']),
    status: _mapStatus(json['status']),
    dueDate: json['dueDate'] != null
        ? DateTime.tryParse(json['dueDate'].toString())
        : (json['due_date'] != null
            ? DateTime.tryParse(json['due_date'].toString())
            : null),
    userId: json['userId'] ?? json['user_id'],
    categoryId: json['categoryId'] ?? json['category_id'] ?? json['Category_id'],
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'].toString())
        : (json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null),
    isActive: json['isActive'] ?? true,
  );
}

  Map<String, dynamic> toJson() {
  return {
    'id': id,
    'title': title,
    'description': description,
    'priority': priority.name.toUpperCase(),
    'status': status.name.toUpperCase(),
    'dueDate': dueDate?.toIso8601String(),
    'userId': userId,
    'categoryId': categoryId,
    'createdAt': createdAt?.toIso8601String(),
    'isActive': isActive,
  };
}

  static TaskPriority _mapPriority(dynamic value) {
    switch ((value ?? '').toString().toUpperCase()) {
      case 'LOW':
        return TaskPriority.low;
      case 'HIGH':
        return TaskPriority.high;
      default:
        return TaskPriority.medium;
    }
  }

  static TaskStatus _mapStatus(dynamic value) {
    switch ((value ?? '').toString().toUpperCase()) {
      case 'DOING':
        return TaskStatus.doing;
      case 'DONE':
        return TaskStatus.done;
      case 'OVERDUE':
        return TaskStatus.overdue;
      default:
        return TaskStatus.todo;
    }
  }
}