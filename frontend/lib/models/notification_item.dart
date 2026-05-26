class NotificationItem {
  NotificationItem({
    required this.id,
    required this.message,
    required this.isRead,
    this.taskId,
    this.remindTime,
    this.createdAt,
  });

  final int id;
  final String message;
  final bool isRead;
  final int? taskId;
  final DateTime? remindTime;
  final DateTime? createdAt;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    int? _int(dynamic value) => value is int ? value : int.tryParse(value?.toString() ?? '');

    return NotificationItem(
      id: _int(json['id']) ?? 0,
      message: (json['message'] ?? '').toString(),
      isRead: json['isRead'] == true,
      taskId: _int(json['taskId']),
      remindTime: DateTime.tryParse((json['remindTime'] ?? '').toString()),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
    );
  }
}
