import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../data/local/token_storage.dart';
import 'auth_interceptor.dart';

class DioClient {
  static Dio create({
    required TokenStorage tokenStorage,
  }) {
    final baseUrl = dotenv.env['BASE_URL'] ?? '';
    final connectTimeout = int.tryParse(
          dotenv.env['CONNECT_TIMEOUT'] ?? '30000',
        ) ??
        30000;
    final receiveTimeout = int.tryParse(
          dotenv.env['RECEIVE_TIMEOUT'] ?? '30000',
        ) ??
        30000;

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: Duration(milliseconds: connectTimeout),
        receiveTimeout: Duration(milliseconds: receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      AuthInterceptor(tokenStorage: tokenStorage),
    );

    return dio;
  }
}