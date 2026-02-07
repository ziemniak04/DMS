/// Application Configuration
///
/// This file contains configuration constants for the application.
/// For production deployment, consider using environment variables or
/// a secure configuration management system.
class AppConfig {
  // AI Assistant API Configuration
  // NOTE: For production, move these to secure environment configuration
  static const String aiAssistantBaseUrl = 'https://mkuch.pl/fast-llm/chat';
  static const String aiAssistantHealthUrl = 'https://mkuch.pl/fast-llm/health';
  static const String aiAssistantApiKey = 'tajnyklucz123deepseek';

  // Feature Flags
  static const bool enableAiAssistant = true;
  static const bool enableDexcomIntegration = true;
  static const bool enableNotifications = true;

  // Mock Account Configuration (for demo purposes)
  static const String mockAccountEmail = 'mocked@test.pl';
  static const String mockAccountPassword = '123456';
  static const bool allowMockAccount = true;

  // App Settings
  static const String appName = 'DMS';
  static const String appVersion = '1.0.0';

  // Backend API Configuration
  static const String backendBaseUrl = 'http://localhost:8000';

  // Glucose Settings
  static const double glucoseTargetMin = 70.0;
  static const double glucoseTargetMax = 180.0;
  static const double glucoseCriticalLow = 54.0;
  static const double glucoseCriticalHigh = 250.0;

  // Private constructor to prevent instantiation
  AppConfig._();
}
