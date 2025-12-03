import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dms_app/core/theme/app_theme.dart';

/// Role Selection Screen
/// Displayed after registration to confirm user role
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Kim jesteś?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Wybierz swój typ konta',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 48),
              
              // Patient Card
              _RoleSelectionCard(
                title: 'Pacjent',
                description: 'Monitoruj poziom glukozy i dziel się danymi z lekarzem',
                icon: Icons.person,
                color: AppTheme.secondaryColor,
                onTap: () => context.go('/patient'),
              ),
              const SizedBox(height: 16),
              
              // Doctor Card
              _RoleSelectionCard(
                title: 'Lekarz',
                description: 'Monitoruj pacjentów i analizuj ich dane zdrowotne',
                icon: Icons.medical_services,
                color: AppTheme.primaryColor,
                onTap: () => context.go('/doctor'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleSelectionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoleSelectionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
