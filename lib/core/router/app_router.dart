import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:dms_app/features/auth/screens/login_screen.dart';
import 'package:dms_app/features/auth/screens/register_screen.dart';
import 'package:dms_app/features/auth/screens/role_selection_screen.dart';
import 'package:dms_app/features/patient/screens/patient_dashboard_screen.dart';
import 'package:dms_app/features/patient/screens/patient_history_screen.dart';
import 'package:dms_app/features/patient/screens/patient_connections_screen.dart';
import 'package:dms_app/features/patient/screens/patient_profile_screen.dart';
import 'package:dms_app/features/doctor/screens/doctor_dashboard_screen.dart';
import 'package:dms_app/features/doctor/screens/doctor_patients_screen.dart';
import 'package:dms_app/features/doctor/screens/patient_detail_screen.dart';
import 'package:dms_app/features/settings/screens/settings_screen.dart';
import 'package:dms_app/features/settings/screens/alerts_settings_screen.dart';
import 'package:dms_app/features/settings/screens/dexcom_connection_screen.dart';
import 'package:dms_app/features/settings/screens/notification_settings_screen.dart';
import 'package:dms_app/features/auth/screens/splash_screen.dart';
import 'package:dms_app/features/patient/screens/add_event_screen.dart';
import 'package:dms_app/features/patient/screens/ai_assistant_screen.dart';

/// App Router Configuration
/// 
/// TODO: [PLACEHOLDER] Add authentication guards when Firebase is implemented
/// TODO: [PLACEHOLDER] Add deep linking support
class AppRouter {
  static GoRouter router(BuildContext context) {
    return GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      routes: [
      // Auth routes
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/role-selection',
        name: 'roleSelection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      
      // Patient routes
      GoRoute(
        path: '/patient',
        name: 'patientDashboard',
        builder: (context, state) => const PatientDashboardScreen(),
        routes: [
          GoRoute(
            path: 'history',
            name: 'patientHistory',
            builder: (context, state) => const PatientHistoryScreen(),
          ),
          GoRoute(
            path: 'connections',
            name: 'patientConnections',
            builder: (context, state) => const PatientConnectionsScreen(),
          ),
          GoRoute(
            path: 'profile',
            name: 'patientProfile',
            builder: (context, state) => const PatientProfileScreen(),
          ),
          GoRoute(
            path: 'add-event',
            name: 'addEvent',
            builder: (context, state) => const AddEventScreen(),
          ),
          GoRoute(
            path: 'ai-assistant',
            name: 'aiAssistant',
            builder: (context, state) => const AiAssistantScreen(),
          ),
        ],
      ),
      
      // Doctor routes
      GoRoute(
        path: '/doctor',
        name: 'doctorDashboard',
        builder: (context, state) => const DoctorDashboardScreen(),
        routes: [
          GoRoute(
            path: 'patients',
            name: 'doctorPatients',
            builder: (context, state) => const DoctorPatientsScreen(),
          ),
          GoRoute(
            path: 'patient/:patientId',
            name: 'patientDetail',
            builder: (context, state) => PatientDetailScreen(
              patientId: state.pathParameters['patientId']!,
            ),
          ),
        ],
      ),
      
      // Settings routes
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'alerts',
            name: 'alertsSettings',
            builder: (context, state) => const AlertsSettingsScreen(),
          ),
          GoRoute(
            path: 'dexcom',
            name: 'dexcomConnection',
            builder: (context, state) => const DexcomConnectionScreen(),
          ),
          GoRoute(
            path: 'notifications',
            name: 'notificationSettings',
            builder: (context, state) => const NotificationSettingsScreen(),
          ),
        ],
      ),
    ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text('Page not found: ${state.uri}'),
        ),
      ),
    );
  }
}
