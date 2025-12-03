import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dms_app/models/glucose_reading.dart';
import 'package:dms_app/core/theme/app_theme.dart';
import 'package:dms_app/core/constants/app_constants.dart';

/// Glucose Chart Widget
/// Displays glucose readings over time with threshold lines
/// 
/// TODO: [PLACEHOLDER] Add touch interaction for reading details
/// TODO: [PLACEHOLDER] Add zoom and pan functionality
/// TODO: [PLACEHOLDER] Add trend arrows overlay
class GlucoseChart extends StatelessWidget {
  final List<GlucoseReading> readings;
  final int hoursRange;

  const GlucoseChart({
    super.key,
    required this.readings,
    this.hoursRange = 24,
  });

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return const Center(
        child: Text('Brak danych do wyświetlenia'),
      );
    }

    final spots = _generateSpots();
    final minY = 40.0;
    final maxY = 400.0;

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 50,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              interval: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: hoursRange / 4,
              getTitlesWidget: (value, meta) {
                final hour = value.toInt();
                if (hour == 0) return const Text('00');
                if (hour == 8) return const Text('08');
                if (hour == 16) return const Text('16');
                if (hour == 24) return const Text('Teraz');
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // Glucose line
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.primaryColor,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
            ),
          ),
        ],
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            // Low threshold line
            HorizontalLine(
              y: AppConstants.glucoseLowThreshold,
              color: AppTheme.glucoseLow,
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
            // High threshold line
            HorizontalLine(
              y: AppConstants.glucoseVeryHighThreshold,
              color: AppTheme.glucoseHigh,
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ],
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${spot.y.toInt()} mg/dL',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  List<FlSpot> _generateSpots() {
    final List<FlSpot> spots = [];
    final now = DateTime.now();
    final startTime = now.subtract(Duration(hours: hoursRange));

    for (final reading in readings) {
      if (reading.timestamp.isAfter(startTime)) {
        final hoursDiff = reading.timestamp.difference(startTime).inMinutes / 60.0;
        spots.add(FlSpot(hoursDiff, reading.value));
      }
    }

    return spots;
  }
}
