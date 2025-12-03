/// Application-wide constants
class AppConstants {
  // App info
  static const String appName = 'DMS';
  static const String appFullName = 'Diabetes Management System';
  static const String appVersion = '1.0.0';
  
  // Glucose ranges (mg/dL)
  static const double glucoseLowThreshold = 70.0;
  static const double glucoseHighThreshold = 180.0;
  static const double glucoseVeryHighThreshold = 250.0;
  static const double glucoseTargetMin = 70.0;
  static const double glucoseTargetMax = 180.0;
  
  // Time ranges for chart display
  static const List<int> chartTimeRanges = [3, 6, 12, 24]; // hours
  
  // User roles
  static const String rolePatient = 'patient';
  static const String roleDoctor = 'doctor';
  
  // SharedPreferences keys
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyUserRole = 'user_role';
  static const String keyUserId = 'user_id';
  static const String keyUserName = 'user_name';
  static const String keyDarkMode = 'dark_mode';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyGlucoseUnit = 'glucose_unit';
}
