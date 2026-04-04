import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/storage_keys.dart';

class TokenStorage {
  final SharedPreferences _prefs;

  TokenStorage(this._prefs);

  Future<void> saveAccessToken(String token) async {
    await _prefs.setString(StorageKeys.accessToken, token);
  }

  Future<void> saveRefreshToken(String token) async {
    await _prefs.setString(StorageKeys.refreshToken, token);
  }

  String? get accessToken => _prefs.getString(StorageKeys.accessToken);
  String? get refreshToken => _prefs.getString(StorageKeys.refreshToken);

  bool get hasAccessToken {
    final token = accessToken;
    return token != null && token.isNotEmpty;
  }

  Future<void> clear() async {
    await _prefs.remove(StorageKeys.accessToken);
    await _prefs.remove(StorageKeys.refreshToken);
  }
}