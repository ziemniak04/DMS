import 'package:dms_app/models/glucose_reading.dart';
import 'dart:math';

/// Mock Analysis Service for demonstrating analysis functionality
class MockAnalysisService {
  /// Generate mock glucose readings for the last N hours
  static List<GlucoseReading> generateMockReadings({int hours = 24}) {
    final readings = <GlucoseReading>[];
    final now = DateTime.now();
    final random = Random();

    for (int i = 0; i < hours * 4; i++) {
      // 4 readings per hour (one every 15 minutes)
      final time = now.subtract(Duration(minutes: i * 15));

      // Generate realistic glucose values (70-200 mg/dL with some variation)
      final baseValue = 120 + random.nextInt(80) - 40;
      final value = baseValue.clamp(40, 400);

      final trend = ['steady', 'rising', 'falling'][random.nextInt(3)];
      final trendRate = random.nextDouble() * 4 - 2; // -2 to 2 mg/dL per min

      readings.add(
        GlucoseReading(
          id: 'mock_$i',
          patientId: 'mock_patient',
          value: value.toDouble(),
          timestamp: time,
          trend: trend,
          source: 'sensor',
        ),
      );
    }

    return readings.reversed.toList();
  }

  /// Calculate statistics from readings
  static Map<String, dynamic> calculateStatistics(List<GlucoseReading> readings) {
    if (readings.isEmpty) {
      return {
        'average': 0.0,
        'min': 0.0,
        'max': 0.0,
        'stdev': 0.0,
        'timeInRange': 0.0,
        'timeHigh': 0.0,
        'timeLow': 0.0,
        'readingCount': 0,
      };
    }

    final values = readings.map((r) => r.value).toList();

    // Calculate average
    final average = values.reduce((a, b) => a + b) / values.length;

    // Calculate min and max
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);

    // Calculate standard deviation
    final squaredDiffs = values.map((v) => (v - average) * (v - average));
    final variance = squaredDiffs.reduce((a, b) => a + b) / values.length;
    final stdev = sqrt(variance);

    // Time in range (80-180 mg/dL is target)
    const targetMin = 80.0;
    const targetMax = 180.0;
    final inRange =
        values.where((v) => v >= targetMin && v <= targetMax).length;
    final timeInRange = (inRange / values.length) * 100;

    // Time high (> 180)
    final high = values.where((v) => v > targetMax).length;
    final timeHigh = (high / values.length) * 100;

    // Time low (< 80)
    final low = values.where((v) => v < targetMin).length;
    final timeLow = (low / values.length) * 100;

    return {
      'average': average.toStringAsFixed(1),
      'min': min.toStringAsFixed(0),
      'max': max.toStringAsFixed(0),
      'stdev': stdev.toStringAsFixed(1),
      'timeInRange': timeInRange.toStringAsFixed(1),
      'timeHigh': timeHigh.toStringAsFixed(1),
      'timeLow': timeLow.toStringAsFixed(1),
      'readingCount': values.length,
    };
  }

  /// Detect trends from readings
  static String analyzeTrend(List<GlucoseReading> readings) {
    if (readings.length < 4) return 'Insufficient data';

    final recent = readings.take(4).toList();
    final older = readings.skip(4).take(4).toList();

    if (recent.isEmpty || older.isEmpty) return 'Insufficient data';

    final recentAvg = recent.map((r) => r.value).reduce((a, b) => a + b) / recent.length;
    final olderAvg = older.map((r) => r.value).reduce((a, b) => a + b) / older.length;

    final difference = recentAvg - olderAvg;

    if (difference > 15) {
      return '📈 Rising trend';
    } else if (difference < -15) {
      return '📉 Falling trend';
    } else {
      return '→ Stable trend';
    }
  }

  /// Get daily pattern analysis
  static String analyzeDailyPattern(List<GlucoseReading> readings) {
    if (readings.isEmpty) return 'No data available';

    final values = readings.map((r) => r.value).toList();
    final average = values.reduce((a, b) => a + b) / values.length;

    if (average < 100) {
      return '✓ Good control with lower readings';
    } else if (average > 180) {
      return '⚠ Consider reviewing medication or carbs';
    } else {
      return '✓ Within reasonable range';
    }
  }

  /// Get HbA1c estimate (simplified)
  static String estimateHbA1c(double averageGlucose) {
    // Simplified formula: (Average glucose + 46.7) / 28.7
    final estimated = (averageGlucose + 46.7) / 28.7;
    return estimated.toStringAsFixed(1);
  }
}
