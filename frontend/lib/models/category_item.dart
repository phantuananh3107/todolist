class CategoryItem {
  CategoryItem({required this.id, required this.name, required this.taskCount, this.colorHex});

  final int id;
  final String name;
  final int taskCount;
  final String? colorHex;

  CategoryItem copyWith({int? id, String? name, int? taskCount, String? colorHex}) {
    return CategoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      taskCount: taskCount ?? this.taskCount,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;

    final rawCount = json['taskCount'];
    final taskCount = rawCount is int ? rawCount : int.tryParse((rawCount ?? '0').toString()) ?? 0;

    return CategoryItem(
      id: id,
      name: (json['name'] ?? 'General').toString(),
      taskCount: taskCount,
      colorHex: json['colorHex']?.toString(),
    );
  }
}
