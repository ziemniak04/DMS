import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:dms_app/providers/glucose_provider.dart';
import 'package:dms_app/widgets/glucose_chart.dart';
import 'package:dms_app/core/theme/app_theme.dart';
import 'package:dms_app/core/constants/app_constants.dart';
import 'package:dms_app/models/user.dart';
import 'package:dms_app/models/diabetes_event.dart';
import 'package:dms_app/services/firestore_service.dart';

/// Patient Detail Screen (for doctors)
/// View detailed patient data including glucose chart and events
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
  final FirestoreService _firestoreService = FirestoreService();
  int _selectedTimeRange = 24;
  User? _patient;
  List<DiabetesEvent> _events = [];
  bool _isLoadingPatient = true;
  bool _isLoadingEvents = true;
  String? _patientError;
  String? _eventsError;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    // Load patient info
    _loadPatientInfo();
    // Load glucose readings from Firestore
    _loadGlucoseData();
    // Load events
    _loadEvents();
  }

  Future<void> _loadPatientInfo() async {
    try {
      final patient = await _firestoreService.getUserById(widget.patientId);
      if (mounted) {
        setState(() {
          _patient = patient;
          _isLoadingPatient = false;
          _patientError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPatient = false;
          _patientError = e.toString();
        });
      }
    }
  }

  void _loadGlucoseData() {
    context
        .read<GlucoseProvider>()
        .loadGlucoseReadingsFromFirestore(widget.patientId, hours: 168);
  }

  Future<void> _loadEvents() async {
    try {
      final events = await _firestoreService.getDiabetesEvents(
        widget.patientId,
        hours: 168,
      );
      if (mounted) {
        setState(() {
          _events = events;
          _isLoadingEvents = false;
          _eventsError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingEvents = false;
          _eventsError = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_patient?.name.isNotEmpty == true
            ? _patient!.name
            : 'Patient Data'),
        actions: [
          IconButton(
            icon: const Icon(Icons.message_outlined),
            onPressed: () {
              // TODO: [PLACEHOLDER] Implement messaging
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Messages - to be implemented'),
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
      body: RefreshIndicator(
        onRefresh: _loadPatientData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: [PLACEHOLDER] Add note/recommendation
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Adding note - to be implemented'),
            ),
          );
        },
        icon: const Icon(Icons.note_add),
        label: const Text('Add Note'),
      ),
    );
  }

  Widget _buildPatientInfoCard() {
    if (_isLoadingPatient) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_patientError != null || _patient == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _patientError ?? 'Patient not found',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    }

    final patient = _patient!;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
                Text(
                  patient.name.isNotEmpty ? patient.name : patient.email,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  patient.email,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                if (patient.diabetesType != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Diabetes: ${patient.diabetesType}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
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
                  title: 'Average',
                  value: '${stats['average']?.toInt() ?? 0}',
                  unit: 'mg/dL',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  title: 'In Range',
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
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Glucose Level',
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
                                : AppTheme.secondaryColor.withValues(alpha: 0.15),
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
            'Recent Events',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (_isLoadingEvents)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_eventsError != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.error_outline, color: Colors.red),
                title: Text('Error loading events: $_eventsError'),
              ),
            )
          else if (_events.isEmpty)
            Card(
              child: ListTile(
                leading: Icon(Icons.info_outline, color: AppTheme.textSecondary),
                title: const Text('No recent events'),
                subtitle: const Text('No events recorded for this patient'),
              ),
            )
          else
            ..._events.take(10).map((event) => _buildEventTile(event)),
        ],
      ),
    );
  }

  Widget _buildEventTile(DiabetesEvent event) {
    IconData icon;
    Color color;
    String title;

    switch (event.type) {
      case EventType.insulin:
        icon = Icons.medication;
        color = AppTheme.primaryColor;
        final units = event.data['units'] ?? event.data['dose'] ?? '';
        title = 'Insulin${units != '' ? ' - $units units' : ''}';
        break;
      case EventType.meal:
        icon = Icons.restaurant;
        color = AppTheme.secondaryColor;
        final carbs = event.data['carbs'] ?? '';
        title = 'Meal${carbs != '' ? ' - ${carbs}g carbs' : ''}';
        break;
      case EventType.activity:
        icon = Icons.directions_run;
        color = AppTheme.warningColor;
        final duration = event.data['duration'] ?? '';
        title = 'Activity${duration != '' ? ' - ${duration} min' : ''}';
        break;
      case EventType.bloodGlucose:
        icon = Icons.bloodtype;
        color = Colors.red;
        final value = event.data['value'] ?? '';
        title = 'Blood Glucose${value != '' ? ' - $value mg/dL' : ''}';
        break;
      case EventType.fastingGlucose:
        icon = Icons.wb_sunny;
        color = Colors.orange;
        final value = event.data['value'] ?? '';
        title = 'Fasting Glucose${value != '' ? ' - $value mg/dL' : ''}';
        break;
      case EventType.note:
        icon = Icons.note;
        color = AppTheme.textSecondary;
        title = 'Note';
        break;
    }

    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(_formatTimeAgo(event.timestamp)),
        trailing: event.notes != null && event.notes!.isNotEmpty
            ? Tooltip(
                message: event.notes!,
                child: const Icon(Icons.comment, size: 16),
              )
            : null,
      ),
    );
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hours ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return DateFormat('MMM d, HH:mm').format(time);
    }
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
        color: AppTheme.secondaryColor.withValues(alpha: 0.1),
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
