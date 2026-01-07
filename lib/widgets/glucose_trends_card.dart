import 'package:flutter/material.dart';
import 'package:dms_app/core/theme/app_theme.dart';
import 'package:dms_app/models/glucose_reading.dart';

/// Glucose Trends Card Widget
/// Displays trend information with visual indicators
class GlucoseTrendsCard extends StatelessWidget {
  final List<GlucoseReading> readings;
  final String timeRange;

  const GlucoseTrendsCard({
    super.key,
    required this.readings,
    required this.timeRange,
  });

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return _buildEmptyState(context);
    }

    final trends = _calculateTrends();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Glucose Trends',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            // Current vs Average
            _buildTrendRow(
              context,
              'Current',
              '${readings.last.value.toStringAsFixed(0)} mg/dL',
              _getTrendIcon(readings.last.trend),
              _getTrendColor(readings.last.value),
            ),
            const SizedBox(height: 12),
            _buildTrendRow(
              context,
              'Average',
              '${trends['average']!.toStringAsFixed(0)} mg/dL',
              Icons.trending_flat,
              Colors.grey,
            ),
            const SizedBox(height: 12),
            _buildTrendRow(
              context,
              'Range',
              '${trends['min']!.toStringAsFixed(0)} - ${trends['max']!.toStringAsFixed(0)} mg/dL',
              Icons.unfold_more,
              Colors.grey,
            ),
            const SizedBox(height: 16),
            // Time in Range indicator
            _buildTimeInRangeIndicator(
              context,
              trends['timeInRange'] as double,
              isDarkMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'No data available',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }

  Widget _buildTrendRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeInRangeIndicator(
    BuildContext context,
    double percentage,
    bool isDarkMode,
  ) {
    final backgroundColor = isDarkMode ? AppTheme.darkCardColor : Colors.grey.shade200;
    final fillColor = _getTimeInRangeColor(percentage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Time in Range (70-180)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: fillColor,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 8,
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: backgroundColor,
              valueColor: AlwaysStoppedAnimation<Color>(fillColor),
            ),
          ),
        ),
      ],
    );
  }

  /// Calculate trend statistics from readings
  Map<String, dynamic> _calculateTrends() {
    final values = readings.map((r) => r.value).toList();
    final average = values.reduce((a, b) => a + b) / values.length;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);

    // Time in range: 70-180 mg/dL
    final inRange = readings.where((r) => r.value >= 70 && r.value <= 180).length;
    final timeInRange = (inRange / readings.length) * 100;

    return {
      'average': average,
      'min': min,
      'max': max,
      'timeInRange': timeInRange,
    };
  }

  /// Get trend icon based on trend direction
  IconData _getTrendIcon(String? trend) {
    switch (trend?.toLowerCase()) {
      case 'rising':
      case 'rising_fast':
        return Icons.trending_up;
      case 'falling':
      case 'falling_fast':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  /// Get color based on glucose value
  Color _getTrendColor(double value) {
    if (value < 70) return AppTheme.glucoseLow;
    if (value < 180) return AppTheme.glucoseNormal;
    if (value < 250) return AppTheme.glucoseHigh;
    return AppTheme.glucoseVeryHigh;
  }

  /// Get color for time in range indicator
  Color _getTimeInRangeColor(double percentage) {
    if (percentage >= 70) return AppTheme.glucoseNormal;
    if (percentage >= 50) return AppTheme.glucoseHigh;
    return AppTheme.glucoseLow;
  }
}
