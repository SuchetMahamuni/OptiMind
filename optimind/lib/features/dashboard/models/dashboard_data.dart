class DashboardData {
  final double focusScore;
  final double consistencyScore;
  final Map<String, dynamic> focusBreakdown;
  final int goalMinutes;
  final String goalRationale;
  final String nudgeMessage;
  final String nudgeType;
  final int totalStudyTimeToday;
  final int currentStreak;
  final int pendingTasks;
  final int completedTasks;

  DashboardData({
    required this.focusScore,
    required this.consistencyScore,
    required this.focusBreakdown,
    required this.goalMinutes,
    required this.goalRationale,
    required this.nudgeMessage,
    required this.nudgeType,
    required this.totalStudyTimeToday,
    required this.currentStreak,
    required this.pendingTasks,
    required this.completedTasks,
  });

  String get focusLabel {
    if (focusScore >= 80) return 'Great';
    if (focusScore >= 60) return 'Good';
    if (focusScore >= 40) return 'Fair';
    return 'Needs Improvement';
  }

  factory DashboardData.fromJson({
    required Map<String, dynamic> focusData,
    required Map<String, dynamic> goalData,
    required Map<String, dynamic> nudgeData,
    required Map<String, dynamic> summaryData,
  }) {
    return DashboardData(
      focusScore: (focusData['focus_score'] ?? 0).toDouble(),
      consistencyScore: (focusData['consistency_score'] ?? 0).toDouble(),
      focusBreakdown: focusData['breakdown'] ?? {},
      goalMinutes: goalData['goal_minutes'] ?? 0,
      goalRationale: goalData['rationale'] ?? '',
      nudgeMessage: nudgeData['nudge'] ?? '',
      nudgeType: nudgeData['type'] ?? 'info',
      totalStudyTimeToday: summaryData['total_study_time_today'] ?? 0,
      currentStreak: summaryData['current_streak'] ?? 0,
      pendingTasks: summaryData['pending_tasks'] ?? 0,
      completedTasks: summaryData['completed_tasks'] ?? 0,
    );
  }
}
