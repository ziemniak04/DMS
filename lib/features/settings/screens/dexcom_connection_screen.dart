import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dms_app/providers/glucose_provider.dart';
import 'package:dms_app/providers/auth_provider.dart';

/// Dexcom Connection Screen
///
/// Allows users to authenticate with their Dexcom account
/// and manage their Dexcom CGM connection.
class DexcomConnectionScreen extends StatefulWidget {
  const DexcomConnectionScreen({super.key});

  @override
  State<DexcomConnectionScreen> createState() => _DexcomConnectionScreenState();
}

class _DexcomConnectionScreenState extends State<DexcomConnectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedRegion = 'us';
  bool _saveCredentials = true;
  bool _obscurePassword = true;
  bool _isLoading = false;

  final List<Map<String, String>> _regions = [
    {'code': 'us', 'name': 'United States'},
    {'code': 'ous', 'name': 'Outside US'},
    {'code': 'jp', 'name': 'Japan'},
  ];

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleConnect() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final glucoseProvider = Provider.of<GlucoseProvider>(context, listen: false);
    final patientId = authProvider.currentUser?.id ?? '';

    final success = await glucoseProvider.authenticateDexcom(
      patientId,
      _usernameController.text.trim(),
      _passwordController.text,
      region: _selectedRegion,
      saveCredentials: _saveCredentials,
    );

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      if (success) {
        // Start real-time streaming
        await glucoseProvider.startGlucoseStream(patientId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully connected to Dexcom!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              glucoseProvider.error ?? 'Failed to connect to Dexcom',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDisconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Dexcom?'),
        content: const Text(
          'Are you sure you want to disconnect your Dexcom account? '
          'Your saved credentials will be removed.',
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

    if (confirmed == true && mounted) {
      final glucoseProvider = Provider.of<GlucoseProvider>(context, listen: false);
      await glucoseProvider.disconnectSensor();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Disconnected from Dexcom'),
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final glucoseProvider = Provider.of<GlucoseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dexcom Connection'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Medical Disclaimer
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Medical Disclaimer',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This integration uses an unofficial Dexcom API for informational purposes only. '
                        'DO NOT use this data for critical medical treatment decisions. '
                        'Always consult your healthcare provider.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Connection Status
              if (glucoseProvider.sensorConnected) ...[
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Connected to Dexcom',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Receiving real-time glucose data',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleDisconnect,
                  icon: const Icon(Icons.link_off),
                  label: const Text('Disconnect'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ] else ...[
                // Login Form
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Dexcom Share Username',
                    hintText: 'Enter your Dexcom Share username',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Region Selection
                DropdownButtonFormField<String>(
                  value: _selectedRegion,
                  decoration: const InputDecoration(
                    labelText: 'Region',
                    prefixIcon: Icon(Icons.public),
                    border: OutlineInputBorder(),
                  ),
                  items: _regions.map((region) {
                    return DropdownMenuItem(
                      value: region['code'],
                      child: Text(region['name']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRegion = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Save Credentials Checkbox
                CheckboxListTile(
                  title: const Text('Save credentials'),
                  subtitle: const Text('Automatically connect on app startup'),
                  value: _saveCredentials,
                  onChanged: (value) {
                    setState(() {
                      _saveCredentials = value ?? true;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 24),

                // Connect Button
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleConnect,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.link),
                  label: Text(_isLoading ? 'Connecting...' : 'Connect to Dexcom'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Help Text
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.info_outline, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Help',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '• Use your Dexcom Share credentials\n'
                        '• Make sure Dexcom Share is enabled in the Dexcom app\n'
                        '• Data updates every 5 minutes\n'
                        '• Select the correct region for your account',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
