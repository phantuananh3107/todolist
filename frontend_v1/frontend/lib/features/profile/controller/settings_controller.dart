import 'package:flutter/material.dart';

import '../../../data/local/app_preferences.dart';

class SettingsController extends ChangeNotifier {
  final AppPreferences appPreferences;

  SettingsController({
    required this.appPreferences,
  });

  bool _isLoading = true;
  bool _enableNotifications = true;
  bool _enableDarkMode = false;
  bool _rememberLogin = true;

  bool get isLoading => _isLoading;
  bool get enableNotifications => _enableNotifications;
  bool get enableDarkMode => _enableDarkMode;
  bool get rememberLogin => _rememberLogin;

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    _enableNotifications = appPreferences.enableNotifications;
    _enableDarkMode = appPreferences.enableDarkMode;
    _rememberLogin = appPreferences.rememberLogin;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateEnableNotifications(bool value) async {
    _enableNotifications = value;
    notifyListeners();
    await appPreferences.setEnableNotifications(value);
  }

  Future<void> updateEnableDarkMode(bool value) async {
    _enableDarkMode = value;
    notifyListeners();
    await appPreferences.setEnableDarkMode(value);
  }

  Future<void> updateRememberLogin(bool value) async {
    _rememberLogin = value;
    notifyListeners();
    await appPreferences.setRememberLogin(value);
  }
}