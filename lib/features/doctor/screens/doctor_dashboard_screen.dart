import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dms_app/providers/auth_provider.dart';
import 'package:dms_app/core/theme/app_theme.dart';

/// Doctor Dashboard Screen
/// Main screen for doctors to view and manage their patients
/// 
/// TODO: [PLACEHOLDER] Implement real patient data loading from Firebase
/// TODO: [PLACEHOLDER] Add patient search functionality
/// TODO: [PLACEHOLDER] Add patient invitation system
class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: _buildBody(),
      ),
      floatingActionButton: _currentNavIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                // TODO: [PLACEHOLDER] Add new patient invitation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Zaproszenie pacjenta - do zaimplementowania'),
                  ),
                );
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Dodaj pacjenta'),
            )
          : null,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    switch (_currentNavIndex) {
      case 0:
        return _buildPatientsTab();
      case 1:
        return _buildAlertsTab();
      case 2:
        return _buildProfileTab();
      default:
        return _buildPatientsTab();
    }
  }

  Widget _buildPatientsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Consumer<AuthProvider>(
                    builder: (context, auth, child) {
                      return Text(
                        'Witaj, ${auth.currentUser?.name ?? "Doktor"}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  Text(
                    'Twoi pacjenci',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  // TODO: [PLACEHOLDER] Implement patient search
                },
              ),
            ],
          ),
        ),
        
        // Stats Cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Pacjenci',
                  value: '12',
                  icon: Icons.people,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  title: 'Ostrzeżenia',
                  value: '3',
                  icon: Icons.warning_amber,
                  color: AppTheme.errorColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Patients List
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Lista pacjentów',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _mockPatients.length,
            itemBuilder: (context, index) {
              final patient = _mockPatients[index];
              return _PatientCard(
                patient: patient,
                onTap: () => context.push('/doctor/patient/${patient['id']}'),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Ostrzeżenia',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _AlertCard(
                patientName: 'Anna Nowak',
                message: 'Niski poziom glukozy: 58 mg/dL',
                time: '5 min temu',
                severity: AlertSeverity.high,
              ),
              _AlertCard(
                patientName: 'Jan Kowalski',
                message: 'Wysoki poziom glukozy: 285 mg/dL',
                time: '15 min temu',
                severity: AlertSeverity.medium,
              ),
              _AlertCard(
                patientName: 'Maria Wiśniewska',
                message: 'Brak danych z sensora od 2 godzin',
                time: '2 godz. temu',
                severity: AlertSeverity.low,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profil',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Profile Card
          Consumer<AuthProvider>(
            builder: (context, auth, child) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                        child: const Icon(
                          Icons.person,
                          size: 40,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.currentUser?.name ?? 'Lekarz',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              auth.currentUser?.email ?? '',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Lekarz',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          
          // Settings
          _buildMenuItem(
            icon: Icons.settings_outlined,
            title: 'Ustawienia',
            onTap: () => context.push('/settings'),
          ),
          _buildMenuItem(
            icon: Icons.notifications_outlined,
            title: 'Powiadomienia',
            onTap: () => context.push('/settings/alerts'),
          ),
          _buildMenuItem(
            icon: Icons.help_outline,
            title: 'Pomoc',
            onTap: () {},
          ),
          
          const SizedBox(height: 24),
          
          // Logout
          ElevatedButton.icon(
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
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

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
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
          icon: Icon(Icons.people_outline),
          label: 'Pacjenci',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.warning_amber_outlined),
          label: 'Ostrzeżenia',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profil',
        ),
      ],
    );
  }

  // Mock data for patients
  final List<Map<String, dynamic>> _mockPatients = [
    {
      'id': 'patient_1',
      'name': 'Anna Nowak',
      'lastReading': 125,
      'status': 'normal',
      'lastUpdate': '5 min temu',
    },
    {
      'id': 'patient_2',
      'name': 'Jan Kowalski',
      'lastReading': 285,
      'status': 'high',
      'lastUpdate': '10 min temu',
    },
    {
      'id': 'patient_3',
      'name': 'Maria Wiśniewska',
      'lastReading': 98,
      'status': 'normal',
      'lastUpdate': '15 min temu',
    },
    {
      'id': 'patient_4',
      'name': 'Piotr Zieliński',
      'lastReading': 58,
      'status': 'low',
      'lastUpdate': '20 min temu',
    },
  ];
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final Map<String, dynamic> patient;
  final VoidCallback onTap;

  const _PatientCard({
    required this.patient,
    required this.onTap,
  });

  Color _getStatusColor() {
    switch (patient['status']) {
      case 'low':
        return AppTheme.glucoseLow;
      case 'high':
        return AppTheme.glucoseHigh;
      default:
        return AppTheme.glucoseNormal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor().withValues(alpha: 0.2),
          child: Text(
            patient['name'].toString().substring(0, 1),
            style: TextStyle(
              color: _getStatusColor(),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          patient['name'],
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${patient['lastReading']} mg/dL • ${patient['lastUpdate']}',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        trailing: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: _getStatusColor(),
            shape: BoxShape.circle,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

enum AlertSeverity { low, medium, high }

class _AlertCard extends StatelessWidget {
  final String patientName;
  final String message;
  final String time;
  final AlertSeverity severity;

  const _AlertCard({
    required this.patientName,
    required this.message,
    required this.time,
    required this.severity,
  });

  Color _getSeverityColor() {
    switch (severity) {
      case AlertSeverity.high:
        return AppTheme.errorColor;
      case AlertSeverity.medium:
        return AppTheme.warningColor;
      case AlertSeverity.low:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getSeverityColor().withValues(alpha: 0.2),
          child: Icon(
            Icons.warning_amber,
            color: _getSeverityColor(),
          ),
        ),
        title: Text(
          patientName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            Text(
              time,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
