import 'dart:convert';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _apiService.post('auth/login', {
      'email': email,
      'password': password,
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final token = data['access_token'];
      final user = data['user'];
      
      await _storageService.saveToken(token);
      await _storageService.saveUser(json.encode(user));
      
      return {'success': true, 'user': user};
    } else {
      final error = json.decode(response.body)['error'] ?? 'Login failed';
      return {'success': false, 'message': error};
    }
  }

  // Register
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await _apiService.post('auth/register', {
      'name': name, // Flask backend expects 'username' probably
      'email': email,
      'password': password,
    });

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      final token = data['access_token'];
      final user = data['user'];
      
      await _storageService.saveToken(token);
      await _storageService.saveUser(json.encode(user));
      
      return {'success': true, 'user': user};
    } else {
      final error = json.decode(response.body)['error'] ?? 'Registration failed';
      return {'success': false, 'message': error};
    }
  }

  // Logout
  Future<void> logout() async {
    await _storageService.clearAll();
  }

  // Check Auth Status
  Future<bool> isAuthenticated() async {
    final token = await _storageService.getToken();
    return token != null;
  }
}
