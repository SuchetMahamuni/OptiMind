import 'package:flutter/material.dart';
import '../../../services/storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  bool _isDarkMode = true;
  int _customGoalMinutes = 120; // Default 2 hours
  bool _useAdaptiveGoal = true;

  bool get isDarkMode => _isDarkMode;
  int get customGoalMinutes => _customGoalMinutes;
  bool get useAdaptiveGoal => _useAdaptiveGoal;

  SettingsProvider() {
    _loadSettings();
  }

  void _loadSettings() {
    _isDarkMode = _storageService.getTheme();
    _customGoalMinutes = _storageService.getCustomGoal();
    _useAdaptiveGoal = _storageService.getUseAdaptiveGoal();
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _storageService.saveTheme(_isDarkMode);
    notifyListeners();
  }

  void setCustomGoal(int minutes) {
    if (minutes < 15 || minutes > 1440) return; // 15m min, 24h max
    _customGoalMinutes = minutes;
    _storageService.saveCustomGoal(minutes);
    notifyListeners();
  }

  void setUseAdaptiveGoal(bool value) {
    _useAdaptiveGoal = value;
    _storageService.saveUseAdaptiveGoal(value);
    notifyListeners();
  }

  Future<void> clearAllData() async {
    await _storageService.clearAll();
    _loadSettings(); // Reset to defaults
    notifyListeners();
  }
}
