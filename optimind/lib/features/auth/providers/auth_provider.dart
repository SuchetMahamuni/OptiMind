import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/storage_service.dart';

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
}
