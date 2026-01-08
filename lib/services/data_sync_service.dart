import 'package:dms_app/models/glucose_reading.dart';
import 'package:dms_app/models/diabetes_event.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:async';

/// Data Sync Service for Dexcom Integration
/// 
/// Handles:
/// 1. Manual and automatic syncing with backend
/// 2. Glucose readings retrieval and storage
/// 3. Event management (meals, insulin, activity)
/// 4. Daily statistics calculation
/// 5. Offline support with local caching
class DataSyncService {
  final String? backendUrl;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _syncStatusKey = 'sync_status';
  static const String _lastSyncKey = 'last_sync_time';

  DataSyncService({this.backendUrl = 'http://localhost:8000'});

  /// Get current user ID
  String? _getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Get Authorization headers with Firebase token
  Future<Map<String, String>> _getAuthHeaders() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final token = await user.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'X-User-ID': user.uid,
    };
  }

  // ==================== Manual Sync ====================

  /// Manually trigger a data sync
  Future<Map<String, dynamic>> manualSync() async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) throw Exception('User not authenticated');

      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$backendUrl/sync/manual'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _updateLocalSyncStatus('syncing', data);
        return data;
      } else {
        throw Exception('Sync failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in manual sync: $e');
      rethrow;
    }
  }

  // ==================== Auto Sync ====================

  /// Enable automatic periodic syncing
  Future<void> enableAutoSync({int intervalMinutes = 5}) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$backendUrl/sync/auto-enable?interval_minutes=$intervalMinutes'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _updateLocalSyncStatus('auto_enabled', data);
        print('Auto sync enabled: ${data['message']}');
      } else {
        throw Exception('Failed to enable auto sync: ${response.statusCode}');
      }
    } catch (e) {
      print('Error enabling auto sync: $e');
      rethrow;
    }
  }

  /// Disable automatic syncing
  Future<void> disableAutoSync() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$backendUrl/sync/auto-disable'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        _updateLocalSyncStatus('auto_disabled', {});
        print('Auto sync disabled');
      } else {
        throw Exception('Failed to disable auto sync: ${response.statusCode}');
      }
    } catch (e) {
      print('Error disabling auto sync: $e');
      rethrow;
    }
  }

  /// Get current sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$backendUrl/sync/status'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get sync status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting sync status: $e');
      rethrow;
    }
  }

  // ==================== Glucose Readings ====================

  /// Get glucose readings from backend
  Future<List<GlucoseReading>> getGlucoseReadings({
    int days = 7,
    int limit = 100,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$backendUrl/sync/readings?days=$days&limit=$limit'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> readingsJson = data['readings'] ?? [];

        return readingsJson.map((json) {
          return GlucoseReading.fromJson(json);
        }).toList();
      } else {
        throw Exception('Failed to get readings: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting glucose readings: $e');
      rethrow;
    }
  }

  /// Get latest glucose reading
  Future<GlucoseReading?> getLatestReading() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$backendUrl/sync/latest-reading'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['reading'] != null) {
          return GlucoseReading.fromJson(data['reading']);
        }
        return null;
      } else {
        throw Exception('Failed to get latest reading: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting latest reading: $e');
      rethrow;
    }
  }

  // ==================== Events ====================

  /// Get events for a user
  Future<List<DiabetesEvent>> getEvents({
    int days = 7,
    String? eventType,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      String url = '$backendUrl/sync/events?days=$days';
      if (eventType != null) {
        url += '&event_type=$eventType';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> eventsJson = data['events'] ?? [];

        return eventsJson.map((json) {
          return DiabetesEvent.fromJson(json);
        }).toList();
      } else {
        throw Exception('Failed to get events: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting events: $e');
      rethrow;
    }
  }

  // ==================== Statistics ====================

  /// Get daily statistics for a month
  Future<List<Map<String, dynamic>>> getDailyStats({
    int? year,
    int? month,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final now = DateTime.now();
      final y = year ?? now.year;
      final m = month ?? now.month;

      final response = await http.get(
        Uri.parse('$backendUrl/sync/daily-stats?year=$y&month=$m'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['stats'] ?? []);
      } else {
        throw Exception('Failed to get stats: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting daily stats: $e');
      rethrow;
    }
  }

  // ==================== Firestore Direct Access ====================

  /// Watch glucose readings in real-time from Firestore
  Stream<List<GlucoseReading>> watchGlucoseReadings({int days = 7}) {
    final userId = _getCurrentUserId();
    if (userId == null) {
      return Stream.error(Exception('User not authenticated'));
    }

    final startDate = DateTime.now().subtract(Duration(days: days));

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('readings')
        .where('timestamp', isGreaterThanOrEqualTo: startDate)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return GlucoseReading.fromJson(data);
      }).toList();
    });
  }

  /// Watch events in real-time from Firestore
  Stream<List<DiabetesEvent>> watchEvents({
    int days = 7,
    String? eventType,
  }) {
    final userId = _getCurrentUserId();
    if (userId == null) {
      return Stream.error(Exception('User not authenticated'));
    }

    final startDate = DateTime.now().subtract(Duration(days: days));

    var query = _firestore
        .collection('users')
        .doc(userId)
        .collection('events')
        .where('timestamp', isGreaterThanOrEqualTo: startDate);

    if (eventType != null) {
      query = query.where('type', isEqualTo: eventType);
    }

    return query
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return DiabetesEvent.fromJson(data);
      }).toList();
    });
  }

  /// Store a local event to Firestore
  Future<void> storeLocalEvent(DiabetesEvent event) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('events')
          .add(event.toJson());
    } catch (e) {
      print('Error storing event: $e');
      rethrow;
    }
  }

  // ==================== Local Status Management ====================

  void _updateLocalSyncStatus(String status, Map<String, dynamic> data) {
    // Store sync status and timestamp locally for quick access
    print('Sync status updated: $status');
    // Could use SharedPreferences for persistent local storage
  }

  /// Get sync statistics for the dashboard
  Future<Map<String, dynamic>> getSyncStats() async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) throw Exception('User not authenticated');

      // Get latest reading
      final latestReading = await getLatestReading();

      // Get today's reading count
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final readings = await _firestore
          .collection('users')
          .doc(userId)
          .collection('readings')
          .where('timestamp',
              isGreaterThanOrEqualTo: startOfDay,
              isLessThanOrEqualTo: endOfDay)
          .count()
          .get();

      // Get sync status
      final syncStatus = await getSyncStatus();

      return {
        'lastReading': latestReading,
        'todayReadingsCount': readings.count,
        'syncStatus': syncStatus['status'],
        'lastSyncTime': syncStatus['lastSyncTime'],
        'activeSyncJob': syncStatus['activeSyncJob'],
        'timestamp': DateTime.now(),
      };
    } catch (e) {
      print('Error getting sync stats: $e');
      rethrow;
    }
  }
}
