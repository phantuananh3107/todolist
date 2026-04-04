import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../models/change_password_request_model.dart';
import '../models/update_profile_request_model.dart';
import '../models/user_model.dart';

class ProfileRemoteDataSource {
  final Dio dio;

  ProfileRemoteDataSource({
    required this.dio,
  });

  Future<UserModel> updateProfile({
    required int userId,
    required UpdateProfileRequestModel request,
  }) async {
    final response = await dio.patch(
      ApiConstants.profile(userId),
      data: request.toJson(),
    );

    if (response.data is Map<String, dynamic>) {
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    }

    throw Exception('Dữ liệu cập nhật profile không hợp lệ');
  }

  Future<void> changePassword({
    required int userId,
    required ChangePasswordRequestModel request,
  }) async {
    await dio.patch(
      ApiConstants.changePassword(userId),
      data: request.toJson(),
    );
  }
}