class CreateTaskRequestModel {
  final String title;
  final String? description;
  final String priority;
  final String status;
  final String? dueDate;
  final int? categoryId;

  const CreateTaskRequestModel({
    required this.title,
    this.description,
    required this.priority,
    required this.status,
    this.dueDate,
    this.categoryId,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      'due_date': dueDate,
      'category_id': categoryId,
    };
  }
}