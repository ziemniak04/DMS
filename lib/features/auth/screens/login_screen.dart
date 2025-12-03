import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dms_app/providers/auth_provider.dart';
import 'package:dms_app/core/theme/app_theme.dart';

/// Login Screen
/// 
/// TODO: [PLACEHOLDER] Add Firebase Auth integration
/// TODO: [PLACEHOLDER] Add Google Sign-In button
/// TODO: [PLACEHOLDER] Add Apple Sign-In button
/// TODO: [PLACEHOLDER] Add "Forgot Password" functionality
/// TODO: [PLACEHOLDER] Add form validation
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        final user = authProvider.currentUser;
        if (user?.isDoctor ?? false) {
          context.go('/doctor');
        } else {
          context.go('/patient');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo and Title
                  Icon(
                    Icons.monitor_heart_outlined,
                    size: 80,
                    color: AppTheme.secondaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'DMS',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Diabetes Management System',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Proszę podać email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Hasło',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Proszę podać hasło';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: [PLACEHOLDER] Implement password reset
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Resetowanie hasła - do zaimplementowania'),
                          ),
                        );
                      },
                      child: const Text('Zapomniałeś hasła?'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error Message
                  Consumer<AuthProvider>(
                    builder: (context, auth, child) {
                      if (auth.error != null) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            auth.error!,
                            style: TextStyle(color: AppTheme.errorColor),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Login Button
                  Consumer<AuthProvider>(
                    builder: (context, auth, child) {
                      return ElevatedButton(
                        onPressed: auth.isLoading ? null : _handleLogin,
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Zaloguj się'),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'lub',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Google Sign-In Button (Placeholder)
                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: [PLACEHOLDER] Implement Google Sign-In
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Google Sign-In - do zaimplementowania'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.g_mobiledata, size: 24),
                    label: const Text('Kontynuuj z Google'),
                  ),
                  const SizedBox(height: 24),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Nie masz konta? ',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      TextButton(
                        onPressed: () => context.push('/register'),
                        child: const Text('Zarejestruj się'),
                      ),
                    ],
                  ),

                  // Demo login hint
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Demo:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const Text('Pacjent: patient@demo.com'),
                        const Text('Lekarz: doctor@demo.com'),
                        const Text('Hasło: dowolne'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
