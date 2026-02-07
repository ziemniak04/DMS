import 'package:flutter/material.dart';
import 'package:dms_app/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Patient Connections Screen
///
/// Allows patients to connect to various health services and platforms
class PatientConnectionsScreen extends StatefulWidget {
  const PatientConnectionsScreen({super.key});

  @override
  State<PatientConnectionsScreen> createState() => _PatientConnectionsScreenState();
}

class _PatientConnectionsScreenState extends State<PatientConnectionsScreen> {
  final Map<String, bool> _connectionStatus = {};
  bool _isLoading = true;

  final List<HealthService> _services = [
    HealthService(
      id: 'apple_health',
      name: 'Apple Health',
      icon: Icons.favorite,
      color: Colors.red,
      description: 'Sync glucose data with Apple Health',
    ),
    HealthService(
      id: 'google_fit',
      name: 'Google Fit',
      icon: Icons.fitness_center,
      color: Colors.blue,
      description: 'Connect with Google Fit for activity tracking',
    ),
    HealthService(
      id: 'fitbit',
      name: 'Fitbit',
      icon: Icons.watch,
      color: Colors.teal,
      description: 'Sync data with your Fitbit device',
    ),
    HealthService(
      id: 'samsung_health',
      name: 'Samsung Health',
      icon: Icons.monitor_heart,
      color: Colors.indigo,
      description: 'Connect to Samsung Health services',
    ),
    HealthService(
      id: 'dexcom',
      name: 'Dexcom CGM',
      icon: Icons.sensors,
      color: Colors.orange,
      description: 'Connect to Dexcom continuous glucose monitor',
      hasDetailedSettings: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadConnectionStatus();
  }

  Future<void> _loadConnectionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (var service in _services) {
        _connectionStatus[service.id] = prefs.getBool('connected_${service.id}') ?? false;
      }
      _isLoading = false;
    });
  }

  Future<void> _toggleConnection(HealthService service) async {
    if (service.hasDetailedSettings && service.id == 'dexcom') {
      // Navigate to detailed Dexcom settings
      Navigator.pushNamed(context, '/dexcom-connection');
      return;
    }

    final isConnected = _connectionStatus[service.id] ?? false;

    if (isConnected) {
      // Disconnect
      final confirmed = await _showDisconnectDialog(service.name);
      if (confirmed == true) {
        await _disconnect(service);
      }
    } else {
      // Connect
      await _connect(service);
    }
  }

  Future<bool?> _showDisconnectDialog(String serviceName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Disconnect $serviceName?'),
        content: Text(
          'Are you sure you want to disconnect from $serviceName? '
          'Your data sync will be stopped.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }

  Future<void> _connect(HealthService service) async {
    setState(() {
      _isLoading = true;
    });

    // Simulate connection process
    await Future.delayed(const Duration(seconds: 1));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('connected_${service.id}', true);

    setState(() {
      _connectionStatus[service.id] = true;
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully connected to ${service.name}!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _disconnect(HealthService service) async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('connected_${service.id}', false);

    setState(() {
      _connectionStatus[service.id] = false;
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Disconnected from ${service.name}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Connections'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor.withValues(alpha: 0.08),
                        AppTheme.secondaryColor.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.health_and_safety_rounded,
                          color: AppTheme.primaryColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Connect to health services to sync your data and get a complete picture of your health.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ..._services.map((service) => _buildServiceCard(service)),
              ],
            ),
    );
  }

  Widget _buildServiceCard(HealthService service) {
    final isConnected = _connectionStatus[service.id] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isConnected
              ? service.color.withValues(alpha: 0.3)
              : AppTheme.dividerColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isConnected
                ? service.color.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                service.color.withValues(alpha: 0.2),
                service.color.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isConnected
                ? [
                    BoxShadow(
                      color: service.color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Icon(service.icon, color: service.color, size: 28),
        ),
        title: Text(
          service.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              service.description,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isConnected
                    ? AppTheme.glucoseNormal.withValues(alpha: 0.15)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isConnected ? AppTheme.glucoseNormal : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isConnected ? 'Connected' : 'Not connected',
                    style: TextStyle(
                      fontSize: 12,
                      color: isConnected ? AppTheme.glucoseNormal : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: service.hasDetailedSettings
            ? Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              )
            : Switch(
                value: isConnected,
                onChanged: (value) => _toggleConnection(service),
                activeColor: service.color,
              ),
        onTap: () => _toggleConnection(service),
      ),
    );
  }
}

class HealthService {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String description;
  final bool hasDetailedSettings;

  HealthService({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
    this.hasDetailedSettings = false,
  });
}
