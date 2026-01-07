import 'package:flutter/material.dart';
import 'package:dms_app/models/glucose_reading.dart';
import 'package:dms_app/core/theme/app_theme.dart';

/// Period-Based Glucose Analysis Card
///
/// Breaks down glucose readings by time of day:
/// - Night (00:00 - 06:00)
/// - Morning (06:00 - 12:00)
/// - Afternoon (12:00 - 18:00)
/// - Evening (18:00 - 00:00)
class PeriodAnalysisCard extends StatelessWidget {
  final List<GlucoseReading> readings;
  final String timeRangeLabel;

  const PeriodAnalysisCard({
    super.key,
    required this.readings,
    this.timeRangeLabel = '24 hours',
  });

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return const SizedBox.shrink();
    }

    final periodStats = _analyzePeriods();

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.wb_twilight,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Daily Pattern Analysis ($timeRangeLabel)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Period breakdowns
            _buildPeriodRow(
              context,
              'Night',
              Icons.nightlight_round,
              '00:00 - 06:00',
              periodStats['night']!,
            ),
            const SizedBox(height: 12),
            _buildPeriodRow(
              context,
              'Morning',
              Icons.wb_sunny,
              '06:00 - 12:00',
              periodStats['morning']!,
            ),
            const SizedBox(height: 12),
            _buildPeriodRow(
              context,
              'Afternoon',
              Icons.light_mode,
              '12:00 - 18:00',
              periodStats['afternoon']!,
            ),
            const SizedBox(height: 12),
            _buildPeriodRow(
              context,
              'Evening',
              Icons.nights_stay,
              '18:00 - 00:00',
              periodStats['evening']!,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodRow(
    BuildContext context,
    String label,
    IconData icon,
    String timeRange,
    Map<String, dynamic> stats,
  ) {
    final count = stats['count'] as int;
    final average = stats['average'] as double;
    final inRange = stats['inRange'] as double;
    final color = _getGlucoseColor(average);

    if (count == 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey.shade400, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    timeRange,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              'No data',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      timeRange,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    average.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const Text(
                    'mg/dL avg',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$count readings',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: inRange >= 70
                      ? AppTheme.glucoseNormal.withValues(alpha: 0.2)
                      : AppTheme.errorColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${inRange.toStringAsFixed(0)}% in range',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: inRange >= 70 ? AppTheme.glucoseNormal : AppTheme.errorColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, Map<String, dynamic>> _analyzePeriods() {
    final periods = {
      'night': <GlucoseReading>[],      // 00:00 - 06:00
      'morning': <GlucoseReading>[],    // 06:00 - 12:00
      'afternoon': <GlucoseReading>[],  // 12:00 - 18:00
      'evening': <GlucoseReading>[],    // 18:00 - 00:00
    };

    // Categorize readings by period
    for (final reading in readings) {
      final hour = reading.timestamp.hour;
      if (hour >= 0 && hour < 6) {
        periods['night']!.add(reading);
      } else if (hour >= 6 && hour < 12) {
        periods['morning']!.add(reading);
      } else if (hour >= 12 && hour < 18) {
        periods['afternoon']!.add(reading);
      } else {
        periods['evening']!.add(reading);
      }
    }

    // Calculate stats for each period
    final Map<String, Map<String, dynamic>> stats = {};

    for (final entry in periods.entries) {
      final periodReadings = entry.value;

      if (periodReadings.isEmpty) {
        stats[entry.key] = {
          'count': 0,
          'average': 0.0,
          'inRange': 0.0,
        };
        continue;
      }

      final values = periodReadings.map((r) => r.value).toList();
      final average = values.reduce((a, b) => a + b) / values.length;
      final inRangeCount = values.where((v) => v >= 70 && v <= 180).length;
      final inRangePercent = (inRangeCount / values.length) * 100;

      stats[entry.key] = {
        'count': periodReadings.length,
        'average': average,
        'inRange': inRangePercent,
      };
    }

    return stats;
  }

  Color _getGlucoseColor(double value) {
    if (value < 70) return AppTheme.glucoseLow;
    if (value <= 180) return AppTheme.glucoseNormal;
    if (value <= 250) return AppTheme.glucoseHigh;
    return AppTheme.errorColor;
  }
}
