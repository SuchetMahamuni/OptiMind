import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class StorageService {
  final _secureStorage = const FlutterSecureStorage();
  
  // Initialize Hive
  static Future<void> initHive() async {
    await Hive.initFlutter();
    await Hive.openBox(AppConstants.userBox);
    await Hive.openBox(AppConstants.tasksBox);
    await Hive.openBox(AppConstants.sessionsBox);
    await Hive.openBox(AppConstants.settingsBox);
  }

  // Tokens
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: AppConstants.tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: AppConstants.tokenKey);
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(key: AppConstants.tokenKey);
  }

  // User Data
  Future<void> saveUser(String userDataJson) async {
    await Hive.box(AppConstants.userBox).put(AppConstants.userKey, userDataJson);
  }

  Future<String?> getUser() async {
    return Hive.box(AppConstants.userBox).get(AppConstants.userKey);
  }

  Future<void> deleteUser() async {
    await Hive.box(AppConstants.userBox).delete(AppConstants.userKey);
  }

  // Theme Persistence
  Future<void> saveTheme(bool isDark) async {
    await Hive.box(AppConstants.settingsBox).put(AppConstants.themeKey, isDark);
  }

  bool getTheme() {
    return Hive.box(AppConstants.settingsBox).get(AppConstants.themeKey, defaultValue: true);
  }

  // Custom Goal Persistence
  Future<void> saveCustomGoal(int minutes) async {
    await Hive.box(AppConstants.settingsBox).put(AppConstants.customGoalKey, minutes);
  }

  int getCustomGoal() {
    return Hive.box(AppConstants.settingsBox).get(AppConstants.customGoalKey, defaultValue: 120);
  }

  Future<void> saveUseAdaptiveGoal(bool useAdaptive) async {
    await Hive.box(AppConstants.settingsBox).put(AppConstants.useAdaptiveGoalKey, useAdaptive);
  }

  bool getUseAdaptiveGoal() {
    return Hive.box(AppConstants.settingsBox).get(AppConstants.useAdaptiveGoalKey, defaultValue: true);
  }

  // Clear All
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    await Hive.box(AppConstants.userBox).clear();
    await Hive.box(AppConstants.tasksBox).clear();
    await Hive.box(AppConstants.sessionsBox).clear();
    // SharedPreferences onboarding reset if needed
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.onboardingKey);
  }
}
