import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/storage_keys.dart';

class AppPreferences {
  final SharedPreferences _prefs;

  AppPreferences(this._prefs);

  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  bool getBool(String key) {
    return _prefs.getBool(key) ?? false;
  }

  Future<void> setEnableNotifications(bool value) async {
    await _prefs.setBool(StorageKeys.enableNotifications, value);
  }

  bool get enableNotifications =>
      _prefs.getBool(StorageKeys.enableNotifications) ?? true;

  Future<void> setEnableDarkMode(bool value) async {
    await _prefs.setBool(StorageKeys.enableDarkMode, value);
  }

  bool get enableDarkMode =>
      _prefs.getBool(StorageKeys.enableDarkMode) ?? false;

  Future<void> setRememberLogin(bool value) async {
    await _prefs.setBool(StorageKeys.rememberLogin, value);
  }

  bool get rememberLogin =>
      _prefs.getBool(StorageKeys.rememberLogin) ?? true;
}