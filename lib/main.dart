import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dms_app/core/theme/app_theme.dart';
import 'package:dms_app/core/router/app_router.dart';
import 'package:dms_app/providers/auth_provider.dart';
import 'package:dms_app/providers/glucose_provider.dart';
import 'package:dms_app/providers/events_provider.dart';
import 'package:dms_app/providers/settings_provider.dart';
import 'package:dms_app/providers/ai_assistant_provider.dart';
import 'package:dms_app/services/notification_service.dart';
import 'package:dms_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize notification service
  await NotificationService().initialize();

  runApp(const DMSApp());
}

/// DMS - Diabetes Management System
/// 
/// A comprehensive glucose tracking application with:
/// - Patient view for monitoring glucose levels
/// - Doctor view for managing patients
/// - Real-time sensor data integration
/// - Firebase authentication
class DMSApp extends StatelessWidget {
  const DMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GlucoseProvider()),
        ChangeNotifierProvider(create: (_) => EventsProvider()),
        ChangeNotifierProvider(create: (_) => AiAssistantProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return MaterialApp.router(
            title: 'DMS - Diabetes Management System',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.themeMode,
            routerConfig: AppRouter.router(context),
          );
        },
      ),
    );
  }
}
