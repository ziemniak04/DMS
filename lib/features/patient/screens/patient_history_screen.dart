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
    final statusColor = isActive ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.all(16),
      color: statusColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isActive ? Icons.sensors : Icons.sensors_off,
              color: statusColor,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isActive ? 'Sensor active' : 'Sensor inactive',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusColor.shade700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _historyResult!.message,
                    style: TextStyle(
                      color: statusColor.shade700,
                      fontSize: 12,
                    ),
                  ),
                  if (_historyResult!.lastReadingTime != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Last reading: ${DateFormat('dd.MM.yyyy HH:mm').format(_historyResult!.lastReadingTime!)}',
                      style: TextStyle(
                        color: statusColor.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_historyResult!.hasData)
              Column(
                children: [
                  Text(
                    '${_historyResult!.readings.length}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: statusColor.shade700,
                    ),
                  ),
                  Text(
                    'readings',
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor.shade700,
                    ),
                  ),
                ],
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
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected && !_isLoading) {
            setState(() {
              _selectedHours = hours;
            });
            _loadHistory();
          }
        },
        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
    
    return Column(
      children: [
        Expanded(
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
      ],
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

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Average', '${avg.toStringAsFixed(0)} mg/dL', _getGlucoseColor(avg)),
            _buildStatItem('Min', '${min.toStringAsFixed(0)} mg/dL', _getGlucoseColor(min)),
            _buildStatItem('Max', '${max.toStringAsFixed(0)} mg/dL', _getGlucoseColor(max)),
            _buildStatItem('In Range', '$inRangePercent%', AppTheme.glucoseNormal),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
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
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
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
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              reading.value.toStringAsFixed(0),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              '${reading.value.toStringAsFixed(0)} mg/dL',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Icon(
              _getTrendIcon(reading.trend),
              size: 20,
              color: color,
            ),
          ],
        ),
        subtitle: Text(
          DateFormat('HH:mm').format(reading.timestamp),
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        trailing: Text(
          _formatTimestamp(reading.timestamp),
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
