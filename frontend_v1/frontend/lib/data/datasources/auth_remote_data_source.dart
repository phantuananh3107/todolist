import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../models/login_request_model.dart';
import '../models/login_response_model.dart';
import '../models/register_request_model.dart';

class AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSource({
    required this.dio,
  });

  Future<LoginResponseModel> login(LoginRequestModel request) async {
    final response = await dio.post(
      ApiConstants.login,
      data: request.toJson(),
    );

    if (response.data is Map<String, dynamic>) {
      return LoginResponseModel.fromJson(response.data as Map<String, dynamic>);
    }

    throw Exception('Dữ liệu đăng nhập không hợp lệ');
  }

  Future<void> register(RegisterRequestModel request) async {
    await dio.post(
      ApiConstants.register,
      data: request.toJson(),
    );
  }

  Future<void> logout() async {
    await dio.post(ApiConstants.logout);
  }
}