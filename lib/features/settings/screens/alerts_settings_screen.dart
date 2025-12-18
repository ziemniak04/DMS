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
        title: const Text('Alerts'),
      ),
      body: ListView(
        children: [
          // Glucose Thresholds Section
          _buildSectionHeader('Glucose Thresholds'),
          
          // Low Threshold
          ListTile(
            title: const Text('Low Glucose Level'),
            subtitle: Text('${_lowThreshold.toInt()} mg/dL'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThresholdDialog(
              title: 'Low Glucose Level',
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
            title: const Text('High Glucose Level'),
            subtitle: Text('${_highThreshold.toInt()} mg/dL'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThresholdDialog(
              title: 'High Glucose Level',
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
          _buildSectionHeader('Alert Types'),
          
          SwitchListTile(
            title: const Text('Urgent Low'),
            subtitle: Text(
              'Notification when glucose < ${(_lowThreshold - 15).toInt()} mg/dL',
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
            title: const Text('Low'),
            subtitle: Text(
              'Notification when glucose < ${_lowThreshold.toInt()} mg/dL',
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
            title: const Text('High'),
            subtitle: Text(
              'Notification when glucose > ${_highThreshold.toInt()} mg/dL',
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
            title: const Text('Signal Loss'),
            subtitle: const Text('Notification when no data from sensor'),
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
          _buildSectionHeader('Sound & Vibration'),
          
          SwitchListTile(
            title: const Text('Sound'),
            subtitle: const Text('Play sound for alerts'),
            value: _soundEnabled,
            onChanged: (value) {
              setState(() {
                _soundEnabled = value;
              });
            },
          ),
          
          SwitchListTile(
            title: const Text('Vibration'),
            subtitle: const Text('Vibrate for alerts'),
            value: _vibrationEnabled,
            onChanged: (value) {
              setState(() {
                _vibrationEnabled = value;
              });
            },
          ),
          
          if (_soundEnabled)
            ListTile(
              title: const Text('Alert Sound'),
              subtitle: const Text('Default'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: [PLACEHOLDER] Implement sound picker
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sound selection - to be implemented'),
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
                    content: Text('Settings saved'),
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text('Save Settings'),
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
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  onChanged(tempValue);
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
