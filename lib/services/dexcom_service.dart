import 'package:flutter/foundation.dart';
import 'package:dexcom/dexcom.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dms_app/models/glucose_reading.dart';

/// Dexcom Service for CGM Integration
///
/// This service provides integration with Dexcom continuous glucose monitors
/// using the Dexcom Share API for real-time glucose data access.
///
/// IMPORTANT MEDICAL DISCLAIMER:
/// DO NOT USE THIS FOR CRITICAL MEDICAL TREATMENT DECISIONS.
/// This uses an unofficial API and should be used for informational purposes only.
class DexcomService {
  Dexcom? _dexcom;
  String? _username;
  String? _password;
  String? _region;
  bool _isAuthenticated = false;

  static const String _prefKeyUsername = 'dexcom_username';
  static const String _prefKeyPassword = 'dexcom_password';
  static const String _prefKeyRegion = 'dexcom_region';

  bool get isAuthenticated => _isAuthenticated;

  /// Initialize the Dexcom service with stored credentials
  Future<bool> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _username = prefs.getString(_prefKeyUsername);
      _password = prefs.getString(_prefKeyPassword);
      _region = prefs.getString(_prefKeyRegion) ?? 'us';

      if (_username != null && _password != null) {
        return await authenticate(_username!, _password!, region: _region!);
      }
      return false;
    } catch (e) {
      debugPrint('Failed to initialize Dexcom service: $e');
      return false;
    }
  }

  /// Authenticate with Dexcom Share
  ///
  /// [username] - Dexcom Share username (email)
  /// [password] - Dexcom Share password
  /// [region] - Region code: 'us' (default), 'ous' (outside US), or 'jp' (Japan)
  /// [saveCredentials] - Whether to save credentials for future sessions
  Future<bool> authenticate(
    String username,
    String password, {
    String region = 'us',
    bool saveCredentials = true,
  }) async {
    try {
      _username = username;
      _password = password;
      _region = region;

      // Create Dexcom instance with named parameters
      _dexcom = Dexcom(
        username: username,
        password: password,
        region: _stringToRegion(region),
      );

      // Test authentication by fetching glucose readings
      final readings = await _dexcom!.getGlucoseReadings(minutes: 5, maxCount: 1);

      if (readings != null) {
        _isAuthenticated = true;

        // Save credentials if requested
        if (saveCredentials) {
          await _saveCredentials(username, password, region);
        }

        return true;
      }

      _isAuthenticated = false;
      return false;
    } catch (e) {
      debugPrint('Dexcom authentication failed: $e');
      _isAuthenticated = false;
      return false;
    }
  }

  /// Get current glucose reading
  Future<GlucoseReading?> getCurrentReading(String patientId) async {
    if (!_isAuthenticated || _dexcom == null) {
      throw Exception('Not authenticated with Dexcom');
    }

    try {
      final readings = await _dexcom!.getGlucoseReadings(minutes: 10, maxCount: 1);

      if (readings == null || readings.isEmpty) {
        return null;
      }

      final dexcomReading = readings.first;
      return _convertToGlucoseReading(dexcomReading, patientId);
    } catch (e) {
      debugPrint('Failed to get current reading: $e');
      // Try to re-authenticate once
      if (_username != null && _password != null && _region != null) {
        await authenticate(_username!, _password!, region: _region!, saveCredentials: false);
        // Retry
        final readings = await _dexcom!.getGlucoseReadings(minutes: 10, maxCount: 1);
        if (readings != null && readings.isNotEmpty) {
          return _convertToGlucoseReading(readings.first, patientId);
        }
      }
      rethrow;
    }
  }

  /// Get glucose readings for a time range
  ///
  /// [patientId] - The patient ID to associate with readings
  /// [minutes] - Number of minutes to look back (default: 1440 = 24 hours)
  /// [maxCount] - Maximum number of readings to retrieve
  Future<List<GlucoseReading>> getReadings(
    String patientId, {
    int minutes = 1440,
    int? maxCount,
  }) async {
    if (!_isAuthenticated || _dexcom == null) {
      throw Exception('Not authenticated with Dexcom');
    }

    try {
      final readings = await _dexcom!.getGlucoseReadings(
        minutes: minutes,
        maxCount: maxCount,
      );

      if (readings == null) {
        return [];
      }

      return readings
          .map((r) => _convertToGlucoseReading(r, patientId))
          .toList();
    } catch (e) {
      debugPrint('Failed to get readings: $e');
      rethrow;
    }
  }

  /// Get all available glucose history (up to 24 hours - Dexcom Share API limit)
  /// 
  /// This fetches the maximum amount of historical data available from Dexcom Share.
  /// Note: Dexcom Share API only provides up to 24 hours of data.
  /// For older historical data, the official Dexcom Web API would be needed.
  /// 
  /// [patientId] - The patient ID to associate with readings
  /// [maxCount] - Maximum number of readings (default: 288 = 24 hours at 5-min intervals)
  Future<List<GlucoseReading>> getFullHistory(
    String patientId, {
    int? maxCount,
  }) async {
    if (!_isAuthenticated || _dexcom == null) {
      throw Exception('Not authenticated with Dexcom');
    }

    try {
      // Request maximum 24 hours (1440 minutes) with up to 288 readings
      // (one reading every 5 minutes for 24 hours = 288 readings)
      final readings = await _dexcom!.getGlucoseReadings(
        minutes: 1440, // 24 hours - maximum supported by Dexcom Share API
        maxCount: maxCount ?? 288,
      );

      if (readings == null || readings.isEmpty) {
        return [];
      }

      return readings
          .map((r) => _convertToGlucoseReading(r, patientId))
          .toList();
    } catch (e) {
      debugPrint('Failed to get full history: $e');
      rethrow;
    }
  }

  /// Get last known readings even if sensor is currently inactive
  /// 
  /// This attempts to fetch the most recent readings available.
  /// Useful for users whose sensor session has ended but want to see
  /// their last recorded data.
  /// 
  /// [patientId] - The patient ID to associate with readings
  /// [hours] - Number of hours to look back (default: 24, max: 24)
  Future<DexcomHistoryResult> getHistoryWithStatus(
    String patientId, {
    int hours = 24,
  }) async {
    if (!_isAuthenticated || _dexcom == null) {
      throw Exception('Not authenticated with Dexcom');
    }

    // Clamp to maximum 24 hours (Dexcom Share API limit)
    final effectiveHours = hours.clamp(1, 24);
    final minutes = effectiveHours * 60;
    final expectedReadings = effectiveHours * 12; // 12 readings per hour (every 5 min)

    try {
      final readings = await _dexcom!.getGlucoseReadings(
        minutes: minutes,
        maxCount: expectedReadings,
      );

      if (readings == null || readings.isEmpty) {
        return DexcomHistoryResult(
          readings: [],
          sensorActive: false,
          lastReadingTime: null,
          message: 'No glucose data available. Your sensor may be inactive or not sharing data.',
        );
      }

      final glucoseReadings = readings
          .map((r) => _convertToGlucoseReading(r, patientId))
          .toList();

      // Sort by timestamp descending (most recent first)
      glucoseReadings.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      final lastReading = glucoseReadings.first;
      final timeSinceLastReading = DateTime.now().difference(lastReading.timestamp);
      
      // If last reading is more than 15 minutes old, sensor is likely inactive
      final sensorActive = timeSinceLastReading.inMinutes <= 15;

      String message;
      if (sensorActive) {
        message = 'Sensor is active. ${glucoseReadings.length} readings retrieved.';
      } else if (timeSinceLastReading.inHours < 1) {
        message = 'Last reading ${timeSinceLastReading.inMinutes} minutes ago. Sensor may be warming up or disconnected.';
      } else if (timeSinceLastReading.inHours < 24) {
        message = 'Last reading ${timeSinceLastReading.inHours} hours ago. Showing historical data.';
      } else {
        message = 'Last reading over 24 hours ago. Sensor session may have ended.';
      }

      return DexcomHistoryResult(
        readings: glucoseReadings,
        sensorActive: sensorActive,
        lastReadingTime: lastReading.timestamp,
        message: message,
      );
    } catch (e) {
      debugPrint('Failed to get history with status: $e');
      return DexcomHistoryResult(
        readings: [],
        sensorActive: false,
        lastReadingTime: null,
        message: 'Error fetching data: ${e.toString()}',
      );
    }
  }

  /// Stream glucose readings at regular intervals
  ///
  /// [patientId] - The patient ID to associate with readings
  /// [seconds] - Interval between readings in seconds (default: 300 = 5 minutes)
  Stream<GlucoseReading> streamReadings(String patientId, {int seconds = 300}) async* {
    if (!_isAuthenticated || _dexcom == null) {
      throw Exception('Not authenticated with Dexcom');
    }

    // Create a stream provider for continuous glucose monitoring
    final provider = DexcomStreamProvider(_dexcom!, maxCount: 1);

    // Listen to the stream
    await for (final readings in provider.stream!) {
      if (readings.isNotEmpty) {
        final dexcomReading = readings.first as DexcomReading;
        yield _convertDexcomReadingToGlucoseReading(dexcomReading, patientId);
      }
    }
  }

  /// Convert Dexcom reading to app's GlucoseReading model
  GlucoseReading _convertToGlucoseReading(dynamic dexcomReading, String patientId) {
    // Extract glucose value (in mg/dL)
    final double value = (dexcomReading['Value'] ?? 0).toDouble();

    // Extract timestamp (milliseconds since epoch)
    final int timestampMs = dexcomReading['WT'] ?? DateTime.now().millisecondsSinceEpoch;
    final DateTime timestamp = DateTime.fromMillisecondsSinceEpoch(timestampMs);

    // Extract trend
    final String trendRaw = dexcomReading['Trend'] ?? 'Flat';
    final String? trend = _convertTrend(trendRaw);

    return GlucoseReading(
      id: 'dexcom_$timestampMs',
      patientId: patientId,
      value: value,
      timestamp: timestamp,
      trend: trend,
      source: 'sensor',
    );
  }

  /// Convert DexcomReading object to app's GlucoseReading model
  GlucoseReading _convertDexcomReadingToGlucoseReading(DexcomReading dexcomReading, String patientId) {
    final int timestampMs = dexcomReading.displayTime.millisecondsSinceEpoch;
    final String? trend = _convertDexcomTrendToString(dexcomReading.trend);

    return GlucoseReading(
      id: 'dexcom_$timestampMs',
      patientId: patientId,
      value: dexcomReading.value.toDouble(),
      timestamp: dexcomReading.displayTime,
      trend: trend,
      source: 'sensor',
    );
  }

  /// Convert DexcomTrend enum to app's trend format
  String? _convertDexcomTrendToString(DexcomTrend trend) {
    switch (trend) {
      case DexcomTrend.doubleUp:
        return 'rising_fast';
      case DexcomTrend.singleUp:
      case DexcomTrend.fortyFiveUp:
        return 'rising';
      case DexcomTrend.flat:
        return 'stable';
      case DexcomTrend.fortyFiveDown:
      case DexcomTrend.singleDown:
        return 'falling';
      case DexcomTrend.doubleDown:
        return 'falling_fast';
      default:
        return 'stable';
    }
  }

  /// Convert Dexcom trend to app's trend format
  String? _convertTrend(String dexcomTrend) {
    switch (dexcomTrend) {
      case 'DoubleUp':
        return 'rising_fast';
      case 'SingleUp':
      case 'FortyFiveUp':
        return 'rising';
      case 'Flat':
        return 'stable';
      case 'FortyFiveDown':
      case 'SingleDown':
        return 'falling';
      case 'DoubleDown':
        return 'falling_fast';
      default:
        return 'stable';
    }
  }

  /// Save credentials to secure storage
  Future<void> _saveCredentials(String username, String password, String region) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyUsername, username);
      await prefs.setString(_prefKeyPassword, password);
      await prefs.setString(_prefKeyRegion, region);
    } catch (e) {
      debugPrint('Failed to save Dexcom credentials: $e');
    }
  }

  /// Clear saved credentials
  Future<void> clearCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKeyUsername);
      await prefs.remove(_prefKeyPassword);
      await prefs.remove(_prefKeyRegion);

      _username = null;
      _password = null;
      _region = null;
      _dexcom = null;
      _isAuthenticated = false;
    } catch (e) {
      debugPrint('Failed to clear Dexcom credentials: $e');
    }
  }

  /// Sign out from Dexcom
  Future<void> signOut() async {
    await clearCredentials();
  }

  /// Convert string region to DexcomRegion enum
  DexcomRegion _stringToRegion(String region) {
    switch (region.toLowerCase()) {
      case 'us':
        return DexcomRegion.us;
      case 'ous':
        return DexcomRegion.ous;
      case 'jp':
        return DexcomRegion.jp;
      default:
        return DexcomRegion.us;
    }
  }

  /// Check if credentials are saved
  Future<bool> hasStoredCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_prefKeyUsername) &&
             prefs.containsKey(_prefKeyPassword);
    } catch (e) {
      return false;
    }
  }
}

/// Result class for history fetching with sensor status
class DexcomHistoryResult {
  final List<GlucoseReading> readings;
  final bool sensorActive;
  final DateTime? lastReadingTime;
  final String message;

  DexcomHistoryResult({
    required this.readings,
    required this.sensorActive,
    this.lastReadingTime,
    required this.message,
  });

  /// Check if there is any data available
  bool get hasData => readings.isNotEmpty;

  /// Get time since last reading
  Duration? get timeSinceLastReading {
    if (lastReadingTime == null) return null;
    return DateTime.now().difference(lastReadingTime!);
  }

  /// Get a human-readable status
  String get statusText {
    if (!hasData) return 'No data available';
    if (sensorActive) return 'Sensor active';
    final duration = timeSinceLastReading;
    if (duration == null) return 'Unknown status';
    if (duration.inMinutes < 60) return 'Last reading ${duration.inMinutes}m ago';
    if (duration.inHours < 24) return 'Last reading ${duration.inHours}h ago';
    return 'Sensor inactive';
  }
}
