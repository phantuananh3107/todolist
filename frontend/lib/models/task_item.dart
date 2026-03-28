class TaskItem {
  TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.category,
    required this.dueDate,
    required this.isCompleted,
  });

  final int id;
  final String title;
  final String description;
  final String priority;
  final String status;
  final String category;
  final DateTime dueDate;
  final bool isCompleted;

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] as int,
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      priority: (json['priority'] ?? 'MEDIUM') as String,
      status: (json['status'] ?? 'TODO') as String,
      category: (json['categoryName'] ?? 'General') as String,
      dueDate: DateTime.tryParse((json['dueDate'] ?? '').toString()) ?? DateTime.now(),
      isCompleted: (json['status'] ?? '') == 'DONE',
    );
  }
}
