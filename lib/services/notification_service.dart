import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';

/// Notification Service
/// 
/// Handles local notifications for:
/// - Hourly blood sugar check reminders
/// - Glucose alerts (high/low)
/// - AI assistant insights
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  Timer? _hourlyReminderTimer;
  
  // Notification channel IDs
  static const String _glucoseCheckChannelId = 'glucose_check';
  static const String _glucoseAlertChannelId = 'glucose_alert';
  static const String _aiInsightChannelId = 'ai_insight';
  
  // Notification IDs
  static const int _hourlyReminderId = 1000;
  static const int _lowGlucoseAlertId = 2000;
  static const int _highGlucoseAlertId = 2001;
  static const int _aiInsightId = 3000;
  
  // Settings keys
  static const String _hourlyReminderEnabledKey = 'hourly_reminder_enabled';
  static const String _quietHoursStartKey = 'quiet_hours_start';
  static const String _quietHoursEndKey = 'quiet_hours_end';

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Initialize timezone data
    tz_data.initializeTimeZones();
    
    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    // Initialize plugin
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    
    // Create notification channels for Android
    await _createNotificationChannels();
    
    _isInitialized = true;
    
    // Check if hourly reminders should be started
    await _checkAndStartHourlyReminders();
  }
  
  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;
    
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin == null) return;
    
    // Glucose check reminder channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _glucoseCheckChannelId,
        'Blood Sugar Check Reminders',
        description: 'Hourly reminders to check your blood sugar levels',
        importance: Importance.defaultImportance,
      ),
    );
    
    // Glucose alert channel (high priority)
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _glucoseAlertChannelId,
        'Glucose Alerts',
        description: 'Alerts for high or low glucose levels',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
    
    // AI insight channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _aiInsightChannelId,
        'AI Health Insights',
        description: 'Personalized insights from the AI assistant',
        importance: Importance.low,
      ),
    );
  }
  
  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    // Handle navigation based on notification payload
    final payload = response.payload;
    if (payload != null) {
      // TODO: Navigate to appropriate screen based on payload
      debugPrint('Notification tapped with payload: $payload');
    }
  }
  
  /// Request notification permissions
  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    } else if (Platform.isAndroid) {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidPlugin?.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }
  
  // ==================== Hourly Reminders ====================
  
  /// Enable or disable hourly blood sugar check reminders
  Future<void> setHourlyRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hourlyReminderEnabledKey, enabled);
    
    if (enabled) {
      await _startHourlyReminders();
    } else {
      _stopHourlyReminders();
    }
  }
  
  /// Check if hourly reminders are enabled
  Future<bool> isHourlyRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hourlyReminderEnabledKey) ?? false;
  }
  
  /// Set quiet hours (no notifications during this time)
  Future<void> setQuietHours(TimeOfDay start, TimeOfDay end) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_quietHoursStartKey, start.hour * 60 + start.minute);
    await prefs.setInt(_quietHoursEndKey, end.hour * 60 + end.minute);
  }
  
  /// Get quiet hours
  Future<(TimeOfDay, TimeOfDay)> getQuietHours() async {
    final prefs = await SharedPreferences.getInstance();
    final startMinutes = prefs.getInt(_quietHoursStartKey) ?? 22 * 60; // Default 10 PM
    final endMinutes = prefs.getInt(_quietHoursEndKey) ?? 7 * 60; // Default 7 AM
    
    return (
      TimeOfDay(hour: startMinutes ~/ 60, minute: startMinutes % 60),
      TimeOfDay(hour: endMinutes ~/ 60, minute: endMinutes % 60),
    );
  }
  
  /// Check if current time is within quiet hours
  Future<bool> _isQuietHours() async {
    final (start, end) = await getQuietHours();
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    
    if (startMinutes <= endMinutes) {
      // Quiet hours don't span midnight
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    } else {
      // Quiet hours span midnight (e.g., 10 PM to 7 AM)
      return nowMinutes >= startMinutes || nowMinutes < endMinutes;
    }
  }
  
  /// Check and start hourly reminders if enabled
  Future<void> _checkAndStartHourlyReminders() async {
    if (await isHourlyRemindersEnabled()) {
      await _startHourlyReminders();
    }
  }
  
  /// Start hourly reminder timer
  Future<void> _startHourlyReminders() async {
    _stopHourlyReminders();
    
    // Calculate time until next hour
    final now = DateTime.now();
    final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1);
    final initialDelay = nextHour.difference(now);
    
    // Send first reminder after the initial delay, then every hour
    Future.delayed(initialDelay, () async {
      await _sendHourlyReminder();
      
      // Then repeat every hour
      _hourlyReminderTimer = Timer.periodic(
        const Duration(hours: 1),
        (_) => _sendHourlyReminder(),
      );
    });
  }
  
  /// Stop hourly reminders
  void _stopHourlyReminders() {
    _hourlyReminderTimer?.cancel();
    _hourlyReminderTimer = null;
  }
  
  /// Send an hourly reminder notification
  Future<void> _sendHourlyReminder() async {
    // Check if in quiet hours
    if (await _isQuietHours()) {
      return;
    }
    
    await _notifications.show(
      _hourlyReminderId,
      '⏰ Time to Check Your Blood Sugar',
      'It\'s been an hour since your last check. Tap to log your current reading.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _glucoseCheckChannelId,
          'Blood Sugar Check Reminders',
          channelDescription: 'Hourly reminders to check your blood sugar levels',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'glucose_check',
    );
  }
  
  /// Send a test reminder notification (for testing purposes)
  Future<void> sendTestReminder() async {
    await _notifications.show(
      _hourlyReminderId + 1,
      '⏰ Test Reminder',
      'This is a test notification. Your reminder settings are working correctly!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _glucoseCheckChannelId,
          'Blood Sugar Check Reminders',
          channelDescription: 'Hourly reminders to check your blood sugar levels',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'test_reminder',
    );
  }
  
  // ==================== Glucose Alerts ====================
  
  /// Send a low glucose alert
  Future<void> sendLowGlucoseAlert(double value) async {
    await _notifications.show(
      _lowGlucoseAlertId,
      '🔴 Low Blood Sugar Alert!',
      'Your glucose is ${value.toStringAsFixed(0)} mg/dL. Consider having a fast-acting carbohydrate.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _glucoseAlertChannelId,
          'Glucose Alerts',
          channelDescription: 'Alerts for high or low glucose levels',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Colors.red,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.critical,
        ),
      ),
      payload: 'low_glucose',
    );
  }
  
  /// Send a high glucose alert
  Future<void> sendHighGlucoseAlert(double value) async {
    await _notifications.show(
      _highGlucoseAlertId,
      '🟠 High Blood Sugar Alert',
      'Your glucose is ${value.toStringAsFixed(0)} mg/dL. Consider checking if you need to take action.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _glucoseAlertChannelId,
          'Glucose Alerts',
          channelDescription: 'Alerts for high or low glucose levels',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Colors.orange,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'high_glucose',
    );
  }
  
  // ==================== AI Insights ====================
  
  /// Send an AI insight notification
  Future<void> sendAiInsight(String title, String message) async {
    await _notifications.show(
      _aiInsightId + DateTime.now().millisecondsSinceEpoch % 1000,
      '🤖 $title',
      message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _aiInsightChannelId,
          'AI Health Insights',
          channelDescription: 'Personalized insights from the AI assistant',
          importance: Importance.low,
          priority: Priority.low,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: false,
        ),
      ),
      payload: 'ai_insight',
    );
  }
  
  // ==================== Utility ====================
  
  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
  
  /// Cancel a specific notification
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }
  
  /// Dispose the service
  void dispose() {
    _stopHourlyReminders();
  }
}
