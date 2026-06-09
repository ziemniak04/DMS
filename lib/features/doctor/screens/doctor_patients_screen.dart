import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dms_app/core/theme/app_theme.dart';
import 'package:dms_app/services/firestore_service.dart';
import 'package:dms_app/providers/auth_provider.dart';
import 'package:dms_app/models/user.dart';

/// Doctor Patients Screen
/// Full list of doctor's patients with search
class DoctorPatientsScreen extends StatefulWidget {
  const DoctorPatientsScreen({super.key});

  @override
  State<DoctorPatientsScreen> createState() => _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends State<DoctorPatientsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  List<User> _patients = [];
  List<User> _filteredPatients = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

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
    if (doctorId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _patients = await _firestoreService.getPatientsByDoctorId(doctorId);
      _applySearch();
      _isLoading = false;
      setState(() {});
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      setState(() {});
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
                'Enter the email address of the patient you want to add.',
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
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final patient = await _firestoreService.getUserByEmail(email);

      if (!mounted) return;
      Navigator.of(context).pop();

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

      final doctorId = context.read<AuthProvider>().currentUser?.id;
      if (patient.doctorId == doctorId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This patient is already in your list'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
        return;
      }

      await _firestoreService.assignPatientToDoctor(patient.id, doctorId!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${patient.name} has been added to your patients'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
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
      appBar: AppBar(
        title: const Text('My Patients'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
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

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filteredPatients.length} patient${_filteredPatients.length == 1 ? '' : 's'}',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Patient list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
                            const SizedBox(height: 8),
                            Text(_error!, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                            const SizedBox(height: 16),
                            ElevatedButton(onPressed: _loadPatients, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : _filteredPatients.isEmpty
                        ? Center(
                            child: Text(
                              _searchQuery.isNotEmpty
                                  ? 'No patients match "$_searchQuery"'
                                  : 'No patients connected yet',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadPatients,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredPatients.length,
                              itemBuilder: (context, index) {
                                final patient = _filteredPatients[index];
                                final initial = patient.name.isNotEmpty
                                    ? patient.name[0].toUpperCase()
                                    : '?';
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
                                    onTap: () => context.push('/doctor/patient/${patient.id}'),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPatientDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Patient'),
      ),
    );
  }
}
