import 'package:dio/dio.dart';

import '../../data/local/token_storage.dart';

class AuthInterceptor extends Interceptor {
  final TokenStorage tokenStorage;

  AuthInterceptor({
    required this.tokenStorage,
  });

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final token = tokenStorage.accessToken;
    final path = options.path;

    final isAuthEndpoint =
        path.endsWith('/users/login') ||
        path.endsWith('/users/register');

    if (!isAuthEndpoint && token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    super.onRequest(options, handler);
  }
}