class ChangePasswordRequestModel {
  final String oldPassword;
  final String newPassword;

  const ChangePasswordRequestModel({
    required this.oldPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    };
  }
}