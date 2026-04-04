import '../../shared/enums/task_status.dart';

class TaskHelpers {
  static bool isCompleted(TaskStatus status) => status == TaskStatus.done;
}
