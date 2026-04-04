import 'package:flutter/material.dart';

import '../../../data/local/token_storage.dart';
import '../../../data/local/user_storage.dart';
import '../../../data/models/auth_tokens_model.dart';
import '../../../data/models/auth_user_model.dart';
import '../../../data/models/login_response_model.dart';
import '../../../data/repositories/auth_repository.dart';

class AuthController extends ChangeNotifier {
  final AuthRepository repository;
  final TokenStorage tokenStorage;
  final UserStorage userStorage;

  AuthController({
    required this.repository,
    required this.tokenStorage,
    required this.userStorage,
  });

  bool _isLoading = false;
  bool _isCheckingSession = false;
  String? _errorMessage;
  LoginResponseModel? _loginResponse;

  bool get isLoading => _isLoading;
  bool get isCheckingSession => _isCheckingSession;
  String? get errorMessage => _errorMessage;
  LoginResponseModel? get loginResponse => _loginResponse;
  bool get isLoggedIn => _loginResponse != null;

  Future<void> restoreSession() async {
    _isCheckingSession = true;
    notifyListeners();

    try {
      if (!tokenStorage.hasAccessToken) {
        _loginResponse = null;
        return;
      }

      final username = userStorage.username ?? '';
      final email = userStorage.email ?? '';
      final role = userStorage.role ?? 'USER';

      _loginResponse = LoginResponseModel(
        tokens: AuthTokensModel(
          accessToken: tokenStorage.accessToken ?? '',
          refreshToken: tokenStorage.refreshToken ?? '',
        ),
        user: AuthUserModel(
          username: username,
          email: email,
          role: role,
        ),
      );
    } finally {
      _isCheckingSession = false;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _loginResponse = await repository.login(
        email: email,
        password: password,
      );
      return true;
    } catch (e) {
      _errorMessage = _mapError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await repository.register(
        username: username,
        email: email,
        password: password,
      );
      return true;
    } catch (e) {
      _errorMessage = _mapError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await repository.logout();
    } finally {
      _loginResponse = null;
      _errorMessage = null;
      notifyListeners();
    }
  }

  String _mapError(Object error) {
    final message = error.toString();
    if (message.contains('DioException')) {
      return 'Không thể kết nối server hoặc dữ liệu không hợp lệ';
    }
    return message;
  }
}