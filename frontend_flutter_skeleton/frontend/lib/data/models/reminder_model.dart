class ReminderModel {
  final int id;
  final int taskId;
  final DateTime remindTime;

  const ReminderModel({
    required this.id,
    required this.taskId,
    required this.remindTime,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'] ?? 0,
      taskId: json['task_id'] ?? 0,
      remindTime: DateTime.parse(json['remind_time'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'remind_time': remindTime.toIso8601String(),
    };
  }
}