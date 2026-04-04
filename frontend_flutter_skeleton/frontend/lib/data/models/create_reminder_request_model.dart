class CreateReminderRequestModel {
  final int taskId;
  final String remindTime;

  const CreateReminderRequestModel({
    required this.taskId,
    required this.remindTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'task_id': taskId,
      'remind_time': remindTime,
    };
  }
}