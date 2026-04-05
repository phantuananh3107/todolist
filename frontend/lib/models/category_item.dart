class CategoryItem {
  CategoryItem({
    required this.id,
    required this.name,
    required this.taskCount,
    this.color = '#3B82F6',
  });

  final int id;
  final String name;
  final int taskCount;
  final String color;

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;

    final rawCount = json['taskCount'];
    final taskCount = rawCount is int ? rawCount : int.tryParse((rawCount ?? '0').toString()) ?? 0;

    final colorValue = json['color'] ?? '#3B82F6';
    final color = colorValue.toString();

    return CategoryItem(
      id: id,
      name: (json['name'] ?? 'General').toString(),
      taskCount: taskCount,
      color: color,
    );
  }
}
