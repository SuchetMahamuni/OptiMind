import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

/// Which time range the user has selected.
enum InsightsFilter { daily, weekly, monthly }

/// A single daily-stats data point used by charts.
class DailyStatPoint {
  final DateTime date;
  final double studyMinutes; // converted from seconds
  final double focusScore;

  const DailyStatPoint({
    required this.date,
    required this.studyMinutes,
    required this.focusScore,
  });
}

/// A single session's interruption data.
class SessionInterruptionPoint {
  final DateTime date;
  final int interruptions;

  const SessionInterruptionPoint({
    required this.date,
    required this.interruptions,
  });
}

class InsightsProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // ── State ──────────────────────────────────────────────────────────────────
  InsightsFilter _selectedFilter = InsightsFilter.weekly;
  bool _isLoading = false;
  String? _errorMessage;

  // ── Raw data ───────────────────────────────────────────────────────────────
  List<DailyStatPoint> _statPoints = [];
  List<SessionInterruptionPoint> _interruptionPoints = [];
  Map<String, double> _subjectDistribution = {};
  int _currentStreak = 0;
  int _bestStreak = 0; // derived from history
  int _weeklyStudyTimeSeconds = 0;

  // ── Getters ────────────────────────────────────────────────────────────────
  InsightsFilter get selectedFilter => _selectedFilter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<DailyStatPoint> get statPoints => _statPoints;
  List<SessionInterruptionPoint> get interruptionPoints => _interruptionPoints;
  Map<String, double> get subjectDistribution => _subjectDistribution;
  int get currentStreak => _currentStreak;
  int get bestStreak => _bestStreak;

  bool get hasData => _statPoints.isNotEmpty;

  /// Total study time in the selected range (in hours + minutes, formatted).
  String get totalStudyTimeFormatted {
    final totalMins = _statPoints.fold<double>(0, (s, p) => s + p.studyMinutes);
    final h = totalMins ~/ 60;
    final m = (totalMins % 60).round();
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  double get avgFocusScore {
    if (_statPoints.isEmpty) return 0;
    final points = _statPoints.where((p) => p.focusScore > 0).toList();
    if (points.isEmpty) return 0;
    return points.fold<double>(0, (s, p) => s + p.focusScore) / points.length;
  }

  int get totalInterruptions =>
      _interruptionPoints.fold(0, (s, p) => s + p.interruptions);

  double get avgInterruptionsPerSession {
    if (_interruptionPoints.isEmpty) return 0;
    return totalInterruptions / _interruptionPoints.length;
  }

  String get weeklyStudyTimeFormatted {
    final h = _weeklyStudyTimeSeconds ~/ 3600;
    final m = (_weeklyStudyTimeSeconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  /// Change the active filter and reload data.
  Future<void> setFilter(InsightsFilter filter) async {
    if (_selectedFilter == filter) return;
    _selectedFilter = filter;
    notifyListeners();
    await fetchAll();
  }

  /// Fetch all insights data in parallel.
  Future<void> fetchAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        _fetchStatsHistory(),
        _fetchSummary(),
        _fetchSessionHistory(),
      ]);
    } catch (e) {
      _errorMessage = 'Unable to load insights. Check your connection.';
      debugPrint('InsightsProvider.fetchAll error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Private fetchers ───────────────────────────────────────────────────────

  Future<void> _fetchStatsHistory() async {
    final days = _daysForFilter();
    final response =
        await _apiService.get('dashboard/stats/history?days=$days');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final history = data['history'] as List? ?? [];

      _statPoints = history.map((item) {
        return DailyStatPoint(
          date: DateTime.parse(item['date'] as String),
          studyMinutes: ((item['total_study_time'] as num?) ?? 0) / 60.0,
          focusScore: ((item['focus_score'] as num?) ?? 0).toDouble(),
        );
      }).toList();

      // Derive best streak from history (consecutive days with study time > 0)
      _bestStreak = _computeBestStreakFromHistory(_statPoints);
    }
  }

  Future<void> _fetchSummary() async {
    final response = await _apiService.get('dashboard/summary');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final summary = data['summary'] as Map<String, dynamic>? ?? {};

      _currentStreak = (summary['current_streak'] as num?)?.toInt() ?? 0;
      _weeklyStudyTimeSeconds =
          (summary['weekly_study_time'] as num?)?.toInt() ?? 0;

      // Subject distribution: convert seconds → minutes
      final dist =
          summary['subject_distribution'] as Map<String, dynamic>? ?? {};
      _subjectDistribution = dist.map(
        (k, v) => MapEntry(k, ((v as num?) ?? 0) / 60.0),
      );
    }
  }

  Future<void> _fetchSessionHistory() async {
    // Fetch enough sessions to cover the selected range
    final perPage = _daysForFilter() * 5; // rough estimate
    final response = await _apiService
        .get('sessions/get_history?per_page=$perPage');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final sessions = data['sessions'] as List? ?? [];

      final cutoff = DateTime.now().subtract(Duration(days: _daysForFilter()));

      _interruptionPoints = sessions
          .where((s) {
            final startStr = s['start_time'] as String?;
            if (startStr == null) return false;
            final start = DateTime.tryParse(startStr);
            return start != null && start.isAfter(cutoff);
          })
          .map((s) => SessionInterruptionPoint(
                date: DateTime.parse(s['start_time'] as String),
                interruptions:
                    ((s['interruptions'] as num?) ?? 0).toInt(),
              ))
          .toList();
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  int _daysForFilter() {
    switch (_selectedFilter) {
      case InsightsFilter.daily:
        return 1;
      case InsightsFilter.weekly:
        return 7;
      case InsightsFilter.monthly:
        return 30;
    }
  }

  int _computeBestStreakFromHistory(List<DailyStatPoint> points) {
    if (points.isEmpty) return 0;
    // Sort ascending by date
    final sorted = List<DailyStatPoint>.from(points)
      ..sort((a, b) => a.date.compareTo(b.date));

    int best = 0, current = 0;
    DateTime? prevDate;

    for (final p in sorted) {
      if (p.studyMinutes <= 0) {
        current = 0;
        prevDate = null;
        continue;
      }
      if (prevDate == null) {
        current = 1;
      } else {
        final diff = p.date.difference(prevDate).inDays;
        if (diff == 1) {
          current++;
        } else {
          current = 1;
        }
      }
      prevDate = p.date;
      if (current > best) best = current;
    }
    return best;
  }
}
