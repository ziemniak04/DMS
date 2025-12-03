import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dms_app/providers/glucose_provider.dart';
import 'package:dms_app/providers/auth_provider.dart';
import 'package:dms_app/widgets/glucose_chart.dart';
import 'package:dms_app/core/theme/app_theme.dart';
import 'package:dms_app/core/constants/app_constants.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final authProvider = context.read<AuthProvider>();
    final glucoseProvider = context.read<GlucoseProvider>();
    glucoseProvider.initializeMockData(authProvider.currentUser?.id ?? 'demo');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/patient/add-event'),
        child: const Icon(Icons.add),
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
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header with profile
          _buildHeader(),
          
          // Alert Status Card
          _buildAlertCard(),
          
          // Sensor Button
          _buildSensorButton(),
          
          // Glucose Chart Card
          _buildChartCard(),
          
          // Clarity Section (placeholder)
          _buildClarityCard(),
          
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Profile Avatar
          GestureDetector(
            onTap: () => setState(() => _currentNavIndex = 3),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
              child: const Icon(Icons.person, color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard() {
    return Consumer<GlucoseProvider>(
      builder: (context, glucose, child) {
        final hasAlerts = glucose.currentReading != null &&
            (glucose.currentReading!.value < AppConstants.glucoseLowThreshold ||
             glucose.currentReading!.value > AppConstants.glucoseVeryHighThreshold);
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(
                hasAlerts ? Icons.warning_amber : Icons.warning_amber,
                size: 40,
                color: hasAlerts ? AppTheme.errorColor : AppTheme.errorColor,
              ),
              const SizedBox(height: 8),
              Text(
                hasAlerts ? 'Ostrzeżenie!' : 'Brak ostrzeżeń',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
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
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () async {
              // TODO: [PLACEHOLDER] Implement sensor connection flow
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Łączenie z sensorem - do zaimplementowania'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3C4043),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              glucose.sensorConnected ? 'Sensor połączony' : 'Uruchom nowy sensor',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChartCard() {
    return Consumer<GlucoseProvider>(
      builder: (context, glucose, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? Colors.grey.shade200 
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              hours == 24 ? '24 godz.' : '$hours',
                              style: TextStyle(
                                fontWeight: isSelected 
                                    ? FontWeight.bold 
                                    : FontWeight.normal,
                                color: AppTheme.textPrimary,
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

  Widget _buildClarityCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.bar_chart,
              color: AppTheme.secondaryColor,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Clarity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // TODO: [PLACEHOLDER] Show Clarity info
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryPlaceholder() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: AppTheme.textSecondary),
          SizedBox(height: 16),
          Text(
            'Historia',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'TODO: [PLACEHOLDER] Implement history view',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionsPlaceholder() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.share, size: 64, color: AppTheme.textSecondary),
          SizedBox(height: 16),
          Text(
            'Połączenia',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'TODO: [PLACEHOLDER] Implement connections/sharing',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePlaceholder() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profil',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          // App Settings Section
          const Text(
            'Ustawienia aplikacji',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          _buildSettingsItem(
            icon: Icons.notifications_outlined,
            title: 'Ostrzeżenia',
            onTap: () => context.push('/settings/alerts'),
          ),
          _buildSettingsItem(
            icon: Icons.event_note_outlined,
            title: 'Zdarzenia',
            onTap: () {},
          ),
          _buildSettingsItem(
            icon: Icons.radio_button_checked,
            title: 'Zakładka Glukoza',
            onTap: () {},
          ),
          _buildSettingsToggle(
            icon: Icons.preview_outlined,
            title: 'Szybki podgląd',
            subtitle: 'Szybko sprawdzaj informacje G7 w menu powiadomień',
            value: true,
            onChanged: (v) {},
          ),
          
          const SizedBox(height: 24),
          
          // Phone Settings Section
          const Text(
            'Ustawienia telefonu',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          _buildSettingsItem(
            icon: Icons.phone_android,
            title: 'Bezpieczeństwo aplikacji G7 na urządzeniach z systemem Android',
            subtitle: 'Unikaj ustawień telefonu, które uniemożliwiają działanie ostrzeżeń i aplikacji.',
            onTap: () {},
          ),
          
          const SizedBox(height: 24),
          
          // Logout Button
          ElevatedButton.icon(
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (mounted) {
                context.go('/login');
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Wyloguj się'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textSecondary),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildSettingsToggle({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textSecondary),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppTheme.secondaryColor,
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
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.radio_button_checked),
          label: 'Glukoza',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.article_outlined),
          label: 'Historia',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.share_outlined),
          label: 'Połączenia',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profil',
        ),
      ],
    );
  }
}
