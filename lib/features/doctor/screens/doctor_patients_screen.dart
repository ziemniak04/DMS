import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dms_app/core/theme/app_theme.dart';
import 'package:dms_app/services/firestore_service.dart';
import 'package:dms_app/providers/auth_provider.dart';

/// Doctor Patients Screen
/// Full list of doctor's patients
class DoctorPatientsScreen extends StatefulWidget {
  const DoctorPatientsScreen({super.key});

  @override
  State<DoctorPatientsScreen> createState() => _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends State<DoctorPatientsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

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
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filters
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 10,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                child: Text(
                  'P$index',
                  style: const TextStyle(color: AppTheme.primaryColor),
                ),
              ),
              title: Text('Patient $index'),
              subtitle: const Text('Last reading: 120 mg/dL'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/doctor/patient/patient_$index'),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPatientDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Patient'),
      ),
    );
  }
}
