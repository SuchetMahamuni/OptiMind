class TaskModel {
  final int id;
  final int userId;
  final String subject;
  final String priority;
  final DateTime? deadline;
  final int estimatedTime;
  final bool isCompleted;
  final DateTime createdAt;

  final int totalSecondsSpent;
  late final double progressPercentage;

  TaskModel({
    required this.id,
    required this.userId,
    required this.subject,
    required this.priority,
    this.deadline,
    required this.estimatedTime,
    required this.isCompleted,
    required this.createdAt,
    this.totalSecondsSpent = 0,
    this.progressPercentage = 0.0,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      subject: json['subject'] as String,
      priority: (json['priority'] as String).toLowerCase(),
      deadline: json['deadline'] != null 
          ? DateTime.parse(json['deadline'] as String) 
          : null,
      estimatedTime: json['estimated_time'] as int,
      isCompleted: json['is_completed'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      totalSecondsSpent: json['total_seconds_spent'] as int? ?? 0,
      progressPercentage: (json['progress_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'priority': priority,
      'deadline': deadline?.toIso8601String(),
      'estimated_time': estimatedTime,
      'is_completed': isCompleted,
    };
  }

  TaskModel copyWith({
    String? subject,
    String? priority,
    DateTime? deadline,
    int? estimatedTime,
    bool? isCompleted,
    int? totalSecondsSpent,
    double? progressPercentage,
  }) {
    return TaskModel(
      id: id,
      userId: userId,
      subject: subject ?? this.subject,
      priority: priority ?? this.priority,
      deadline: deadline ?? this.deadline,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      totalSecondsSpent: totalSecondsSpent ?? this.totalSecondsSpent,
      progressPercentage: progressPercentage ?? this.progressPercentage,
    );
  }
}
