import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../models/dashboard_data.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  DashboardData? _data;
  bool _isLoading = false;
  String? _error;

  DashboardData? get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Parallel API calls
      final responses = await Future.wait([
        _apiService.get('focus-score'),
        _apiService.get('daily-goal'),
        _apiService.get('nudge'),
        _apiService.get('dashboard/summary'),
      ]);

      // Basic error check
      for (var response in responses) {
        if (response.statusCode != 200) {
          throw Exception('Error fetching dashboard components');
        }
      }

      final focusJson = json.decode(responses[0].body);
      final goalJson = json.decode(responses[1].body);
      final nudgeJson = json.decode(responses[2].body);
      final summaryJson = json.decode(responses[3].body)['summary'] ?? {};

      _data = DashboardData.fromJson(
        focusData: focusJson,
        goalData: goalJson,
        nudgeData: nudgeJson,
        summaryData: summaryJson,
      );
    } catch (e) {
      _error = "Unable to load dashboard. Please check your connection.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
