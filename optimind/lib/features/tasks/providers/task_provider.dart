import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../models/task_model.dart';

class TaskProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<TaskModel> _tasks = [];
  bool _isLoading = false;
  String? _error;

  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Sorted tasks: Incomplete first, then by priority (desc), then deadline (asc)
  List<TaskModel> get sortedTasks {
    final sorted = List<TaskModel>.from(_tasks);
    sorted.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      
      // Priority weights
      final priorityWeight = {'high': 3, 'medium': 2, 'low': 1};
      int pA = priorityWeight[a.priority] ?? 0;
      int pB = priorityWeight[b.priority] ?? 0;
      
      if (pA != pB) return pB.compareTo(pA);
      
      if (a.deadline != null && b.deadline != null) {
        return a.deadline!.compareTo(b.deadline!);
      }
      return a.deadline != null ? -1 : 1;
    });
    return sorted;
  }

  Future<void> fetchTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('tasks/');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _tasks = (data['tasks'] as List)
            .map((t) => TaskModel.fromJson(t))
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

  Future<bool> addTask(String subject, String priority, DateTime? deadline, int estimatedTime) async {
    try {
      final response = await _apiService.post('tasks/', {
        'subject': subject,
        'priority': priority,
        'deadline': deadline?.toIso8601String(),
        'estimated_time': estimatedTime,
      });

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        _tasks.add(TaskModel.fromJson(data['task']));
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Error adding task: $e");
    }
    return false;
  }

  Future<void> toggleComplete(int taskId) async {
    try {
      final response = await _apiService.patch('tasks/$taskId/complete', {});
      if (response.statusCode == 200) {
        final index = _tasks.indexWhere((t) => t.id == taskId);
        if (index != -1) {
          _tasks[index] = _tasks[index].copyWith(isCompleted: true);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Error toggling completion: $e");
    }
  }

  Future<bool> deleteTask(int taskId) async {
    try {
      final response = await _apiService.delete('tasks/$taskId');
      if (response.statusCode == 200) {
        _tasks.removeWhere((t) => t.id == taskId);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Error deleting task: $e");
    }
    return false;
  }
}
