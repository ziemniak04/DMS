import 'package:flutter/material.dart';
import 'package:dms_app/models/glucose_reading.dart';
import 'package:dms_app/services/dexcom_service.dart';
import 'package:dms_app/services/firestore_service.dart';
import 'dart:math';
import 'dart:async';

/// Glucose Data Provider
///
/// Integrated with Dexcom CGM for real-time glucose monitoring
class GlucoseProvider extends ChangeNotifier {
  final DexcomService _dexcomService = DexcomService();
  final FirestoreService _firestoreService = FirestoreService();

  List<GlucoseReading> _readings = [];
  GlucoseReading? _currentReading;
  bool _isLoading = false;
  bool _sensorConnected = false;
  String? _error;
  StreamSubscription<GlucoseReading>? _glucoseStreamSubscription;

  List<GlucoseReading> get readings => _readings;
  GlucoseReading? get currentReading => _currentReading;
  bool get isLoading => _isLoading;
  bool get sensorConnected => _sensorConnected;
  String? get error => _error;

  /// Get readings for a specific time range
  List<GlucoseReading> getReadingsForTimeRange(int hours) {
    final cutoff = DateTime.now().subtract(Duration(hours: hours));
    return _readings.where((r) => r.timestamp.isAfter(cutoff)).toList();
  }

  /// Initialize with Dexcom service
  Future<void> initializeDexcom(String patientId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Try to authenticate with stored credentials
      final authenticated = await _dexcomService.initialize();

      if (authenticated) {
        _sensorConnected = true;
        // Load glucose readings for the last 24 hours
        await loadGlucoseReadings(patientId, hours: 24);
      } else {
        _sensorConnected = false;
        _error = 'Dexcom not connected. Please authenticate.';
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize Dexcom: ${e.toString()}';
      _isLoading = false;
      _sensorConnected = false;
      notifyListeners();
    }
  }

