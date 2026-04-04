class AuthUserModel {
  final String username;
  final String email;
  final String role;

  const AuthUserModel({
    required this.username,
    required this.email,
    required this.role,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'USER',
    );
  }
}