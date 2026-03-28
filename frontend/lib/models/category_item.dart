class CategoryItem {
  CategoryItem({required this.id, required this.name, required this.taskCount});

  final int id;
  final String name;
  final int taskCount;

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: json['id'] as int,
      name: (json['name'] ?? 'General') as String,
      taskCount: (json['taskCount'] ?? 0) as int,
    );
  }
}
