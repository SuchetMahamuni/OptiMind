class SessionModel {
  final int id;
  final int userId;
  final int? taskId;
  final DateTime startTime;
  final DateTime endTime;
  final int interruptions;
  final int duration;
  final bool isActive;

  SessionModel({
    required this.id,
    required this.userId,
    this.taskId,
    required this.startTime,
    required this.endTime,
    required this.interruptions,
    required this.duration,
    required this.isActive,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      taskId: json['task_id'] as int?,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      duration: json['duration'] as int,
      interruptions: json['interruptions'] as int,
      isActive: json['is_active'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'task_id': taskId,
      'duration': duration,
      'is_active': isActive,
    };
  }
}
