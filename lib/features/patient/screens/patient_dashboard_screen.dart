import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:dms_app/providers/glucose_provider.dart';
import 'package:dms_app/providers/auth_provider.dart';
import 'package:dms_app/providers/settings_provider.dart';
import 'package:dms_app/providers/events_provider.dart';
import 'package:dms_app/widgets/glucose_chart.dart';
import 'package:dms_app/widgets/glucose_statistics_card.dart';
import 'package:dms_app/widgets/period_analysis_card.dart';
import 'package:dms_app/widgets/daily_pattern_card.dart';
import 'package:dms_app/widgets/analysis_demo_dialog.dart';
import 'package:dms_app/widgets/glucose_trends_card.dart';
import 'package:dms_app/core/theme/app_theme.dart';
import 'package:dms_app/core/constants/app_constants.dart';
import 'package:dms_app/models/glucose_reading.dart';
import 'package:dms_app/services/dexcom_service.dart';
import 'package:dms_app/features/patient/screens/patient_connections_screen.dart';

/// Patient Dashboard Screen
/// Main screen for patients to view glucose data
/// 
/// Matches the design from the reference images with:
/// - Alert status at top
/// - "Start new sensor" button
/// - Time range selector (3, 6, 12, 24 hours)
/// - Glucose chart with threshold lines
/// - Bottom navigation
class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  int _selectedTimeRange = 24;
  int _currentNavIndex = 0;
  
  // History tab state
  DexcomHistoryResult? _historyResult;
  bool _isLoadingHistory = false;
  int _selectedHistoryHours = 24;
  String _selectedHistoryView = 'list';

  @override
  void initState() {
    super.initState();
    // Load data after the first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final glucoseProvider = context.read<GlucoseProvider>();
    final eventsProvider = context.read<EventsProvider>();
    final patientId = authProvider.currentUser?.id ?? 'demo';
    final userEmail = authProvider.currentUser?.email ?? '';

    debugPrint('Loading data for user: $userEmail, patientId: $patientId');

    // Check if this is the mock account first
    if (userEmail == 'mocked@test.pl') {
      debugPrint('Loading mock data from Firestore...');
      // Load mock data from Firestore directly
      await glucoseProvider.loadGlucoseReadingsFromFirestore(patientId);
      await eventsProvider.loadEvents(patientId, isMockAccount: true);
      debugPrint('Mock data loaded. Readings: ${glucoseProvider.readings.length}');
      return;
    }

    // Check if the user has Dexcom credentials stored
    final hasDexcomCredentials = await glucoseProvider.hasDexcomCredentials();

    if (hasDexcomCredentials) {
      // User has Dexcom configured — always use Dexcom data path
      debugPrint('Dexcom credentials found, initializing Dexcom...');
      await glucoseProvider.initializeDexcom(patientId);

      if (glucoseProvider.sensorConnected) {
        debugPrint('Dexcom connected. Readings: ${glucoseProvider.readings.length}');
      } else {
        // Dexcom is configured but failed to connect — do NOT fall back to mock data
        debugPrint('Dexcom configured but not connected. Error: ${glucoseProvider.error}');
      }
      await eventsProvider.loadEvents(patientId);
    } else {
      // No Dexcom credentials — use local mock data for demo purposes
      debugPrint('No Dexcom credentials, loading local mock data...');
      await glucoseProvider.initializeMockData(patientId);
      await eventsProvider.loadEvents(patientId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: _buildBody(),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // AI Assistant FAB
          FloatingActionButton.small(
            heroTag: 'ai_assistant',
            onPressed: () => context.push('/patient/ai-assistant'),
            backgroundColor: Colors.purple,
            child: const Icon(Icons.smart_toy, color: Colors.white),
          ),
          const SizedBox(height: 8),
          // Add Event FAB
          FloatingActionButton(
            heroTag: 'add_event',
            onPressed: () => context.push('/patient/add-event'),
            child: const Icon(Icons.add),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    switch (_currentNavIndex) {
      case 0:
        return _buildGlucoseTab();
      case 1:
        return _buildHistoryPlaceholder();
      case 2:
        return _buildConnectionsPlaceholder();
      case 3:
        return _buildProfilePlaceholder();
      default:
        return _buildGlucoseTab();
    }
  }

  Widget _buildGlucoseTab() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Header with profile
            _buildHeader(),

            // Alert Status Card
            _buildAlertCard(),

            // Sensor Button
            _buildSensorButton(),

            // Current Glucose Display
            _buildCurrentGlucoseCard(),

            // Glucose Chart Card
            _buildChartCard(),

            // Glucose Trends Card - New!
            _buildTrendsCard(),

            // Enhanced Statistics Card
            _buildEnhancedStatistics(),

            // Period Analysis Card
            _buildPeriodAnalysis(),

            // Daily Pattern Card
            _buildDailyPattern(),

            // Clarity Section (placeholder)
            _buildClarityCard(),

            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    final authProvider = context.read<AuthProvider>();
    final glucoseProvider = context.read<GlucoseProvider>();
    final patientId = authProvider.currentUser?.id ?? 'demo';
    final userEmail = authProvider.currentUser?.email ?? '';

    // Mock account always refreshes from Firestore
    if (userEmail == 'mocked@test.pl') {
      await glucoseProvider.loadGlucoseReadingsFromFirestore(patientId);
      return;
    }

    if (glucoseProvider.sensorConnected) {
      // Refresh current reading from Dexcom
      await glucoseProvider.refreshCurrentReading(patientId);
      // Reload glucose readings
      await glucoseProvider.loadGlucoseReadings(patientId, hours: 24);
    } else {
      // Check if Dexcom is configured before deciding what to do
      final hasDexcomCredentials = await glucoseProvider.hasDexcomCredentials();
      if (hasDexcomCredentials) {
        // Try to reconnect Dexcom only — do NOT fall back to mock data
        debugPrint('Refreshing: attempting Dexcom reconnection...');
        await glucoseProvider.initializeDexcom(patientId);
      } else {
        // No Dexcom configured, reload mock data
        _loadData();
      }
    }
  }

  Widget _buildHeader() {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Welcome Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        final email = auth.currentUser?.email ?? 'user@example.com';
                        final name = email.split('@').first;
                        return Text(
                          name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  // Theme Toggle Button
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        settings.themeMode == ThemeMode.dark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        color: AppTheme.primaryColor,
                        size: 22,
                      ),
                      onPressed: () {
                        final nextTheme = settings.themeMode == ThemeMode.light
                            ? ThemeMode.dark
                            : settings.themeMode == ThemeMode.dark
                                ? ThemeMode.system
                                : ThemeMode.light;
                        settings.setThemeMode(nextTheme);
                      },
                      tooltip: 'Toggle theme',
                    ),
                  ),
                  // Profile Avatar
                  GestureDetector(
                    onTap: () => setState(() => _currentNavIndex = 3),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withValues(alpha: 0.7),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.transparent,
                        child: Icon(Icons.person_rounded, color: Colors.white, size: 26),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlertCard() {
    return Consumer<GlucoseProvider>(
      builder: (context, glucose, child) {
        final hasAlerts = glucose.currentReading != null &&
            (glucose.currentReading!.value < AppConstants.glucoseLowThreshold ||
             glucose.currentReading!.value > AppConstants.glucoseVeryHighThreshold);

        final alertColor = hasAlerts ? AppTheme.errorColor : AppTheme.glucoseNormal;
        final icon = hasAlerts ? Icons.warning_rounded : Icons.check_circle_rounded;
        final title = hasAlerts ? 'Alert' : 'All Good';
        final subtitle = hasAlerts
            ? 'Glucose level requires attention'
            : 'Your glucose is in target range';

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                alertColor.withValues(alpha: 0.1),
                alertColor.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: alertColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: alertColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: alertColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: alertColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSensorButton() {
    return Consumer<GlucoseProvider>(
      builder: (context, glucose, child) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: glucose.sensorConnected
                        ? [AppTheme.secondaryColor, AppTheme.secondaryColor.withValues(alpha: 0.8)]
                        : [Colors.grey.shade600, Colors.grey.shade700],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (glucose.sensorConnected ? AppTheme.secondaryColor : Colors.grey)
                          .withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await context.push('/settings/dexcom');
                    if (mounted) _loadData();
                  },
                  icon: Icon(
                    glucose.sensorConnected ? Icons.sensors_rounded : Icons.sensor_occupied_rounded,
                    size: 22,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  label: Text(
                    glucose.sensorConnected ? 'Sensor connected' : 'Connect sensor',
                    style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const AnalysisDemoDialog(),
                  );
                },
                icon: const Icon(Icons.analytics_rounded, size: 20),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.5), width: 1.5),
                ),
                label: const Text(
                  'View Analysis Demo',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentGlucoseCard() {
    return Consumer<GlucoseProvider>(
      builder: (context, glucose, child) {
        if (glucose.currentReading == null && !glucose.sensorConnected) {
          return const SizedBox.shrink();
        }

        final reading = glucose.currentReading;
        final isLoading = glucose.isLoading;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withValues(alpha: 0.85),
                AppTheme.tertiaryColor,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current glucose level',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (isLoading)
                        const CircularProgressIndicator(color: Colors.white)
                      else if (reading != null)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              reading.value.toInt().toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 56,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                'mg/dL',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        const Text(
                          '--',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  if (reading != null && reading.trend != null)
                    _buildTrendIndicator(reading.trend!),
                ],
              ),
              if (reading != null) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getTimeAgo(reading.timestamp),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                    ),
                    if (glucose.sensorConnected)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.circle,
                              size: 8,
                              color: Colors.greenAccent,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Live',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrendIndicator(String trend) {
    IconData icon;
    Color color = Colors.white;

    switch (trend) {
      case 'rising_fast':
        icon = Icons.arrow_upward;
        break;
      case 'rising':
        icon = Icons.trending_up;
        break;
      case 'stable':
        icon = Icons.trending_flat;
        break;
      case 'falling':
        icon = Icons.trending_down;
        break;
      case 'falling_fast':
        icon = Icons.arrow_downward;
        break;
      default:
        icon = Icons.remove;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 40,
        color: color,
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else {
      return '${difference.inHours} hrs ago';
    }
  }

  Widget _buildChartCard() {
    return Consumer<GlucoseProvider>(
      builder: (context, glucose, child) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Time Range Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: AppConstants.chartTimeRanges.map((hours) {
                      final isSelected = _selectedTimeRange == hours;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTimeRange = hours;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              border: isSelected
                                  ? null
                                  : Border.all(
                                      color: AppTheme.dividerColor,
                                      width: 1,
                                    ),
                            ),
                            child: Text(
                              hours == 24 ? '24h' : '${hours}h',
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      // TODO: [PLACEHOLDER] Show chart options menu
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Chart
              SizedBox(
                height: 250,
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

  Widget _buildTrendsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Consumer<GlucoseProvider>(
        builder: (context, glucose, child) {
          final readings = glucose.getReadingsForTimeRange(_selectedTimeRange);
          if (readings.isEmpty) return const SizedBox.shrink();
          
          return GlucoseTrendsCard(
            readings: readings,
            timeRange: '${_selectedTimeRange}h',
          );
        },
      ),
    );
  }

  Widget _buildEnhancedStatistics() {
    return Consumer<GlucoseProvider>(
      builder: (context, glucose, child) {
        final readings = glucose.getReadingsForTimeRange(_selectedTimeRange);
        if (readings.isEmpty) return const SizedBox.shrink();

        return GlucoseStatisticsCard(
          readings: readings,
          timeRangeLabel: _selectedTimeRange == 24 ? '24 hrs' : '$_selectedTimeRange hrs',
        );
      },
    );
  }

  Widget _buildPeriodAnalysis() {
    return Consumer<GlucoseProvider>(
      builder: (context, glucose, child) {
        final readings = glucose.getReadingsForTimeRange(_selectedTimeRange);
        if (readings.isEmpty) return const SizedBox.shrink();

        return PeriodAnalysisCard(
          readings: readings,
          timeRangeLabel: _selectedTimeRange == 24 ? '24 hrs' : '$_selectedTimeRange hrs',
        );
      },
    );
  }

  Widget _buildDailyPattern() {
    return Consumer<GlucoseProvider>(
      builder: (context, glucose, child) {
        final readings = glucose.getReadingsForTimeRange(_selectedTimeRange);
        if (readings.isEmpty) return const SizedBox.shrink();

        return DailyPatternCard(
          readings: readings,
          timeRangeLabel: _selectedTimeRange == 24 ? '24 hrs' : '$_selectedTimeRange hrs',
        );
      },
    );
  }

  Widget _buildClarityCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.secondaryColor.withValues(alpha: 0.2),
                  AppTheme.secondaryColor.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.bar_chart_rounded,
              color: AppTheme.secondaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Clarity Reports',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'View detailed insights',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_forward_rounded,
                color: AppTheme.primaryColor,
              ),
              onPressed: () {
                // TODO: [PLACEHOLDER] Show Clarity info
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryPlaceholder() {
    return _HistoryTabContent(
      historyResult: _historyResult,
      isLoading: _isLoadingHistory,
      selectedHours: _selectedHistoryHours,
      selectedView: _selectedHistoryView,
      onLoadHistory: _loadHistory,
      onHoursChanged: (hours) {
        setState(() {
          _selectedHistoryHours = hours;
        });
        _loadHistory();
      },
      onViewChanged: () {
        setState(() {
          _selectedHistoryView = _selectedHistoryView == 'list' ? 'chart' : 'list';
        });
      },
    );
  }

  Future<void> _loadHistory() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final glucoseProvider = Provider.of<GlucoseProvider>(context, listen: false);
    final patientId = authProvider.currentUser?.id ?? '';

    if (patientId.isEmpty) return;

    setState(() {
      _isLoadingHistory = true;
    });

    final result = await glucoseProvider.fetchHistoryWithStatus(
      patientId,
      hours: _selectedHistoryHours,
    );

    if (mounted) {
      setState(() {
        _historyResult = result;
        _isLoadingHistory = false;
      });
    }
  }

  Widget _buildConnectionsPlaceholder() {
    return const PatientConnectionsScreen();
  }

  Widget _buildProfilePlaceholder() {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor.withValues(alpha: 0.1),
                      AppTheme.secondaryColor.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withValues(alpha: 0.7),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.transparent,
                        child: Icon(Icons.person_rounded, color: Colors.white, size: 36),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          final email = auth.currentUser?.email ?? 'user@example.com';
                          final name = email.split('@').first;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // App Settings Section
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  'App Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              _buildSettingsItem(
                icon: Icons.palette_outlined,
                title: 'Theme',
                subtitle: _getThemeModeName(settings.themeMode),
                onTap: () => _showThemeDialog(context, settings),
              ),
              _buildSettingsItem(
                icon: Icons.notifications_outlined,
                title: 'Alerts',
                onTap: () => context.push('/settings/alerts'),
              ),
              _buildSettingsItem(
                icon: Icons.event_note_outlined,
                title: 'Events',
                onTap: () {},
              ),
              _buildSettingsItem(
                icon: Icons.radio_button_checked,
                title: 'Glucose Tab',
                onTap: () {},
              ),
              _buildSettingsToggle(
                icon: Icons.preview_outlined,
                title: 'Quick Preview',
                subtitle: 'Quickly check G7 info in the notification menu',
                value: true,
                onChanged: (v) {},
              ),
              
              const SizedBox(height: 24),
              
              // Phone Settings Section
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  'Phone Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              _buildSettingsItem(
                icon: Icons.phone_android,
                title: 'G7 app security on Android devices',
                subtitle: 'Avoid phone settings that prevent alerts and app from working.',
                onTap: () {},
              ),
              
              const SizedBox(height: 24),
              
              // Logout Button
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.errorColor,
                      AppTheme.errorColor.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.errorColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await context.read<AuthProvider>().logout();
                    if (mounted) {
                      context.go('/login');
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  void _showThemeDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Light'),
              leading: Radio<ThemeMode>(
                value: ThemeMode.light,
                groupValue: settings.themeMode,
                onChanged: (value) {
                  if (value != null) settings.setThemeMode(value);
                  Navigator.pop(dialogContext);
                },
              ),
            ),
            ListTile(
              title: const Text('Dark'),
              leading: Radio<ThemeMode>(
                value: ThemeMode.dark,
                groupValue: settings.themeMode,
                onChanged: (value) {
                  if (value != null) settings.setThemeMode(value);
                  Navigator.pop(dialogContext);
                },
              ),
            ),
            ListTile(
              title: const Text('System'),
              leading: Radio<ThemeMode>(
                value: ThemeMode.system,
                groupValue: settings.themeMode,
                onChanged: (value) {
                  if (value != null) settings.setThemeMode(value);
                  Navigator.pop(dialogContext);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.dividerColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: subtitle != null
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              )
            : null,
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: AppTheme.textSecondary,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSettingsToggle({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value
              ? AppTheme.secondaryColor.withValues(alpha: 0.3)
              : AppTheme.dividerColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: value
                ? AppTheme.secondaryColor.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: value
                ? AppTheme.secondaryColor.withValues(alpha: 0.15)
                : AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: value ? AppTheme.secondaryColor : AppTheme.primaryColor,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: subtitle != null
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              )
            : null,
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.secondaryColor,
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentNavIndex,
      onTap: (index) {
        setState(() {
          _currentNavIndex = index;
        });
        // Load history data when switching to history tab
        if (index == 1 && _historyResult == null) {
          _loadHistory();
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.radio_button_checked),
          label: 'Glucose',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.article_outlined),
          label: 'History',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.share_outlined),
          label: 'Connections',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }
}

/// History Tab Content Widget
class _HistoryTabContent extends StatelessWidget {
  final DexcomHistoryResult? historyResult;
  final bool isLoading;
  final int selectedHours;
  final String selectedView;
  final VoidCallback onLoadHistory;
  final ValueChanged<int> onHoursChanged;
  final VoidCallback onViewChanged;

  const _HistoryTabContent({
    required this.historyResult,
    required this.isLoading,
    required this.selectedHours,
    required this.selectedView,
    required this.onLoadHistory,
    required this.onHoursChanged,
    required this.onViewChanged,
  });

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
    return Column(
      children: [
        // Header with actions
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Measurement History',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(selectedView == 'list' ? Icons.show_chart : Icons.list),
                onPressed: onViewChanged,
                tooltip: selectedView == 'list' ? 'Show chart' : 'Show list',
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: isLoading ? null : onLoadHistory,
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        
        // Sensor Status Card
        _buildSensorStatusCard(),
        
        // Time Range Selector
        _buildTimeRangeSelector(),
        
        const SizedBox(height: 8),
        
        // Content
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(context),
        ),
      ],
    );
  }

  Widget _buildSensorStatusCard() {
    if (historyResult == null) return const SizedBox.shrink();

    final isActive = historyResult!.sensorActive;
    final statusColor = isActive ? AppTheme.glucoseNormal : AppTheme.warningColor;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: statusColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isActive ? Icons.sensors : Icons.sensors_off,
                  color: statusColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isActive ? 'Sensor active' : 'Sensor inactive',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      Text(
                        historyResult!.message,
                        style: TextStyle(
                          color: statusColor.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (historyResult!.hasData)
                  Column(
                    children: [
                      Text(
                        '${historyResult!.readings.length}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      Text(
                        'readings',
                        style: TextStyle(
                          fontSize: 10,
                          color: statusColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            // API limitation info
            const Divider(height: 16),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Dexcom Share API only provides data from the last 24 hours.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    final isSelected = selectedHours == hours;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected && !isLoading) {
            onHoursChanged(hours);
          }
        },
        selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (historyResult == null || !historyResult!.hasData) {
      return _buildEmptyState(context);
    }

    if (selectedView == 'chart') {
      return _buildChartView();
    } else {
      return _buildListView();
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.sensors_off,
              size: 64,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'No data to display',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Connect your Dexcom account in settings to see measurement history',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
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
    final readings = historyResult!.readings;

    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: 300,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GlucoseChart(
                readings: readings,
                hoursRange: selectedHours,
              ),
            ),
          ),
          _buildStatisticsCard(readings),
          GlucoseStatisticsCard(
            readings: readings,
            timeRangeLabel: selectedHours == 24 ? '24 hrs' : '$selectedHours hrs',
          ),
          PeriodAnalysisCard(
            readings: readings,
            timeRangeLabel: selectedHours == 24 ? '24 hrs' : '$selectedHours hrs',
          ),
          DailyPatternCard(
            readings: readings,
            timeRangeLabel: selectedHours == 24 ? '24 hrs' : '$selectedHours hrs',
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

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Average', avg.toStringAsFixed(0), _getGlucoseColor(avg)),
            _buildStatItem('Min', min.toStringAsFixed(0), _getGlucoseColor(min)),
            _buildStatItem('Max', max.toStringAsFixed(0), _getGlucoseColor(max)),
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
    final readings = historyResult!.readings;
    
    // Group readings by date
    final groupedReadings = <String, List<GlucoseReading>>{};
    for (final reading in readings) {
      final dateKey = DateFormat('dd.MM.yyyy').format(reading.timestamp);
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
                  fontSize: 14,
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
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              reading.value.toStringAsFixed(0),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              '${reading.value.toStringAsFixed(0)} mg/dL',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(width: 8),
            Icon(
              _getTrendIcon(reading.trend),
              size: 18,
              color: color,
            ),
          ],
        ),
        subtitle: Text(
          DateFormat('HH:mm').format(reading.timestamp),
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        trailing: Text(
          _formatTimestamp(reading.timestamp),
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
