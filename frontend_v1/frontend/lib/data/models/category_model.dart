class CategoryModel {
  final int id;
  final String name;
  final int? userId;
  final bool isActive;

  const CategoryModel({
    required this.id,
    required this.name,
    this.userId,
    this.isActive = true,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      userId: json['userId'] ?? json['user_id'],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'user_id': userId,
      'isActive': isActive,
    };
  }
}