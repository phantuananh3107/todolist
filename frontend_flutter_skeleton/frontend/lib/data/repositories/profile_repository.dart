import '../datasources/profile_remote_data_source.dart';
import '../models/change_password_request_model.dart';
import '../models/update_profile_request_model.dart';
import '../models/user_model.dart';

class ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepository({
    required this.remoteDataSource,
  });

  Future<UserModel> getProfile() async {
    return remoteDataSource.getProfile();
  }

  Future<UserModel> updateProfile({
    required String username,
    required String email,
  }) async {
    return remoteDataSource.updateProfile(
      UpdateProfileRequestModel(
        username: username,
        email: email,
      ),
    );
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await remoteDataSource.changePassword(
      ChangePasswordRequestModel(
        oldPassword: oldPassword,
        newPassword: newPassword,
      ),
    );
  }
}