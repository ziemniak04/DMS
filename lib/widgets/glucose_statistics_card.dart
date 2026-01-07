import 'package:flutter/material.dart';
import 'package:dms_app/models/glucose_reading.dart';
import 'package:dms_app/core/theme/app_theme.dart';
import 'dart:math';

/// Enhanced Glucose Statistics Card
///
/// Displays comprehensive statistics for glucose readings including:
/// - Average, Min, Max
/// - Standard Deviation & Coefficient of Variation
/// - Time in Range, Time Above Range, Time Below Range
/// - Estimated HbA1c
class GlucoseStatisticsCard extends StatelessWidget {
  final List<GlucoseReading> readings;
  final String timeRangeLabel;

  const GlucoseStatisticsCard({
    super.key,
    required this.readings,
    this.timeRangeLabel = '24 hours',
  });

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return const SizedBox.shrink();
    }

    final stats = _calculateStatistics();

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
                  Icons.analytics_outlined,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Statistics ($timeRangeLabel)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Primary stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  'Average',
                  stats['average']!.toStringAsFixed(0),
                  'mg/dL',
                  _getGlucoseColor(stats['average']!),
                ),
                _buildStatColumn(
                  'Min',
                  stats['min']!.toStringAsFixed(0),
                  'mg/dL',
                  _getGlucoseColor(stats['min']!),
                ),
                _buildStatColumn(
                  'Max',
                  stats['max']!.toStringAsFixed(0),
                  'mg/dL',
                  _getGlucoseColor(stats['max']!),
                ),
              ],
            ),

            const Divider(height: 24),

            // Variability stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  'Std Dev',
                  stats['stdDev']!.toStringAsFixed(1),
                  'mg/dL',
                  AppTheme.textSecondary,
                ),
                _buildStatColumn(
                  'CV',
                  '${stats['cv']!.toStringAsFixed(0)}%',
                  stats['cv']! < 36 ? 'Good' : 'High',
                  stats['cv']! < 36 ? AppTheme.glucoseNormal : AppTheme.errorColor,
                ),
                _buildStatColumn(
                  'Est. HbA1c',
                  '${stats['hba1c']!.toStringAsFixed(1)}%',
                  '',
                  _getHbA1cColor(stats['hba1c']!),
                ),
              ],
            ),

            const Divider(height: 24),

            // Time in Range
            const Text(
              'Time in Range',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            _buildTimeInRangeBar(
              stats['percentLow']!,
              stats['percentInRange']!,
              stats['percentHigh']!,
              stats['percentVeryHigh']!,
            ),

            const SizedBox(height: 12),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem('Low (<70)', AppTheme.glucoseLow, '${stats['percentLow']!.toStringAsFixed(0)}%'),
                _buildLegendItem('Normal', AppTheme.glucoseNormal, '${stats['percentInRange']!.toStringAsFixed(0)}%'),
                _buildLegendItem('High (>180)', AppTheme.glucoseHigh, '${stats['percentHigh']!.toStringAsFixed(0)}%'),
                _buildLegendItem('Very High (>250)', AppTheme.errorColor, '${stats['percentVeryHigh']!.toStringAsFixed(0)}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, String subtitle, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (subtitle.isNotEmpty)
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  Widget _buildTimeInRangeBar(
    double percentLow,
    double percentInRange,
    double percentHigh,
    double percentVeryHigh,
  ) {
    return Container(
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            if (percentLow > 0)
              Expanded(
                flex: (percentLow * 100).toInt(),
                child: Container(color: AppTheme.glucoseLow),
              ),
            if (percentInRange > 0)
              Expanded(
                flex: (percentInRange * 100).toInt(),
                child: Container(color: AppTheme.glucoseNormal),
              ),
            if (percentHigh > 0)
              Expanded(
                flex: (percentHigh * 100).toInt(),
                child: Container(color: AppTheme.glucoseHigh),
              ),
            if (percentVeryHigh > 0)
              Expanded(
                flex: (percentVeryHigh * 100).toInt(),
                child: Container(color: AppTheme.errorColor),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, String percent) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              percent,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Map<String, double> _calculateStatistics() {
    final values = readings.map((r) => r.value).toList();

    // Basic stats
    final average = values.reduce((a, b) => a + b) / values.length;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);

    // Standard deviation
    final variance = values
        .map((v) => pow(v - average, 2))
        .reduce((a, b) => a + b) / values.length;
    final stdDev = sqrt(variance);

    // Coefficient of variation (target <36% for good glycemic control)
    final cv = (stdDev / average) * 100;

    // Estimated HbA1c (eAG formula: HbA1c% = (average + 46.7) / 28.7)
    final hba1c = (average + 46.7) / 28.7;

    // Time in ranges
    final lowCount = values.where((v) => v < 70).length;
    final inRangeCount = values.where((v) => v >= 70 && v <= 180).length;
    final highCount = values.where((v) => v > 180 && v <= 250).length;
    final veryHighCount = values.where((v) => v > 250).length;

    final total = values.length.toDouble();

    return {
      'average': average,
      'min': min,
      'max': max,
      'stdDev': stdDev,
      'cv': cv,
      'hba1c': hba1c,
      'percentLow': lowCount / total,
      'percentInRange': inRangeCount / total,
      'percentHigh': highCount / total,
      'percentVeryHigh': veryHighCount / total,
    };
  }

  Color _getGlucoseColor(double value) {
    if (value < 70) return AppTheme.glucoseLow;
    if (value <= 180) return AppTheme.glucoseNormal;
    if (value <= 250) return AppTheme.glucoseHigh;
    return AppTheme.errorColor;
  }

  Color _getHbA1cColor(double value) {
    if (value < 7.0) return AppTheme.glucoseNormal;
    if (value < 8.0) return AppTheme.glucoseHigh;
    return AppTheme.errorColor;
  }
}
