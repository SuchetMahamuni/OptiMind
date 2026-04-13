import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  final _storage = const FlutterSecureStorage();
  
  // Headers with Auth
  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // GET
  Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${AppConstants.baseUrl}/$endpoint');
    return await http.get(url, headers: headers);
  }

  // POST
  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${AppConstants.baseUrl}/$endpoint');
    return await http.post(url, headers: headers, body: json.encode(body));
  }

  // PUT
  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${AppConstants.baseUrl}/$endpoint');
    return await http.put(url, headers: headers, body: json.encode(body));
  }

  // PATCH
  Future<http.Response> patch(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${AppConstants.baseUrl}/$endpoint');
    return await http.patch(url, headers: headers, body: json.encode(body));
  }

  // DELETE
  Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${AppConstants.baseUrl}/$endpoint');
    return await http.delete(url, headers: headers);
  }
}
