import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dms_app/core/theme/app_theme.dart';
import 'package:dms_app/providers/settings_provider.dart';

/// Settings Screen
/// 
/// Manage app-wide settings including theme, glucose units, and alerts
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            children: [
              // Display Section
              _buildSectionHeader('Display'),
              ListTile(
                title: const Text('Theme'),
                subtitle: Text(_getThemeModeName(settings.themeMode)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemeDialog(context, settings),
              ),
              ListTile(
                title: const Text('Glucose Unit'),
                subtitle: Text(settings.glucoseUnit),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showGlucoseUnitDialog(context, settings),
              ),
              
              // Notifications Section
              _buildSectionHeader('Notifications'),
              SwitchListTile(
                title: const Text('Alert Sound'),
                subtitle: const Text('Play sound for alerts'),
                value: settings.alertSoundEnabled,
                onChanged: (value) => settings.setAlertSoundEnabled(value),
              ),
              SwitchListTile(
                title: const Text('Alert Vibration'),
                subtitle: const Text('Vibrate for alerts'),
                value: settings.alertVibrationEnabled,
                onChanged: (value) => settings.setAlertVibrationEnabled(value),
              ),
              ListTile(
                title: const Text('Alert Settings'),
                subtitle: const Text('Glucose thresholds and timing'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/alerts'),
              ),
              
              // Data Section
              _buildSectionHeader('Data'),
              ListTile(
                title: const Text('Dexcom Connection'),
                subtitle: const Text('Connect Dexcom CGM sensor'),
                trailing: const Icon(Icons.sensors),
                onTap: () => context.push('/settings/dexcom'),
              ),
              ListTile(
                title: const Text('Export Data'),
                subtitle: const Text('Download data in CSV format'),
                trailing: const Icon(Icons.download),
                onTap: () {
                  // TODO: [PLACEHOLDER] Implement data export
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Data export - to be implemented'),
                    ),
                  );
                },
              ),
              ListTile(
                title: const Text('Sync'),
                subtitle: const Text('Last: never'),
                trailing: const Icon(Icons.sync),
                onTap: () {
                  // TODO: [PLACEHOLDER] Implement data sync
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sync - to be implemented'),
                    ),
                  );
                },
              ),
              
              // About Section
              _buildSectionHeader('About'),
              ListTile(
                title: const Text('App Version'),
                subtitle: const Text('1.0.0 (demo)'),
              ),
              ListTile(
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () {
                  // TODO: [PLACEHOLDER] Open privacy policy
                },
              ),
              ListTile(
                title: const Text('Terms of Service'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () {
                  // TODO: [PLACEHOLDER] Open terms of service
                },
              ),
              ListTile(
                title: const Text('Open Source Licenses'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showLicensePage(context: context);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
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

  void _showGlucoseUnitDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Glucose Unit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('mg/dL'),
              leading: Radio<String>(
                value: 'mg/dL',
                groupValue: settings.glucoseUnit,
                onChanged: (value) {
                  if (value != null) settings.setGlucoseUnit(value);
                  Navigator.pop(dialogContext);
                },
              ),
            ),
            ListTile(
              title: const Text('mmol/L'),
              leading: Radio<String>(
                value: 'mmol/L',
                groupValue: settings.glucoseUnit,
                onChanged: (value) {
                  if (value != null) settings.setGlucoseUnit(value);
                  Navigator.pop(dialogContext);
                  // TODO: [PLACEHOLDER] Convert all glucose values
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Unit conversion - to be implemented'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
