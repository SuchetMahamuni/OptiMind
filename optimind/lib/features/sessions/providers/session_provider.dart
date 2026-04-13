import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../sessions/models/session_model.dart';


enum SessionState { idle, active, paused, summary }

class SessionProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  int? _currentTaskId;
  int? _currentSessionId;
  int? _targetDuration; // in minutes

  List<SessionModel> _sessions = [];
  SessionState _state = SessionState.idle;
  int _elapsedSeconds = 0;
  int _startFrom = 0;
  int _interruptionCount = 0;
  bool _isLoading = false;
  DateTime? _startTime;
  Timer? _timer;
  String? _error;

  // Getters
  List<SessionModel> get sessions => _sessions;
  SessionState get state => _state;
  bool get isLoading => _isLoading;
  int get elapsedSeconds => _elapsedSeconds;
  int get interruptionCount => _interruptionCount;
  bool get isActive => _state == SessionState.active || _state == SessionState.paused;
  bool get isPaused => _state == SessionState.paused;
  int? get currentTaskId => _currentTaskId;
  int? get currentSessionId => _currentSessionId;
  int? get targetDuration => _targetDuration;
  String? get error => _error;

  List<SessionModel> get sortedSessions {
    final sorted = List<SessionModel>.from(_sessions);
    sorted.sort((a, b) {
      // Start time (Most cases handled here itself)
      if (a.startTime != b.startTime) {
        return (a.startTime.isAfter(b.startTime)) ? -1 : 1;
      }

      // If ever in life it doesn't end there
      if (a.duration != b.duration){
        return (a.duration > b.duration) ? -1 : 1;
      }
      // No sane session shall come till here, yet EDGE CASE
      return (a.interruptions < b.interruptions) ? 1 : -1;
    });
    return sorted;
  }
  
  double get sessionProgress {
    if (_targetDuration == null || _targetDuration! <= 0) return 0.0;
    final totalTargetSeconds = _targetDuration!; //targetDuration is in seconds
    return (_elapsedSeconds / totalTargetSeconds).clamp(0.0, 1.0);
  }

  Future<void> fetchSessions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('sessions/get_history');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _sessions = (data['sessions'] as List)
            .map((t) => SessionModel.fromJson(t))
            .toList();
      } else {
        _error = "Error fetching tasks";
      }
    } catch (e) {
      _error = "Unable to connect to server";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Start Session
  void startSession({int? taskId, int? targetDuration, int? startFrom}) {
    _state = SessionState.active;
    _startTime = DateTime.now();
    _startFrom = startFrom ?? 0;
    _elapsedSeconds = startFrom ?? 0;
    _interruptionCount = 0;
    _currentTaskId = taskId;
    _targetDuration = targetDuration;
    _startTimer();
    notifyListeners();
  }

  // Pause Session
  void pauseSession() {
    if (_state == SessionState.active) {
      _state = SessionState.paused;
      _timer?.cancel();
      notifyListeners();
    }
  }

  // Resume Session
  void resumeSession() {
    if (_state == SessionState.paused) {
      _state = SessionState.active;
      _startTimer();
      notifyListeners();
    }
  }

  // Add Interruption
  void addInterruption() {
    if (isActive) {
      _interruptionCount++;
      notifyListeners();
    }
  }

  // End Session
  Future<bool> endSession(bool shouldSync) async {
    if (!isActive) return false;

    _timer?.cancel();
    final endTime = DateTime.now();
    final durationSeconds = _elapsedSeconds - _startFrom;

    // Prepare payload
    final payload = {
      'duration': durationSeconds,
      'interruptions': _interruptionCount,
      'start_time': _startTime?.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'task_id': _currentTaskId,
    };

    _state = SessionState.summary;
    notifyListeners();

    if (!shouldSync) return false;

    try {
      final response = await _apiService.post('sessions/add_session', payload);
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint('Error syncing session: $e');
      return false;
    }
  }

  // Reset to Idle
  void reset() {
    _state = SessionState.idle;
    _elapsedSeconds = 0;
    _interruptionCount = 0;
    _startTime = null;
    _currentTaskId = null;
    _targetDuration = null;
    _timer?.cancel();
    notifyListeners();
  }

  // Timer Logic
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_state == SessionState.active) {
        _elapsedSeconds++;
        notifyListeners();
      }
    });
  }

  String formatTime(int seconds) {
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    int s = seconds % 60;

    if (h > 0) {
      return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
    }
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
