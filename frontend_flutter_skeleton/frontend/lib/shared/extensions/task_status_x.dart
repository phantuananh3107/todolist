import '../enums/task_status.dart';

extension TaskStatusX on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.todo:
        return 'To-do';
      case TaskStatus.doing:
        return 'Doing';
      case TaskStatus.done:
        return 'Done';
      case TaskStatus.overdue:
        return 'Overdue';
    }
  }
}
