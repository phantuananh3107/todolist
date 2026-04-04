import 'auth_tokens_model.dart';
import 'auth_user_model.dart';

class LoginResponseModel {
  final AuthTokensModel tokens;
  final AuthUserModel user;

  const LoginResponseModel({
    required this.tokens,
    required this.user,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      tokens: AuthTokensModel.fromJson(json),
      user: AuthUserModel.fromJson(json),
    );
  }
}