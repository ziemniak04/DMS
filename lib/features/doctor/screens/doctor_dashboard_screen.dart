import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dms_app/providers/auth_provider.dart';
import 'package:dms_app/core/theme/app_theme.dart';
import 'package:dms_app/services/firestore_service.dart';
import 'package:dms_app/models/user.dart';

/// Doctor Dashboard Screen
/// Main screen for doctors to view and manage their patients
class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  int _currentNavIndex = 0;
  final FirestoreService _firestoreService = FirestoreService();
  
  List<User> _patients = [];
  List<User> _filteredPatients = [];
  bool _isLoadingPatients = true;
  String? _patientsError;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPatients();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    final doctorId = context.read<AuthProvider>().currentUser?.id;
    debugPrint('[DoctorDashboard] _loadPatients called, doctorId: $doctorId');
    if (doctorId == null) {
      debugPrint('[DoctorDashboard] doctorId is null, aborting load');
      return;
    }

    setState(() {
      _isLoadingPatients = true;
      _patientsError = null;
    });

    try {
      _patients = await _firestoreService.getPatientsByDoctorId(doctorId);
      debugPrint('[DoctorDashboard] Loaded ${_patients.length} patients: ${_patients.map((p) => '${p.name}(${p.id})').join(', ')}');
      _applySearch();
      _isLoadingPatients = false;
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('[DoctorDashboard] Error loading patients: $e');
      _patientsError = e.toString();
      _isLoadingPatients = false;
      if (mounted) setState(() {});
    }
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredPatients = List.from(_patients);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredPatients = _patients.where((p) =>
        p.name.toLowerCase().contains(query) ||
        p.email.toLowerCase().contains(query)
      ).toList();
    }
  }

  Future<void> _showAddPatientDialog() async {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Patient'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter the email address of the patient you want to add to your list.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Patient Email',
                  hintText: 'patient@example.com',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Add Patient'),
          ),
        ],
      ),
    );

    if (result == true && emailController.text.isNotEmpty) {
      await _addPatientByEmail(emailController.text.trim());
    }

    emailController.dispose();
  }

  Future<void> _addPatientByEmail(String email) async {
    bool dialogOpen = false;
    try {
      // Show loading indicator
      dialogOpen = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Find patient by email
      debugPrint('[DoctorDashboard] Searching for patient by email: $email');
      final patient = await _firestoreService.getUserByEmail(email);
      debugPrint('[DoctorDashboard] getUserByEmail result: ${patient?.name} (${patient?.id}), role: ${patient?.role}');

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      dialogOpen = false;

      if (patient == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No patient found with email: $email'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      if (patient.role != 'patient') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This user is not a patient'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      // Check if already assigned
      final doctorId = context.read<AuthProvider>().currentUser?.id;
      debugPrint('[DoctorDashboard] Current doctor ID: $doctorId, patient doctorId: ${patient.doctorId}');
      if (patient.doctorId == doctorId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This patient is already in your list'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
        return;
      }

      // Assign patient to doctor
      debugPrint('[DoctorDashboard] Assigning patient ${patient.id} to doctor $doctorId');
      await _firestoreService.assignPatientToDoctor(patient.id, doctorId!);
      debugPrint('[DoctorDashboard] Assignment successful');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${patient.name.isNotEmpty ? patient.name : patient.email} has been added to your patients'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );

      // Refresh the patient list
      await _loadPatients();
    } catch (e) {
      debugPrint('[DoctorDashboard] Error adding patient: $e');
      if (!mounted) return;
      if (dialogOpen) {
        Navigator.of(context).pop(); // Close loading dialog only if still open
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding patient: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: _buildBody(),
      ),
      floatingActionButton: _currentNavIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _showAddPatientDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('Add Patient'),
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
                        'Welcome, ${auth.currentUser?.name ?? "Doctor"}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  Text(
                    'Your patients',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadPatients,
              ),
            ],
          ),
        ),
        
        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search patients by name or email...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _applySearch();
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applySearch();
              });
            },
          ),
        ),
        const SizedBox(height: 12),

        // Stats Cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Patients',
                  value: '${_patients.length}',
                  icon: Icons.people,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  title: 'Shown',
                  value: '${_filteredPatients.length}',
                  icon: Icons.filter_list,
                  color: AppTheme.secondaryColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Patients List
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Patient List',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        Expanded(
          child: _isLoadingPatients
              ? const Center(child: CircularProgressIndicator())
              : _patientsError != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
                          const SizedBox(height: 8),
                          Text('Error loading patients', style: TextStyle(color: AppTheme.errorColor)),
                          const SizedBox(height: 4),
                          Text(_patientsError!, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: _loadPatients, child: const Text('Retry')),
                        ],
                      ),
                    )
                  : _filteredPatients.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: AppTheme.textSecondary),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No patients match your search'
                                    : 'No patients yet',
                                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                              ),
                              if (_searchQuery.isEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Tap "Add Patient" to connect with a patient',
                                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                ),
                              ],
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadPatients,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredPatients.length,
                            itemBuilder: (context, index) {
                              final patient = _filteredPatients[index];
                              return _PatientCard(
                                patient: patient,
                                onTap: () => context.push('/doctor/patient/${patient.id}'),
                              );
                            },
                          ),
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
            'Alerts',
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
                message: 'Low glucose level: 58 mg/dL',
                time: '5 min ago',
                severity: AlertSeverity.high,
              ),
              _AlertCard(
                patientName: 'Jan Kowalski',
                message: 'High glucose level: 285 mg/dL',
                time: '15 min ago',
                severity: AlertSeverity.medium,
              ),
              _AlertCard(
                patientName: 'Maria Wiśniewska',
                message: 'No sensor data for 2 hours',
                time: '2 hrs ago',
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
            'Profile',
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
                              auth.currentUser?.name ?? 'Doctor',
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
                                'Doctor',
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
            title: 'Settings',
            onTap: () => context.push('/settings'),
          ),
          _buildMenuItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            onTap: () => context.push('/settings/alerts'),
          ),
          _buildMenuItem(
            icon: Icons.help_outline,
            title: 'Help',
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
            label: const Text('Sign Out'),
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
          label: 'Patients',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.warning_amber_outlined),
          label: 'Alerts',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }
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
  final User patient;
  final VoidCallback onTap;

  const _PatientCard({
    required this.patient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial = patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '?';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
          child: Text(
            initial,
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          patient.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          patient.email,
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        trailing: const Icon(Icons.chevron_right),
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
