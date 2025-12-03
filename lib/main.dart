import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dms_app/core/theme/app_theme.dart';
import 'package:dms_app/core/router/app_router.dart';
import 'package:dms_app/providers/auth_provider.dart';
import 'package:dms_app/providers/glucose_provider.dart';
import 'package:dms_app/providers/events_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // TODO: [PLACEHOLDER] Initialize Firebase
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  
  runApp(const DMSApp());
}

/// DMS - Diabetes Management System
/// 
/// A comprehensive glucose tracking application with:
/// - Patient view for monitoring glucose levels
/// - Doctor view for managing patients
/// - Real-time sensor data integration (placeholder)
/// - Firebase authentication (placeholder)
class DMSApp extends StatelessWidget {
  const DMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GlucoseProvider()),
        ChangeNotifierProvider(create: (_) => EventsProvider()),
      ],
      child: MaterialApp.router(
        title: 'DMS - Diabetes Management System',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light, // TODO: [PLACEHOLDER] Make this configurable
        routerConfig: AppRouter.router,
      ),
    );
  }
}