  /// Initialize with mock data (for testing without Dexcom)
  Future<void> initializeMockData(String patientId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Generate mock glucose data for the last 24 hours
      _readings = _generateMockReadings(patientId, hours: 24);
      _currentReading = _readings.isNotEmpty ? _readings.last : null;
      _sensorConnected = false; // Mock sensor not connected state

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load glucose data: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load glucose readings from Dexcom
  Future<void> loadGlucoseReadings(String patientId, {int hours = 24}) async {
    if (!_dexcomService.isAuthenticated) {
      _error = 'Not authenticated with Dexcom';
      notifyListeners();
      return;
    }

    try {
      _readings = await _dexcomService.getReadings(
        patientId,
        minutes: hours * 60,
      );
      _currentReading = _readings.isNotEmpty ? _readings.last : null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load glucose readings: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Load glucose readings from Firestore (for mock accounts)
  Future<void> loadGlucoseReadingsFromFirestore(String patientId, {int hours = 24}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('Loading glucose readings from Firestore for patientId: $patientId');
      _readings = await _firestoreService.getGlucoseReadings(patientId, hours: hours);
      _currentReading = _readings.isNotEmpty ? _readings.last : null;
      _sensorConnected = false; // Firestore data, not real sensor
      print('Loaded ${_readings.length} glucose readings from Firestore');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading glucose readings from Firestore: $e');
      _error = 'Failed to load glucose readings from database: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Authenticate with Dexcom
  Future<bool> authenticateDexcom(
    String patientId,
    String username,
    String password, {
    String region = 'us',
    bool saveCredentials = true,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final authenticated = await _dexcomService.authenticate(
        username,
        password,
        region: region,
        saveCredentials: saveCredentials,
      );

      if (authenticated) {
        _sensorConnected = true;
        // Load initial data
        await loadGlucoseReadings(patientId, hours: 24);
        _error = null;
      } else {
        _sensorConnected = false;
        _error = 'Failed to authenticate with Dexcom';
      }

      _isLoading = false;
      notifyListeners();
      return authenticated;
    } catch (e) {
      _error = 'Dexcom authentication error: ${e.toString()}';
      _sensorConnected = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Generate mock readings for testing
  List<GlucoseReading> _generateMockReadings(String patientId, {int hours = 24}) {
    final List<GlucoseReading> mockReadings = [];
    final random = Random(42); // Fixed seed for consistent data
    final now = DateTime.now();
    
    // Generate reading every 5 minutes
    final totalReadings = hours * 12;
    double baseValue = 120.0;
    
    for (int i = totalReadings; i >= 0; i--) {
      // Simulate realistic glucose fluctuations
      baseValue += (random.nextDouble() - 0.5) * 10;
      
      // Add meal spikes
      final hour = (now.subtract(Duration(minutes: i * 5))).hour;
      if (hour == 8 || hour == 13 || hour == 19) {
        baseValue += random.nextDouble() * 30;
      }
      
      // Keep within realistic bounds
      baseValue = baseValue.clamp(60.0, 300.0);
      
      mockReadings.add(GlucoseReading(
        id: 'reading_$i',
        patientId: patientId,
        value: baseValue,
        timestamp: now.subtract(Duration(minutes: i * 5)),
        trend: _calculateTrend(baseValue, mockReadings.isNotEmpty ? mockReadings.last.value : baseValue),
        source: 'sensor',
      ));
    }
    
    return mockReadings;
  }

  String _calculateTrend(double current, double previous) {
    final diff = current - previous;
    if (diff > 3) return 'rising_fast';
    if (diff > 1) return 'rising';
    if (diff < -3) return 'falling_fast';
    if (diff < -1) return 'falling';
    return 'stable';
  }

  /// Connect to Dexcom sensor (alias for backwards compatibility)
  Future<bool> connectSensor() async {
    // Check if already authenticated
    return _dexcomService.isAuthenticated;
  }

  /// Disconnect from Dexcom sensor
  Future<void> disconnectSensor() async {
    await stopGlucoseStream();
    await _dexcomService.signOut();
    _sensorConnected = false;
    _readings.clear();
    _currentReading = null;
    notifyListeners();
  }

  /// Fetch all available history from Dexcom (up to 24 hours)
  /// 
  /// This is useful for users who want to see their historical data
  /// even when their sensor is not currently active.
  Future<DexcomHistoryResult> fetchHistoryWithStatus(String patientId, {int hours = 24}) async {
    if (!_dexcomService.isAuthenticated) {
      return DexcomHistoryResult(
        readings: [],
        sensorActive: false,
        lastReadingTime: null,
        message: 'Not authenticated with Dexcom. Please connect your account.',
      );
    }

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _dexcomService.getHistoryWithStatus(patientId, hours: hours);
      
      if (result.hasData) {
        _readings = result.readings;
        _currentReading = result.readings.isNotEmpty ? result.readings.first : null;
        _sensorConnected = result.sensorActive;
      }

      _isLoading = false;
      _error = result.sensorActive ? null : result.message;
      notifyListeners();
      
      return result;
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to fetch history: ${e.toString()}';
      notifyListeners();
      
      return DexcomHistoryResult(
        readings: [],
        sensorActive: false,
        lastReadingTime: null,
        message: _error!,
      );
    }
  }

  /// Fetch full 24-hour history from Dexcom
  Future<void> fetchFullHistory(String patientId) async {
    if (!_dexcomService.isAuthenticated) {
      _error = 'Not authenticated with Dexcom';
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _readings = await _dexcomService.getFullHistory(patientId);
      
      if (_readings.isNotEmpty) {
        // Sort by timestamp descending
        _readings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _currentReading = _readings.first;
        
        // Check if sensor is active (last reading within 15 minutes)
        final timeSinceLastReading = DateTime.now().difference(_currentReading!.timestamp);
        _sensorConnected = timeSinceLastReading.inMinutes <= 15;
      } else {
        _sensorConnected = false;
      }

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to fetch history: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Start real-time glucose data streaming
  /// Automatically updates glucose readings every 5 minutes (default Dexcom interval)
  Future<void> startGlucoseStream(String patientId, {int intervalSeconds = 300}) async {
    if (!_dexcomService.isAuthenticated) {
      _error = 'Not authenticated with Dexcom';
      notifyListeners();
      return;
    }

    try {
      // Cancel existing stream if any
      await stopGlucoseStream();

      // Start new stream
      _glucoseStreamSubscription = _dexcomService
          .streamReadings(patientId, seconds: intervalSeconds)
          .listen(
        (reading) {
          // Add new reading to the list
          _readings.add(reading);
          _currentReading = reading;

          // Keep only last 24 hours of data
          final cutoff = DateTime.now().subtract(const Duration(hours: 24));
          _readings.removeWhere((r) => r.timestamp.isBefore(cutoff));

          notifyListeners();
        },
        onError: (error) {
          _error = 'Glucose stream error: ${error.toString()}';
          notifyListeners();
        },
      );

      _sensorConnected = true;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to start glucose stream: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Stop real-time glucose data streaming
  Future<void> stopGlucoseStream() async {
    await _glucoseStreamSubscription?.cancel();
    _glucoseStreamSubscription = null;
  }

  /// Get current reading from Dexcom
  Future<void> refreshCurrentReading(String patientId) async {
    if (!_dexcomService.isAuthenticated) {
      _error = 'Not authenticated with Dexcom';
      notifyListeners();
      return;
    }

    try {
      final reading = await _dexcomService.getCurrentReading(patientId);
      if (reading != null) {
        _currentReading = reading;
        // Add to readings if it's newer
        if (_readings.isEmpty || reading.timestamp.isAfter(_readings.last.timestamp)) {
          _readings.add(reading);
        }
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to refresh reading: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Check if Dexcom credentials are stored
  Future<bool> hasDexcomCredentials() async {
    return await _dexcomService.hasStoredCredentials();
  }

  /// Add manual reading
  Future<void> addManualReading(double value, {String? notes}) async {
    final reading = GlucoseReading(
      id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
      patientId: _currentReading?.patientId ?? 'unknown',
      value: value,
      timestamp: DateTime.now(),
      source: 'manual',
    );
    
    _readings.add(reading);
    _currentReading = reading;
    
    // TODO: [PLACEHOLDER] Save to Firebase
    
    notifyListeners();
  }

  /// Get statistics for a time range
  Map<String, double> getStatistics(int hours) {
    final rangeReadings = getReadingsForTimeRange(hours);
    if (rangeReadings.isEmpty) {
      return {'average': 0, 'min': 0, 'max': 0, 'inRange': 0};
    }

    final values = rangeReadings.map((r) => r.value).toList();
    final average = values.reduce((a, b) => a + b) / values.length;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final inRange = values.where((v) => v >= 70 && v <= 180).length / values.length * 100;

    return {
      'average': average,
      'min': min,
      'max': max,
      'inRange': inRange,
    };
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _glucoseStreamSubscription?.cancel();
    super.dispose();
  }
}
