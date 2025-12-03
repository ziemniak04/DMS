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
        title: const Text('Ustawienia'),
      ),
      body: ListView(
        children: [
          // Display Section
          _buildSectionHeader('Wyświetlanie'),
          SwitchListTile(
            title: const Text('Tryb ciemny'),
            subtitle: const Text('Zmień wygląd aplikacji'),
            value: _darkMode,
            onChanged: (value) {
              setState(() {
                _darkMode = value;
              });
              // TODO: [PLACEHOLDER] Implement dark mode
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tryb ciemny - do zaimplementowania'),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Jednostka glukozy'),
            subtitle: Text(_glucoseUnit),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showGlucoseUnitDialog();
            },
          ),
          
          // Notifications Section
          _buildSectionHeader('Powiadomienia'),
          SwitchListTile(
            title: const Text('Powiadomienia push'),
            subtitle: const Text('Otrzymuj alerty o poziomie glukozy'),
            value: _notifications,
            onChanged: (value) {
              setState(() {
                _notifications = value;
              });
              // TODO: [PLACEHOLDER] Save notification preference
            },
          ),
          ListTile(
            title: const Text('Ustawienia ostrzeżeń'),
            subtitle: const Text('Progi glukozy i dźwięki'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/alerts'),
          ),
          
          // Data Section
          _buildSectionHeader('Dane'),
          ListTile(
            title: const Text('Eksport danych'),
            subtitle: const Text('Pobierz dane w formacie CSV'),
            trailing: const Icon(Icons.download),
            onTap: () {
              // TODO: [PLACEHOLDER] Implement data export
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Eksport danych - do zaimplementowania'),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Synchronizacja'),
            subtitle: const Text('Ostatnia: nigdy'),
            trailing: const Icon(Icons.sync),
            onTap: () {
              // TODO: [PLACEHOLDER] Implement data sync
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Synchronizacja - do zaimplementowania'),
                ),
              );
            },
          ),
          
          // About Section
          _buildSectionHeader('Informacje'),
          ListTile(
            title: const Text('Wersja aplikacji'),
            subtitle: const Text('1.0.0 (demo)'),
          ),
          ListTile(
            title: const Text('Polityka prywatności'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () {
              // TODO: [PLACEHOLDER] Open privacy policy
            },
          ),
          ListTile(
            title: const Text('Regulamin'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () {
              // TODO: [PLACEHOLDER] Open terms of service
            },
          ),
          ListTile(
            title: const Text('Licencje open source'),
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
        title: const Text('Jednostka glukozy'),
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
                          content: Text('Konwersja jednostek - do zaimplementowania'),
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
