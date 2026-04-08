class ReminderItem {
  ReminderItem({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    required this.remindTime,
    this.taskDueDate,
  });

  final int id;
  final int taskId;
  final String taskTitle;
  final DateTime remindTime;
  final DateTime? taskDueDate;

  factory ReminderItem.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawTaskId = json['taskId'];
    return ReminderItem(
      id: rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0,
      taskId: rawTaskId is int ? rawTaskId : int.tryParse(rawTaskId.toString()) ?? 0,
      taskTitle: (json['taskTitle'] ?? '').toString(),
      remindTime: DateTime.tryParse((json['remindTime'] ?? '').toString()) ?? DateTime.now(),
      taskDueDate: json['taskDueDate'] == null ? null : DateTime.tryParse(json['taskDueDate'].toString()),
    );
  }
}
