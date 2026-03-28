class CategoryItem {
  CategoryItem({required this.id, required this.name, required this.taskCount});

  final int id;
  final String name;
  final int taskCount;

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    // parse an toàn, tránh crash nếu backend trả kiểu khác
    final rawId = json['id'];
    final id = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;

    final rawCount = json['taskCount'];
    final taskCount = rawCount is int ? rawCount : int.tryParse((rawCount ?? '0').toString()) ?? 0;

    return CategoryItem(
      id: id,
      name: (json['name'] ?? 'General').toString(),
      taskCount: taskCount,
    );
  }
}
