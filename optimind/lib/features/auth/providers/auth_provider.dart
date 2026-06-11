import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../services/update_service.dart';
import '../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/storage_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  // Updates Provider values
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;

  final UpdateService _updateService = UpdateService();

  // Initialize Auth State
  Future<void> init() async {
    final userData = await _storageService.getUser();
    if (userData != null) {
      _user = UserModel.fromJson(json.decode(userData));
      notifyListeners();
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;
    
    final result = await _authService.login(email, password);
    
    if (result['success']) {
      _user = UserModel.fromJson(result['user']);
      _setLoading(false);
      return true;
    } else {
      _error = result['message'];
      _setLoading(false);
      return false;
    }
  }

  // Register
  Future<bool> register(String name, String email, String password) async {
    _setLoading(true);
    _error = null;
    
    final result = await _authService.register(name, email, password);
    
    if (result['success']) {
      _user = UserModel.fromJson(result['user']);
      _setLoading(false);
      return true;
    } else {
      _error = result['message'];
      _setLoading(false);
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<Map<String, dynamic>> checkUpdate() async {
    final result = await _authService.checkUpdate();
    // Obtain current app version
    final packageInfo = await PackageInfo.fromPlatform();
    // Compare current version with update version
    if (isUpdateAvailable(packageInfo.version, result['latest_version'])) {
      return {'update_available':true, 'data':result};
    }
    else{
      return {'update_available': false, 'data': null};
    }
  }

  bool isUpdateAvailable(String currentVersion, String latestVersion) {
    final current = currentVersion.split('.').map(int.parse).toList();
    final latest = latestVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      if (latest[i] > current[i]) return true;
      if (latest[i] < current[i]) return false;
    }
    return false;
  }

  Future<void> installUpdate(String apkUrl) async {
    try {
      _isDownloading = true;
      _downloadProgress = 0;

      notifyListeners();

      await _updateService.downloadAndInstallApk(
        apkUrl: apkUrl,
        onProgress: (progress) {
          _downloadProgress = progress;

          notifyListeners();
        },
      );
    } finally {
      _isDownloading = false;

      notifyListeners();
    }
  }
}
