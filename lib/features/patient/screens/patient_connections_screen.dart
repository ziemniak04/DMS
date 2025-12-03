import 'package:flutter/material.dart';
import 'package:dms_app/core/theme/app_theme.dart';

/// Patient Connections Screen
/// 
/// TODO: [PLACEHOLDER] Implement doctor connection/invitation
/// TODO: [PLACEHOLDER] Add QR code sharing
/// TODO: [PLACEHOLDER] Implement data sharing permissions
class PatientConnectionsScreen extends StatelessWidget {
  const PatientConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Połączenia'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.share, size: 64, color: AppTheme.textSecondary),
            SizedBox(height: 16),
            Text(
              'Połączenia z lekarzami',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'TODO: [PLACEHOLDER] Tutaj będzie można połączyć się z lekarzem i udostępniać dane',
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
