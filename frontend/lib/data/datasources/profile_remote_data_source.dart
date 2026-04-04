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

  Future<UserModel> getProfile() async {
    final response = await dio.get(ApiConstants.profile);

    if (response.data is Map<String, dynamic>) {
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    }

    throw Exception('Dữ liệu profile không hợp lệ');
  }

  Future<UserModel> updateProfile(UpdateProfileRequestModel request) async {
    final response = await dio.put(
      ApiConstants.profile,
      data: request.toJson(),
    );

    if (response.data is Map<String, dynamic>) {
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    }

    throw Exception('Dữ liệu cập nhật profile không hợp lệ');
  }

  Future<void> changePassword(ChangePasswordRequestModel request) async {
    await dio.put(
      ApiConstants.changePassword,
      data: request.toJson(),
    );
  }
}