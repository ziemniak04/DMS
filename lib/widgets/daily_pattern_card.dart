import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dms_app/models/glucose_reading.dart';
import 'package:dms_app/core/theme/app_theme.dart';

/// Daily Pattern Comparison Card
///
/// Shows glucose patterns across multiple days for comparison
/// Helps identify recurring patterns and anomalies
class DailyPatternCard extends StatelessWidget {
  final List<GlucoseReading> readings;
  final String timeRangeLabel;

  const DailyPatternCard({
    super.key,
    required this.readings,
    this.timeRangeLabel = '24 hours',
  });

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return const SizedBox.shrink();
    }

    final dailyData = _groupByDay();

    if (dailyData.isEmpty) {
      return const SizedBox.shrink();
    }

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
                  Icons.calendar_view_day,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Daily Comparison',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${dailyData.length} days',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Day entries
            ...dailyData.entries.map((entry) {
              final date = entry.key;
              final stats = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildDayRow(date, stats),
              );
            }),

            if (dailyData.length > 1) ...[
              const Divider(height: 24),
              _buildComparison(dailyData),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDayRow(String date, Map<String, dynamic> stats) {
    final average = stats['average'] as double;
    final min = stats['min'] as double;
    final max = stats['max'] as double;
    final count = stats['count'] as int;
    final inRange = stats['inRange'] as double;
    final color = _getGlucoseColor(average);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                '$count readings',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatChip('Avg', average.toStringAsFixed(0), color),
              _buildStatChip('Min', min.toStringAsFixed(0), _getGlucoseColor(min)),
              _buildStatChip('Max', max.toStringAsFixed(0), _getGlucoseColor(max)),
              _buildPercentageChip('${inRange.toStringAsFixed(0)}% TIR', inRange >= 70),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPercentageChip(String text, bool isGood) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isGood
            ? AppTheme.glucoseNormal.withValues(alpha: 0.2)
            : AppTheme.errorColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isGood ? AppTheme.glucoseNormal : AppTheme.errorColor,
        ),
      ),
    );
  }

  Widget _buildComparison(Map<String, Map<String, dynamic>> dailyData) {
    final averages = dailyData.values.map((s) => s['average'] as double).toList();
    final overallAverage = averages.reduce((a, b) => a + b) / averages.length;

    final inRangeValues = dailyData.values.map((s) => s['inRange'] as double).toList();
    final avgInRange = inRangeValues.reduce((a, b) => a + b) / inRangeValues.length;

    // Find best and worst days
    final sortedByInRange = dailyData.entries.toList()
      ..sort((a, b) => (b.value['inRange'] as double).compareTo(a.value['inRange'] as double));

    final bestDay = sortedByInRange.first;
    final worstDay = sortedByInRange.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Summary',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem(
              'Avg Glucose',
              overallAverage.toStringAsFixed(0),
              'mg/dL',
              _getGlucoseColor(overallAverage),
            ),
            _buildSummaryItem(
              'Avg TIR',
              avgInRange.toStringAsFixed(0),
              '%',
              avgInRange >= 70 ? AppTheme.glucoseNormal : AppTheme.errorColor,
            ),
          ],
        ),
        if (dailyData.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDayHighlight(
                  'Best Day',
                  bestDay.key,
                  (bestDay.value['inRange'] as double).toStringAsFixed(0),
                  true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDayHighlight(
                  'Needs Attention',
                  worstDay.key,
                  (worstDay.value['inRange'] as double).toStringAsFixed(0),
                  false,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(
          '$value$unit',
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
          ),
        ),
      ],
    );
  }

  Widget _buildDayHighlight(String label, String day, String tirPercent, bool isPositive) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isPositive
            ? Colors.green.shade50
            : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPositive
              ? Colors.green.shade200
              : Colors.orange.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPositive ? Icons.thumb_up : Icons.priority_high,
                size: 14,
                color: isPositive ? Colors.green.shade700 : Colors.orange.shade700,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isPositive ? Colors.green.shade700 : Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            day,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '$tirPercent% TIR',
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, Map<String, dynamic>> _groupByDay() {
    final Map<String, List<GlucoseReading>> dailyReadings = {};

    // Group readings by day
    for (final reading in readings) {
      final dateKey = DateFormat('dd MMM yyyy').format(reading.timestamp);
      dailyReadings.putIfAbsent(dateKey, () => []).add(reading);
    }

    // Calculate stats for each day
    final Map<String, Map<String, dynamic>> dailyStats = {};

    for (final entry in dailyReadings.entries) {
      final dayReadings = entry.value;
      final values = dayReadings.map((r) => r.value).toList();

      if (values.isEmpty) continue;

      final average = values.reduce((a, b) => a + b) / values.length;
      final min = values.reduce((a, b) => a < b ? a : b);
      final max = values.reduce((a, b) => a > b ? a : b);
      final inRangeCount = values.where((v) => v >= 70 && v <= 180).length;
      final inRangePercent = (inRangeCount / values.length) * 100;

      dailyStats[entry.key] = {
        'count': dayReadings.length,
        'average': average,
        'min': min,
        'max': max,
        'inRange': inRangePercent,
      };
    }

    return dailyStats;
  }

  Color _getGlucoseColor(double value) {
    if (value < 70) return AppTheme.glucoseLow;
    if (value <= 180) return AppTheme.glucoseNormal;
    if (value <= 250) return AppTheme.glucoseHigh;
    return AppTheme.errorColor;
  }
}
