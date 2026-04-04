import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/storage_keys.dart';

class UserStorage {
  final SharedPreferences _prefs;

  UserStorage(this._prefs);

  Future<void> saveUser({
    required String username,
    required String email,
    required String role,
  }) async {
    await _prefs.setString(StorageKeys.savedUsername, username);
    await _prefs.setString(StorageKeys.savedEmail, email);
    await _prefs.setString(StorageKeys.savedRole, role);
  }

  String? get username => _prefs.getString(StorageKeys.savedUsername);
  String? get email => _prefs.getString(StorageKeys.savedEmail);
  String? get role => _prefs.getString(StorageKeys.savedRole);

  Future<void> clear() async {
    await _prefs.remove(StorageKeys.savedUsername);
    await _prefs.remove(StorageKeys.savedEmail);
    await _prefs.remove(StorageKeys.savedRole);
  }
}