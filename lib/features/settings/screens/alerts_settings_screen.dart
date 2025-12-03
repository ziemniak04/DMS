import 'package:flutter/material.dart';
import 'package:dms_app/core/theme/app_theme.dart';
import 'package:dms_app/core/constants/app_constants.dart';

/// Alerts Settings Screen
/// Configure glucose thresholds and notification preferences
/// 
/// TODO: [PLACEHOLDER] Save settings to SharedPreferences/Firebase
/// TODO: [PLACEHOLDER] Add sound selection
/// TODO: [PLACEHOLDER] Add vibration settings
/// TODO: [PLACEHOLDER] Add repeat alert settings
class AlertsSettingsScreen extends StatefulWidget {
  const AlertsSettingsScreen({super.key});

  @override
  State<AlertsSettingsScreen> createState() => _AlertsSettingsScreenState();
}

class _AlertsSettingsScreenState extends State<AlertsSettingsScreen> {
  double _lowThreshold = AppConstants.glucoseLowThreshold;
  double _highThreshold = AppConstants.glucoseVeryHighThreshold;
  bool _urgentLowEnabled = true;
  bool _lowEnabled = true;
  bool _highEnabled = true;
  bool _signalLossEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ostrzeżenia'),
      ),
      body: ListView(
        children: [
          // Glucose Thresholds Section
          _buildSectionHeader('Progi glukozy'),
          
          // Low Threshold
          ListTile(
            title: const Text('Niski poziom glukozy'),
            subtitle: Text('${_lowThreshold.toInt()} mg/dL'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThresholdDialog(
              title: 'Niski poziom glukozy',
              currentValue: _lowThreshold,
              min: 50,
              max: 100,
              onChanged: (value) {
                setState(() {
                  _lowThreshold = value;
                });
              },
            ),
          ),
          
          // High Threshold
          ListTile(
            title: const Text('Wysoki poziom glukozy'),
            subtitle: Text('${_highThreshold.toInt()} mg/dL'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThresholdDialog(
              title: 'Wysoki poziom glukozy',
              currentValue: _highThreshold,
              min: 180,
              max: 350,
              onChanged: (value) {
                setState(() {
                  _highThreshold = value;
                });
              },
            ),
          ),
          
          const Divider(),
          
          // Alert Types Section
          _buildSectionHeader('Typy ostrzeżeń'),
          
          SwitchListTile(
            title: const Text('Pilne niski poziom'),
            subtitle: Text(
              'Powiadomienie gdy glukoza < ${(_lowThreshold - 15).toInt()} mg/dL',
            ),
            secondary: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning,
                color: AppTheme.errorColor,
              ),
            ),
            value: _urgentLowEnabled,
            onChanged: (value) {
              setState(() {
                _urgentLowEnabled = value;
              });
            },
          ),
          
          SwitchListTile(
            title: const Text('Niski poziom'),
            subtitle: Text(
              'Powiadomienie gdy glukoza < ${_lowThreshold.toInt()} mg/dL',
            ),
            secondary: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.glucoseLow.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_downward,
                color: AppTheme.glucoseLow,
              ),
            ),
            value: _lowEnabled,
            onChanged: (value) {
              setState(() {
                _lowEnabled = value;
              });
            },
          ),
          
          SwitchListTile(
            title: const Text('Wysoki poziom'),
            subtitle: Text(
              'Powiadomienie gdy glukoza > ${_highThreshold.toInt()} mg/dL',
            ),
            secondary: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.glucoseHigh.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_upward,
                color: AppTheme.glucoseHigh,
              ),
            ),
            value: _highEnabled,
            onChanged: (value) {
              setState(() {
                _highEnabled = value;
              });
            },
          ),
          
          SwitchListTile(
            title: const Text('Utrata sygnału'),
            subtitle: const Text('Powiadomienie gdy brak danych z sensora'),
            secondary: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.signal_cellular_off,
                color: AppTheme.textSecondary,
              ),
            ),
            value: _signalLossEnabled,
            onChanged: (value) {
              setState(() {
                _signalLossEnabled = value;
              });
            },
          ),
          
          const Divider(),
          
          // Sound & Vibration Section
          _buildSectionHeader('Dźwięk i wibracja'),
          
          SwitchListTile(
            title: const Text('Dźwięk'),
            subtitle: const Text('Odtwarzaj dźwięk przy ostrzeżeniach'),
            value: _soundEnabled,
            onChanged: (value) {
              setState(() {
                _soundEnabled = value;
              });
            },
          ),
          
          SwitchListTile(
            title: const Text('Wibracja'),
            subtitle: const Text('Wibruj przy ostrzeżeniach'),
            value: _vibrationEnabled,
            onChanged: (value) {
              setState(() {
                _vibrationEnabled = value;
              });
            },
          ),
          
          if (_soundEnabled)
            ListTile(
              title: const Text('Dźwięk ostrzeżenia'),
              subtitle: const Text('Domyślny'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: [PLACEHOLDER] Implement sound picker
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Wybór dźwięku - do zaimplementowania'),
                  ),
                );
              },
            ),
          
          const SizedBox(height: 24),
          
          // Save Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                // TODO: [PLACEHOLDER] Save settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ustawienia zapisane'),
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text('Zapisz ustawienia'),
            ),
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

  void _showThresholdDialog({
    required String title,
    required double currentValue,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    double tempValue = currentValue;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${tempValue.toInt()} mg/dL',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Slider(
                  value: tempValue,
                  min: min,
                  max: max,
                  divisions: ((max - min) / 5).toInt(),
                  onChanged: (value) {
                    setDialogState(() {
                      tempValue = value;
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${min.toInt()}'),
                    Text('${max.toInt()}'),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Anuluj'),
              ),
              ElevatedButton(
                onPressed: () {
                  onChanged(tempValue);
                  Navigator.pop(context);
                },
                child: const Text('Zapisz'),
              ),
            ],
          );
        },
      ),
    );
  }
}
