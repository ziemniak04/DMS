import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dms_app/services/notification_service.dart';
import 'package:dms_app/providers/ai_assistant_provider.dart';

/// Notification Settings Screen
/// 
/// Allows users to configure notification preferences including:
/// - Hourly blood sugar check reminders
/// - Quiet hours
/// - AI Assistant settings
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  
  bool _hourlyRemindersEnabled = false;
  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 7, minute: 0);
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    await _notificationService.initialize();
    
    final hourlyEnabled = await _notificationService.isHourlyRemindersEnabled();
    final (quietStart, quietEnd) = await _notificationService.getQuietHours();
    
    setState(() {
      _hourlyRemindersEnabled = hourlyEnabled;
      _quietStart = quietStart;
      _quietEnd = quietEnd;
      _isLoading = false;
    });
  }
  
  Future<void> _toggleHourlyReminders(bool enabled) async {
    // Request permissions first
    if (enabled) {
      final granted = await _notificationService.requestPermissions();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification permission is required for reminders'),
            ),
          );
        }
        return;
      }
    }
    
    await _notificationService.setHourlyRemindersEnabled(enabled);
    setState(() {
      _hourlyRemindersEnabled = enabled;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled 
                ? 'Hourly reminders enabled' 
                : 'Hourly reminders disabled',
          ),
        ),
      );
    }
  }
  
  Future<void> _selectQuietStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _quietStart,
      helpText: 'Select quiet hours start time',
    );
    
    if (time != null) {
      setState(() {
        _quietStart = time;
      });
      await _notificationService.setQuietHours(_quietStart, _quietEnd);
    }
  }
  
  Future<void> _selectQuietEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _quietEnd,
      helpText: 'Select quiet hours end time',
    );
    
    if (time != null) {
      setState(() {
        _quietEnd = time;
      });
      await _notificationService.setQuietHours(_quietStart, _quietEnd);
    }
  }
  
  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Hourly Reminders Section
                _buildSectionHeader('Blood Sugar Check Reminders'),
                SwitchListTile(
                  title: const Text('Hourly Reminders'),
                  subtitle: const Text('Get reminded to check your blood sugar every hour'),
                  value: _hourlyRemindersEnabled,
                  onChanged: _toggleHourlyReminders,
                  secondary: const Icon(Icons.schedule),
                ),
                
                // Quiet Hours Section
                _buildSectionHeader('Quiet Hours'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'No notifications will be sent during quiet hours',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.nightlight_round),
                  title: const Text('Start Time'),
                  subtitle: Text(_formatTime(_quietStart)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _selectQuietStartTime,
                ),
                ListTile(
                  leading: const Icon(Icons.wb_sunny),
                  title: const Text('End Time'),
                  subtitle: Text(_formatTime(_quietEnd)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _selectQuietEndTime,
                ),
                
                // AI Assistant Section
                _buildSectionHeader('AI Health Assistant'),
                Consumer<AiAssistantProvider>(
                  builder: (context, aiProvider, child) {
                    return Column(
                      children: [
                        SwitchListTile(
                          title: const Text('AI Assistant'),
                          subtitle: const Text('Get AI-powered glucose insights'),
                          value: aiProvider.isEnabled,
                          onChanged: (value) => aiProvider.setEnabled(value),
                          secondary: const Icon(Icons.smart_toy),
                        ),
                        ListTile(
                          leading: const Icon(Icons.health_and_safety),
                          title: const Text('Check Service Status'),
                          subtitle: const Text('Verify AI service availability'),
                          onTap: () async {
                            final available = await aiProvider.checkHealth();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(available 
                                      ? '✓ AI service is online' 
                                      : '✗ AI service is unavailable'),
                                  backgroundColor: available ? Colors.green : Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
                
                // Info Section
                _buildSectionHeader('About Notifications'),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              const Text(
                                'How it works',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '• Hourly reminders help you maintain regular blood sugar checks\n'
                            '• Quiet hours prevent notifications during sleep\n'
                            '• The AI assistant can analyze your readings and provide personalized tips',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
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
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
