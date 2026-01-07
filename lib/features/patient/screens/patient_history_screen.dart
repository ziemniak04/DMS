import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:dms_app/core/theme/app_theme.dart';
import 'package:dms_app/providers/glucose_provider.dart';
import 'package:dms_app/providers/auth_provider.dart';
import 'package:dms_app/models/glucose_reading.dart';
import 'package:dms_app/services/dexcom_service.dart';
import 'package:dms_app/widgets/glucose_chart.dart';
import 'package:dms_app/widgets/glucose_statistics_card.dart';
import 'package:dms_app/widgets/period_analysis_card.dart';
import 'package:dms_app/widgets/daily_pattern_card.dart';

/// Patient History Screen
/// 
/// Displays glucose history from Dexcom with sensor status information.
/// Shows historical data even when sensor is not currently active.
class PatientHistoryScreen extends StatefulWidget {
  const PatientHistoryScreen({super.key});

  @override
  State<PatientHistoryScreen> createState() => _PatientHistoryScreenState();
}

class _PatientHistoryScreenState extends State<PatientHistoryScreen> {
  DexcomHistoryResult? _historyResult;
  bool _isLoading = false;
  int _selectedHours = 24;
  String _selectedView = 'list'; // 'list' or 'chart'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
    });
  }

  Future<void> _loadHistory() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final glucoseProvider = Provider.of<GlucoseProvider>(context, listen: false);
    final patientId = authProvider.currentUser?.id ?? '';

    if (patientId.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    final result = await glucoseProvider.fetchHistoryWithStatus(
      patientId,
      hours: _selectedHours,
    );

    setState(() {
      _historyResult = result;
      _isLoading = false;
    });
  }

  Color _getGlucoseColor(double value) {
    if (value < 70) return AppTheme.glucoseLow;
    if (value > 180) return AppTheme.glucoseHigh;
    return AppTheme.glucoseNormal;
  }

  IconData _getTrendIcon(String? trend) {
    switch (trend) {
      case 'rising_fast':
        return Icons.arrow_upward;
      case 'rising':
        return Icons.trending_up;
      case 'falling_fast':
        return Icons.arrow_downward;
      case 'falling':
        return Icons.trending_down;
      case 'stable':
      default:
        return Icons.trending_flat;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hrs ago';
    } else {
      return DateFormat('dd.MM.yyyy HH:mm').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          // View toggle
          IconButton(
            icon: Icon(_selectedView == 'list' ? Icons.show_chart : Icons.list),
            onPressed: () {
              setState(() {
                _selectedView = _selectedView == 'list' ? 'chart' : 'list';
              });
            },
            tooltip: _selectedView == 'list' ? 'Show Chart' : 'Show List',
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadHistory,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Sensor Status Card
          _buildSensorStatusCard(),
          
          // Time Range Selector
          _buildTimeRangeSelector(),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorStatusCard() {
    if (_historyResult == null) return const SizedBox.shrink();

    final isActive = _historyResult!.sensorActive;
    final statusColor = isActive ? AppTheme.glucoseNormal : AppTheme.warningColor;
    final bgColor = isActive ? AppTheme.glucoseNormal : AppTheme.warningColor;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bgColor.withValues(alpha: 0.15),
            bgColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bgColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isActive ? Icons.sensors : Icons.sensors_off,
                color: statusColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isActive ? 'Sensor Active' : 'Sensor Inactive',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _historyResult!.message,
                    style: TextStyle(
                      color: statusColor.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                  if (_historyResult!.lastReadingTime != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Last reading: ${DateFormat('dd.MM.yyyy HH:mm').format(_historyResult!.lastReadingTime!)}',
                      style: TextStyle(
                        color: statusColor.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_historyResult!.hasData)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      '${_historyResult!.readings.length}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    Text(
                      'readings',
                      style: TextStyle(
                        fontSize: 11,
                        color: statusColor.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTimeChip(3, '3 hrs'),
          _buildTimeChip(6, '6 hrs'),
          _buildTimeChip(12, '12 hrs'),
          _buildTimeChip(24, '24 hrs'),
        ],
      ),
    );
  }

  Widget _buildTimeChip(int hours, String label) {
    final isSelected = _selectedHours == hours;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.primaryColor.withValues(alpha: 0.5),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isLoading ? null : () {
              setState(() {
                _selectedHours = hours;
              });
              _loadHistory();
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.primaryColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_historyResult == null || !_historyResult!.hasData) {
      return _buildEmptyState();
    }

    if (_selectedView == 'chart') {
      return _buildChartView();
    } else {
      return _buildListView();
    }
  }

  Widget _buildEmptyState() {
    final glucoseProvider = Provider.of<GlucoseProvider>(context);
    final isConnected = glucoseProvider.sensorConnected;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isConnected ? Icons.hourglass_empty : Icons.sensors_off,
              size: 64,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              isConnected
                  ? 'No data to display'
                  : 'Not connected to Dexcom',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isConnected
                  ? 'Wait for new sensor readings'
                  : 'Connect your Dexcom account in settings to view reading history',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            if (!isConnected)
              ElevatedButton.icon(
                onPressed: () {
                  context.push('/settings/dexcom');
                },
                icon: const Icon(Icons.link),
                label: const Text('Connect Dexcom'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartView() {
    final readings = _historyResult!.readings;

    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: 300,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GlucoseChart(
                readings: readings,
                hoursRange: _selectedHours,
              ),
            ),
          ),
          // Statistics summary
          _buildStatisticsCard(readings),
          // Enhanced statistics
          GlucoseStatisticsCard(
            readings: readings,
            timeRangeLabel: _selectedHours == 24 ? '24 hrs' : '$_selectedHours hrs',
          ),
          // Period analysis
          PeriodAnalysisCard(
            readings: readings,
            timeRangeLabel: _selectedHours == 24 ? '24 hrs' : '$_selectedHours hrs',
          ),
          // Daily pattern
          DailyPatternCard(
            readings: readings,
            timeRangeLabel: _selectedHours == 24 ? '24 hrs' : '$_selectedHours hrs',
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard(List<GlucoseReading> readings) {
    if (readings.isEmpty) return const SizedBox.shrink();

    final values = readings.map((r) => r.value).toList();
    final avg = values.reduce((a, b) => a + b) / values.length;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final inRange = values.where((v) => v >= 70 && v <= 180).length;
    final inRangePercent = (inRange / values.length * 100).toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.08),
            AppTheme.secondaryColor.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Average', '${avg.toStringAsFixed(0)}', _getGlucoseColor(avg)),
            _buildStatItemDivider(),
            _buildStatItem('Min', '${min.toStringAsFixed(0)}', _getGlucoseColor(min)),
            _buildStatItemDivider(),
            _buildStatItem('Max', '${max.toStringAsFixed(0)}', _getGlucoseColor(max)),
            _buildStatItemDivider(),
            _buildStatItem('Range', '$inRangePercent%', AppTheme.glucoseNormal),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItemDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppTheme.primaryColor.withValues(alpha: 0.2),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    final readings = _historyResult!.readings;
    
    // Group readings by date
    final groupedReadings = <String, List<GlucoseReading>>{};
    for (final reading in readings) {
      final dateKey = DateFormat('dd MMMM yyyy', 'en').format(reading.timestamp);
      groupedReadings.putIfAbsent(dateKey, () => []).add(reading);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: groupedReadings.length,
      itemBuilder: (context, index) {
        final dateKey = groupedReadings.keys.elementAt(index);
        final dayReadings = groupedReadings[dateKey]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                dateKey,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            ...dayReadings.map((reading) => _buildReadingTile(reading)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildReadingTile(GlucoseReading reading) {
    final color = _getGlucoseColor(reading.value);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.25),
                color.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          ),
          child: Center(
            child: Text(
              reading.value.toStringAsFixed(0),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 18,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                '${reading.value.toStringAsFixed(0)} mg/dL',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getTrendIcon(reading.trend),
                size: 20,
                color: color,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('HH:mm').format(reading.timestamp),
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _formatTimestamp(reading.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
