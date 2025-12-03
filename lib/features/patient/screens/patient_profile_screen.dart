import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dms_app/providers/auth_provider.dart';
import 'package:dms_app/core/theme/app_theme.dart';

/// Patient Profile Screen
/// 
/// TODO: [PLACEHOLDER] Add profile editing
/// TODO: [PLACEHOLDER] Add profile picture upload
/// TODO: [PLACEHOLDER] Add diabetes type selection
class PatientProfileScreen extends StatelessWidget {
  const PatientProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          final user = auth.currentUser;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile Header
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.name ?? 'Użytkownik',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Settings Section
              const Text(
                'Ustawienia',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              _buildMenuItem(
                context,
                icon: Icons.notifications_outlined,
                title: 'Powiadomienia',
                onTap: () => context.push('/settings/alerts'),
              ),
              _buildMenuItem(
                context,
                icon: Icons.settings_outlined,
                title: 'Ustawienia aplikacji',
                onTap: () => context.push('/settings'),
              ),
              _buildMenuItem(
                context,
                icon: Icons.help_outline,
                title: 'Pomoc',
                onTap: () {
                  // TODO: [PLACEHOLDER] Implement help section
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.info_outline,
                title: 'O aplikacji',
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'DMS',
                    applicationVersion: '1.0.0',
                    applicationLegalese: '© 2024 DMS Team',
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              // Logout Button
              ElevatedButton.icon(
                onPressed: () async {
                  await auth.logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Wyloguj się'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
