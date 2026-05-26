class AdminUserItem {
  AdminUserItem({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.isActive,
    required this.isDeleted,
    required this.categoryCount,
    required this.taskCount,
  });

  final int id;
  final String username;
  final String email;
  final String role;
  final bool isActive;
  final bool isDeleted;
  final int categoryCount;
  final int taskCount;

  factory AdminUserItem.fromJson(Map<String, dynamic> json) {
    int _int(dynamic value) => value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;
    final categories = (json['categories'] as List?) ?? const [];
    int taskCount = 0;
    for (final category in categories) {
      if (category is Map<String, dynamic>) {
        taskCount += _int(category['taskCount']);
      } else if (category is Map) {
        taskCount += _int(category['taskCount']);
      }
    }
    return AdminUserItem(
      id: _int(json['id']),
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'USER').toString(),
      isActive: json['isActive'] != false,
      isDeleted: json['isDeleted'] == true,
      categoryCount: categories.length,
      taskCount: taskCount,
    );
  }
}
