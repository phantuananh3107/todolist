class UpdateProfileRequestModel {
  final String username;
  final String email;

  const UpdateProfileRequestModel({
    required this.username,
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
    };
  }
}