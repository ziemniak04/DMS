import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dms_app/providers/glucose_provider.dart';
import 'package:dms_app/widgets/glucose_chart.dart';
import 'package:dms_app/core/theme/app_theme.dart';
import 'package:dms_app/core/constants/app_constants.dart';

/// Patient Detail Screen (for doctors)
/// View detailed patient data including glucose chart and events
/// 
/// TODO: [PLACEHOLDER] Load real patient data from Firebase
/// TODO: [PLACEHOLDER] Add event history timeline
/// TODO: [PLACEHOLDER] Add notes functionality
/// TODO: [PLACEHOLDER] Add recommendations feature
class PatientDetailScreen extends StatefulWidget {
  final String patientId;

  const PatientDetailScreen({
    super.key,
    required this.patientId,
  });

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  int _selectedTimeRange = 24;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  void _loadPatientData() {
    // TODO: [PLACEHOLDER] Load real patient data
    context.read<GlucoseProvider>().initializeMockData(widget.patientId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dane pacjenta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.message_outlined),
            onPressed: () {
              // TODO: [PLACEHOLDER] Implement messaging
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Wiadomości - do zaimplementowania'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: [PLACEHOLDER] Show options menu
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Info Card
            _buildPatientInfoCard(),
            
            // Statistics Cards
            _buildStatisticsSection(),
            
            // Glucose Chart
            _buildChartSection(),
            
            // Recent Events
            _buildEventsSection(),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: [PLACEHOLDER] Add note/recommendation
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dodawanie notatki - do zaimplementowania'),
            ),
          );
        },
        icon: const Icon(Icons.note_add),
        label: const Text('Dodaj notatkę'),
      ),
    );
  }

  Widget _buildPatientInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
            child: const Icon(
              Icons.person,
              size: 30,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TODO: [PLACEHOLDER] Use real patient name
                const Text(
                  'Anna Nowak',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ID: ${widget.patientId}',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.glucoseNormal,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Sensor aktywny',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Consumer<GlucoseProvider>(
      builder: (context, glucose, child) {
        final stats = glucose.getStatistics(_selectedTimeRange);
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Średnia',
                  value: '${stats['average']?.toInt() ?? 0}',
                  unit: 'mg/dL',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  title: 'W zakresie',
                  value: '${stats['inRange']?.toInt() ?? 0}',
                  unit: '%',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  title: 'Min/Max',
                  value: '${stats['min']?.toInt() ?? 0}-${stats['max']?.toInt() ?? 0}',
                  unit: '',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChartSection() {
    return Consumer<GlucoseProvider>(
      builder: (context, glucose, child) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Poziom glukozy',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Time range selector
                  Row(
                    children: AppConstants.chartTimeRanges.map((hours) {
                      final isSelected = _selectedTimeRange == hours;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTimeRange = hours;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${hours}h',
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: glucose.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : GlucoseChart(
                        readings: glucose.getReadingsForTimeRange(_selectedTimeRange),
                        hoursRange: _selectedTimeRange,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEventsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ostatnie zdarzenia',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // TODO: [PLACEHOLDER] Load real events from Firebase
          Card(
            child: ListTile(
              leading: const Icon(Icons.medication, color: AppTheme.primaryColor),
              title: const Text('Insulina - 10 jednostek'),
              subtitle: const Text('2 godziny temu'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.restaurant, color: AppTheme.secondaryColor),
              title: const Text('Posiłek - 45g węglowodanów'),
              subtitle: const Text('2 godziny temu'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.directions_run, color: AppTheme.warningColor),
              title: const Text('Aktywność - 30 min'),
              subtitle: const Text('5 godzin temu'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;

  const _StatCard({
    required this.title,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (unit.isNotEmpty)
                Text(
                  ' $unit',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
