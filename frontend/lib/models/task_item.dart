class TaskItem {
  TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.category,
    required this.dueDate,
    this.categoryId,
  });

  final int id;
  final String title;
  final String description;
  final String priority;
  final String status;
  final String category;
  final DateTime dueDate;
  final int? categoryId;

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    // parse id an toàn — backend có thể trả int, num, hoặc string
    final rawId = json['id'];
    final id = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;

    // category có thể là categoryName (string) hoặc category object
    String categoryName = 'General';
    int? categoryId;

    if (json['categoryName'] != null) {
      categoryName = json['categoryName'].toString();
    }
    if (json['category'] is Map) {
      categoryName = (json['category']['name'] ?? categoryName).toString();
      final catId = json['category']['id'];
      categoryId = catId is int ? catId : int.tryParse(catId.toString());
    }
    if (json['categoryId'] != null) {
      final catId = json['categoryId'];
      categoryId = catId is int ? catId : int.tryParse(catId.toString());
    }

    return TaskItem(
      id: id,
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      priority: (json['priority'] ?? 'MEDIUM').toString(),
      status: (json['status'] ?? 'TODO').toString(),
      category: categoryName,
      categoryId: categoryId,
      dueDate: DateTime.tryParse((json['dueDate'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}
