import '../datasources/auth_remote_data_source.dart';
import '../local/token_storage.dart';
import '../local/user_storage.dart';
import '../models/login_request_model.dart';
import '../models/login_response_model.dart';
import '../models/register_request_model.dart';

class AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final TokenStorage tokenStorage;
  final UserStorage userStorage;

  AuthRepository({
    required this.remoteDataSource,
    required this.tokenStorage,
    required this.userStorage,
  });

  Future<LoginResponseModel> login({
    required String email,
    required String password,
  }) async {
    final response = await remoteDataSource.login(
      LoginRequestModel(
        email: email,
        password: password,
      ),
    );

    await tokenStorage.saveAccessToken(response.tokens.accessToken);
    await tokenStorage.saveRefreshToken(response.tokens.refreshToken);

    await userStorage.saveUser(
      username: response.user.username,
      email: response.user.email,
      role: response.user.role,
    );

    return response;
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    await remoteDataSource.register(
      RegisterRequestModel(
        username: username,
        email: email,
        password: password,
      ),
    );
  }

  Future<void> logout() async {
    try {
      await remoteDataSource.logout();
    } catch (_) {
      // bỏ qua lỗi server logout
    } finally {
      await tokenStorage.clear();
      await userStorage.clear();
    }
  }
}