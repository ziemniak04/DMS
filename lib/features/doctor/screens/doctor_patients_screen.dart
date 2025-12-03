import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dms_app/core/theme/app_theme.dart';

/// Doctor Patients Screen
/// Full list of doctor's patients
/// 
/// TODO: [PLACEHOLDER] Load real patient data from Firebase
/// TODO: [PLACEHOLDER] Add search and filter functionality
/// TODO: [PLACEHOLDER] Add sorting options
class DoctorPatientsScreen extends StatelessWidget {
  const DoctorPatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moi pacjenci'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: [PLACEHOLDER] Implement search
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: [PLACEHOLDER] Implement filters
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
              title: Text('Pacjent $index'),
              subtitle: const Text('Ostatni pomiar: 120 mg/dL'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/doctor/patient/patient_$index'),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: [PLACEHOLDER] Implement patient invitation
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Zaproszenie pacjenta - do zaimplementowania'),
            ),
          );
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Zaproś pacjenta'),
      ),
    );
  }
}
