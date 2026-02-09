import 'package:flutter/foundation.dart';
import 'package:dexcom/dexcom.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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

  /// Cached session ID for direct API calls (bypasses broken package parsing)
  String? _sessionId;

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

      // Authenticate by obtaining account ID + session ID via direct API calls.
      // We do this ourselves because the dexcom package's getGlucoseReadings()
      // has a bug parsing timestamps with positive timezone offsets (e.g. +0100).
      _sessionId = await _createSession(username, password, region);

      if (_sessionId != null) {
        // Verify the session works by fetching 1 reading via raw API
        final testReadings = await _fetchReadingsRaw(minutes: 10, maxCount: 1);

        if (testReadings != null) {
          _isAuthenticated = true;

          // Save credentials if requested
          if (saveCredentials) {
            await _saveCredentials(username, password, region);
          }

          return true;
        }
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
    if (!_isAuthenticated || _sessionId == null) {
      throw Exception('Not authenticated with Dexcom');
    }

    try {
      final readings = await _fetchReadingsRaw(minutes: 10, maxCount: 1);

      if (readings == null || readings.isEmpty) {
        return null;
      }

      return _convertToGlucoseReading(readings.first, patientId);
    } catch (e) {
      debugPrint('Failed to get current reading: $e');
      // Try to re-authenticate once
      if (_username != null && _password != null && _region != null) {
        _sessionId = await _createSession(_username!, _password!, _region!);
        // Retry
        final readings = await _fetchReadingsRaw(minutes: 10, maxCount: 1);
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
    if (!_isAuthenticated || _sessionId == null) {
      throw Exception('Not authenticated with Dexcom');
    }

    try {
      final readings = await _fetchReadingsRaw(
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
    if (!_isAuthenticated || _sessionId == null) {
      throw Exception('Not authenticated with Dexcom');
    }

    try {
      // Request maximum 24 hours (1440 minutes) with up to 288 readings
      // (one reading every 5 minutes for 24 hours = 288 readings)
      final readings = await _fetchReadingsRaw(
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
    if (!_isAuthenticated || _sessionId == null) {
      throw Exception('Not authenticated with Dexcom');
    }

    // Clamp to maximum 24 hours (Dexcom Share API limit)
    final effectiveHours = hours.clamp(1, 24);
    final minutes = effectiveHours * 60;
    final expectedReadings = effectiveHours * 12; // 12 readings per hour (every 5 min)

    try {
      final readings = await _fetchReadingsRaw(
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
    if (!_isAuthenticated || _sessionId == null) {
      throw Exception('Not authenticated with Dexcom');
    }

    // Poll at the given interval using raw API (bypasses broken package parsing)
    while (true) {
      try {
        final readings = await _fetchReadingsRaw(minutes: 10, maxCount: 1);
        if (readings != null && readings.isNotEmpty) {
          yield _convertToGlucoseReading(readings.first, patientId);
        }
      } catch (e) {
        debugPrint('[DexcomService] Stream poll error: $e');
      }
      await Future.delayed(Duration(seconds: seconds));
    }
  }

  // ==================== Raw Dexcom Share API methods ====================
  // These bypass the dexcom package's broken timestamp parsing for regions
  // with positive UTC offsets (e.g. +0100 in Europe).

  /// Get the base URL for the Dexcom Share API based on region
  String _getBaseUrl(String region) {
    switch (region.toLowerCase()) {
      case 'us':
        return 'https://share2.dexcom.com/ShareWebServices/Services';
      case 'ous':
        return 'https://shareous1.dexcom.com/ShareWebServices/Services';
      case 'jp':
        return 'https://share.dexcom.jp/ShareWebServices/Services';
      default:
        return 'https://share2.dexcom.com/ShareWebServices/Services';
    }
  }

  /// Get the application ID for the given region
  String _getAppId(String region) {
    switch (region.toLowerCase()) {
      case 'jp':
        return 'd8665ade-9673-4e27-9ff6-92db4ce13d13';
      default:
        return 'd89443d2-327c-4a6f-89e5-496bbb0317db';
    }
  }

  /// Create a Dexcom Share session and return the session ID.
  /// This replicates the package's auth flow but stores the session ID
  /// so we can make raw API calls with proper timestamp parsing.
  Future<String?> _createSession(String username, String password, String region) async {
    try {
      final baseUrl = _getBaseUrl(region);
      final appId = _getAppId(region);

      // Step 1: Get account ID
      final accountResponse = await http.post(
        Uri.parse('$baseUrl/General/AuthenticatePublisherAccount'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'accountName': username,
          'password': password,
          'applicationId': appId,
        }),
      );

      if (accountResponse.statusCode != 200) {
        debugPrint('[DexcomService] Failed to get account ID: ${accountResponse.statusCode}');
        return null;
      }

      final accountId = accountResponse.body.replaceAll('"', '');

      // Step 2: Get session ID
      final sessionResponse = await http.post(
        Uri.parse('$baseUrl/General/LoginPublisherAccountById'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'accountId': accountId,
          'password': password,
          'applicationId': appId,
        }),
      );

      if (sessionResponse.statusCode != 200) {
        debugPrint('[DexcomService] Failed to get session ID: ${sessionResponse.statusCode}');
        return null;
      }

      return sessionResponse.body.replaceAll('"', '');
    } catch (e) {
      debugPrint('[DexcomService] Session creation failed: $e');
      return null;
    }
  }

  /// Fetch glucose readings directly from the Dexcom Share API.
  /// Returns raw JSON maps with proper handling of all timestamp formats.
  Future<List<Map<String, dynamic>>?> _fetchReadingsRaw({
    int minutes = 1440,
    int? maxCount,
  }) async {
    if (_sessionId == null || _region == null) return null;

    try {
      final baseUrl = _getBaseUrl(_region!);
      final response = await http.post(
        Uri.parse('$baseUrl/Publisher/ReadPublisherLatestGlucoseValues'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sessionId': _sessionId,
          'minutes': minutes,
          'maxCount': maxCount ?? (minutes ~/ 5),
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        debugPrint('[DexcomService] Raw API error: ${response.statusCode} — ${response.body}');
        // Session might have expired, try to recreate
        if (response.statusCode == 500 && _username != null && _password != null) {
          debugPrint('[DexcomService] Attempting session refresh...');
          _sessionId = await _createSession(_username!, _password!, _region!);
          if (_sessionId != null) {
            // Retry once
            final retryResponse = await http.post(
              Uri.parse('$baseUrl/Publisher/ReadPublisherLatestGlucoseValues'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'sessionId': _sessionId,
                'minutes': minutes,
                'maxCount': maxCount ?? (minutes ~/ 5),
              }),
            );
            if (retryResponse.statusCode == 200) {
              final List<dynamic> data = jsonDecode(retryResponse.body);
              return data.cast<Map<String, dynamic>>();
            }
          }
        }
        return null;
      }
    } catch (e) {
      debugPrint('[DexcomService] Raw fetch error: $e');
      rethrow;
    }
  }

  /// Convert Dexcom reading to app's GlucoseReading model
  GlucoseReading _convertToGlucoseReading(dynamic dexcomReading, String patientId) {
    // Extract glucose value (in mg/dL)
    final double value = (dexcomReading['Value'] ?? 0).toDouble();

    // Extract timestamp — Dexcom returns formats like:
    //   1770654779246+0100  (milliseconds + timezone offset)
    //   /Date(1770654779246+0100)/
    //   1770654779246
    final DateTime timestamp = _parseDexcomTimestamp(
      dexcomReading['WT'] ?? dexcomReading['ST'] ?? dexcomReading['DT'],
    );
    final int timestampMs = timestamp.millisecondsSinceEpoch;

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

  /// Parse Dexcom timestamp which can come in several formats:
  ///   - int milliseconds:  1770654779246
  ///   - string with tz:    "1770654779246+0100" or "1770654779246-0500"
  ///   - Date wrapper:      "/Date(1770654779246+0100)/"
  ///   - null → fallback to now
  DateTime _parseDexcomTimestamp(dynamic raw) {
    if (raw == null) return DateTime.now();

    // If it's already an int, use directly
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }

    // Convert to string for parsing
    String s = raw.toString();

    // Strip /Date(...)/ wrapper if present
    final dateWrapperRegex = RegExp(r'/?Date\(([^)]+)\)/?');
    final wrapperMatch = dateWrapperRegex.firstMatch(s);
    if (wrapperMatch != null) {
      s = wrapperMatch.group(1)!;
    }

    // Strip timezone offset (+0100, -0500, etc.) — keep only the milliseconds part
    // The offset is always a sign followed by 4 digits at the end
    final tzRegex = RegExp(r'^(\d+)[+-]\d{4}$');
    final tzMatch = tzRegex.firstMatch(s);
    if (tzMatch != null) {
      s = tzMatch.group(1)!;
    }

    // Parse the milliseconds
    final ms = int.tryParse(s);
    if (ms != null) {
      return DateTime.fromMillisecondsSinceEpoch(ms);
    }

    debugPrint('[DexcomService] Failed to parse timestamp: $raw');
    return DateTime.now();
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
      _sessionId = null;
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
