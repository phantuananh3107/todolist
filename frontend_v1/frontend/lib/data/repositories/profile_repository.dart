import 'dart:convert';

import '../datasources/profile_remote_data_source.dart';
import '../local/token_storage.dart';
import '../local/user_storage.dart';
import '../models/change_password_request_model.dart';
import '../models/update_profile_request_model.dart';
import '../models/user_model.dart';

class ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;
  final UserStorage userStorage;
  final TokenStorage tokenStorage;

  ProfileRepository({
    required this.remoteDataSource,
    required this.userStorage,
    required this.tokenStorage,
  });

  Future<UserModel> getProfile() async {
    return UserModel(
      id: _extractUserId() ?? 0,
      username: userStorage.username ?? '',
      email: userStorage.email ?? '',
      role: userStorage.role ?? 'USER',
      isActive: true,
    );
  }

  Future<UserModel> updateProfile({
    required String username,
    required String email,
  }) async {
    final userId = _extractUserId();

    if (userId == null) {
      await userStorage.saveUser(
        username: username,
        email: email,
        role: userStorage.role ?? 'USER',
      );
      return getProfile();
    }

    final user = await remoteDataSource.updateProfile(
      userId: userId,
      request: UpdateProfileRequestModel(
        username: username,
        email: email,
      ),
    );

    await userStorage.saveUser(
      username: user.username,
      email: user.email,
      role: user.role,
    );

    return user;
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final userId = _extractUserId();
    if (userId == null) {
      throw Exception('Không đọc được userId từ token đăng nhập');
    }

    await remoteDataSource.changePassword(
      userId: userId,
      request: ChangePasswordRequestModel(
        oldPassword: oldPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      ),
    );
  }

  int? _extractUserId() {
    final token = tokenStorage.accessToken;
    if (token == null || token.isEmpty) return null;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      return int.tryParse(map['sub']?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }
}
