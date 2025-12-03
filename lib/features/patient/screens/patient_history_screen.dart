import 'package:flutter/material.dart';
import 'package:dms_app/core/theme/app_theme.dart';

/// Patient History Screen
/// 
/// TODO: [PLACEHOLDER] Implement daily/weekly/monthly history views
/// TODO: [PLACEHOLDER] Add export functionality
/// TODO: [PLACEHOLDER] Add filtering by event type
class PatientHistoryScreen extends StatelessWidget {
  const PatientHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historia'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: AppTheme.textSecondary),
            SizedBox(height: 16),
            Text(
              'Historia zdarzeń',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'TODO: [PLACEHOLDER] Tutaj będzie wyświetlana historia pomiarów glukozy i zdarzeń',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
