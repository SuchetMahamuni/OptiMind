class AppConstants {
  // API URLs
  // static const String baseUrl = 'https://suchet.pythonanywhere.com/api'; // WSGI
  static const String baseUrl = 'http://192.168.1.6:5000/api'; // Dev
  
  // Storage Keys
  static const String tokenKey = 'jwt_token';
  static const String userKey = 'user_data';
  static const String onboardingKey = 'onboarding_done';
  static const String themeKey = 'theme_preference';
  static const String customGoalKey = 'custom_study_goal';
  static const String useAdaptiveGoalKey = 'use_adaptive_goal';
  
  // Hive Boxes
  static const String userBox = 'userBox';
  static const String tasksBox = 'tasksBox';
  static const String sessionsBox = 'sessionsBox';
  static const String settingsBox = 'settingsBox';
  
  // Session Settings (Default)
  static const int pomodoroDuration = 25; // Minutes
  static const int shortBreakDuration = 5; // Minutes
  static const int longBreakDuration = 15; // Minutes
  static const int sessionsBeforeLongBreak = 4;
  
  // Scoring
  static const int maxFocusScore = 100;
  static const int minFocusScore = 0;
  
  // Nudge Intervals
  static const int lazinessNudgeThreshold = 120; // 2 hours of inactivity
  static const int burnoutNudgeThreshold = 180; // 3 hours of continuous study
}
