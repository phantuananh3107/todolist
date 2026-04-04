class UserModel {
  final int id;
  final String username;
  final String email;
  final String role;
  final DateTime? createdAt;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.createdAt,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'USER',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : (json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString())
              : null),
      isActive: json['isActive'] ?? json['active'] ?? true,
    );
  }
}
