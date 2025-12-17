import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dms_app/core/theme/app_theme.dart';

/// Settings Screen
/// 
/// TODO: [PLACEHOLDER] Implement dark mode toggle
/// TODO: [PLACEHOLDER] Add language selection
/// TODO: [PLACEHOLDER] Add glucose unit switching (mg/dL ↔ mmol/L)
/// TODO: [PLACEHOLDER] Save settings to SharedPreferences
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _notifications = true;
  String _glucoseUnit = 'mg/dL';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Display Section
          _buildSectionHeader('Display'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Change app appearance'),
            value: _darkMode,
            onChanged: (value) {
              setState(() {
                _darkMode = value;
              });
              // TODO: [PLACEHOLDER] Implement dark mode
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dark mode - to be implemented'),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Glucose Unit'),
            subtitle: Text(_glucoseUnit),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showGlucoseUnitDialog();
            },
          ),
          
          // Notifications Section
          _buildSectionHeader('Notifications'),
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive glucose level alerts'),
            value: _notifications,
            onChanged: (value) {
              setState(() {
                _notifications = value;
              });
              // TODO: [PLACEHOLDER] Save notification preference
            },
          ),
          ListTile(
            title: const Text('Alert Settings'),
            subtitle: const Text('Glucose thresholds and sounds'),
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

  void _showGlucoseUnitDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Glucose Unit'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('mg/dL'),
                  leading: Radio<String>(
                    value: 'mg/dL',
                    groupValue: _glucoseUnit,
                    onChanged: (value) {
                      setState(() {
                        _glucoseUnit = value!;
                      });
                      setDialogState(() {});
                      Navigator.pop(dialogContext);
                    },
                  ),
                ),
                ListTile(
                  title: const Text('mmol/L'),
                  leading: Radio<String>(
                    value: 'mmol/L',
                    groupValue: _glucoseUnit,
                    onChanged: (value) {
                      setState(() {
                        _glucoseUnit = value!;
                      });
                      setDialogState(() {});
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
            );
          },
        ),
      ),
    );
  }
}
