# DMS - Diabetes Management System

## Project Overview

DMS (Diabetes Management System) is a Flutter-based mobile application for tracking glucose levels using continuous glucose monitoring (CGM) sensors. The app supports two user roles: **Patients** and **Doctors**.

## Project Structure

```
dms_app/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart       # App-wide constants and thresholds
│   │   ├── router/
│   │   │   └── app_router.dart          # GoRouter navigation configuration
│   │   └── theme/
│   │       └── app_theme.dart           # Material 3 theme configuration
│   ├── features/
│   │   ├── auth/
│   │   │   └── screens/
│   │   │       ├── login_screen.dart        # Login page
│   │   │       ├── register_screen.dart     # Registration page
│   │   │       └── role_selection_screen.dart
│   │   ├── patient/
│   │   │   └── screens/
│   │   │       ├── patient_dashboard_screen.dart  # Main patient view
│   │   │       ├── patient_history_screen.dart
│   │   │       ├── patient_connections_screen.dart
│   │   │       ├── patient_profile_screen.dart
│   │   │       └── add_event_screen.dart     # Add insulin/meal/activity
│   │   ├── doctor/
│   │   │   └── screens/
│   │   │       ├── doctor_dashboard_screen.dart   # Main doctor view
│   │   │       ├── doctor_patients_screen.dart
│   │   │       └── patient_detail_screen.dart     # View patient data
│   │   └── settings/
│   │       └── screens/
│   │           ├── settings_screen.dart
│   │           └── alerts_settings_screen.dart
│   ├── models/
│   │   ├── user.dart                    # User model (patient/doctor)
│   │   ├── glucose_reading.dart         # Glucose data model
│   │   └── diabetes_event.dart          # Event model (insulin, meal, etc.)
│   ├── providers/
│   │   ├── auth_provider.dart           # Authentication state
│   │   ├── glucose_provider.dart        # Glucose data management
│   │   └── events_provider.dart         # Events management
│   ├── widgets/
│   │   └── glucose_chart.dart           # Glucose chart widget (fl_chart)
│   └── main.dart                        # App entry point
└── pubspec.yaml
```

## Placeholder Locations

### 🔴 High Priority - Core Functionality

#### Firebase Integration
- **File:** `lib/main.dart`
  - TODO: Initialize Firebase
  
- **File:** `lib/providers/auth_provider.dart`
  - TODO: Replace mock login with `Firebase Auth signInWithEmailAndPassword`
  - TODO: Replace mock registration with `Firebase Auth createUserWithEmailAndPassword`
  - TODO: Add Google Sign-In
  - TODO: Add Apple Sign-In
  - TODO: Add password reset functionality
  - TODO: Add email verification
  - TODO: Save user data to Firestore

- **File:** `lib/providers/glucose_provider.dart`
  - TODO: Implement data sync with Firebase
  - TODO: Replace mock data with real Firestore queries

- **File:** `lib/providers/events_provider.dart`
  - TODO: Sync events with Firebase Firestore
  - TODO: Add offline support with local storage

#### Sensor API Integration
- **File:** `lib/providers/glucose_provider.dart`
  - TODO: Connect to real sensor API (Dexcom G7, Libre, etc.)
  - TODO: Implement real-time data streaming
  - TODO: Add Bluetooth connectivity for sensors
  - TODO: Implement actual sensor connection (scan, pair, receive data)

### 🟡 Medium Priority - Feature Completion

#### Patient Features
- **File:** `lib/features/patient/screens/patient_dashboard_screen.dart`
  - TODO: Implement sensor connection flow
  - TODO: Show chart options menu

- **File:** `lib/features/patient/screens/patient_history_screen.dart`
  - TODO: Implement daily/weekly/monthly history views
  - TODO: Add export functionality
  - TODO: Add filtering by event type

- **File:** `lib/features/patient/screens/patient_connections_screen.dart`
  - TODO: Implement doctor connection/invitation
  - TODO: Add QR code sharing
  - TODO: Implement data sharing permissions

- **File:** `lib/features/patient/screens/add_event_screen.dart`
  - TODO: Add form validation
  - TODO: Add date/time picker
  - TODO: Save events to Firebase

#### Doctor Features
- **File:** `lib/features/doctor/screens/doctor_dashboard_screen.dart`
  - TODO: Implement real patient data loading from Firebase
  - TODO: Add patient search functionality
  - TODO: Add patient invitation system

- **File:** `lib/features/doctor/screens/patient_detail_screen.dart`
  - TODO: Load real patient data from Firebase
  - TODO: Add event history timeline
  - TODO: Add notes functionality
  - TODO: Add recommendations feature

### 🟢 Low Priority - Enhancements

#### Settings
- **File:** `lib/features/settings/screens/settings_screen.dart`
  - TODO: Implement dark mode toggle
  - TODO: Add language selection
  - TODO: Add glucose unit switching (mg/dL ↔ mmol/L)
  - TODO: Save settings to SharedPreferences

- **File:** `lib/features/settings/screens/alerts_settings_screen.dart`
  - TODO: Save settings to SharedPreferences/Firebase
  - TODO: Add sound selection
  - TODO: Add vibration settings
  - TODO: Add repeat alert settings

#### UI Enhancements
- **File:** `lib/widgets/glucose_chart.dart`
  - TODO: Add touch interaction for reading details
  - TODO: Add zoom and pan functionality
  - TODO: Add trend arrows overlay

- **File:** `lib/core/theme/app_theme.dart`
  - TODO: Implement dark theme

## Dependencies

Current dependencies in `pubspec.yaml`:
- `go_router` - Navigation
- `provider` - State management
- `fl_chart` - Glucose charts
- `google_fonts` - Typography
- `intl` - Date/time formatting
- `shared_preferences` - Local storage

**To be added for Firebase:**
```yaml
firebase_core: ^2.24.2
firebase_auth: ^4.16.0
cloud_firestore: ^4.14.0
```

## Running the App

```bash
cd dms_app
flutter pub get
flutter run
```

## Demo Credentials

The mock authentication accepts:
- **Patient login:** Any email without "doctor" → `patient@demo.com`
- **Doctor login:** Email containing "doctor" or "dr" → `doctor@demo.com`
- **Password:** Any non-empty string

## Design Reference

The app UI is based on Dexcom G7 app design:
- Google Material Design 3 style
- Green accent color for health/glucose
- Bottom navigation bar
- Card-based layouts
- Time range selectors for charts (3, 6, 12, 24 hours)

## Key Features

### Patient View
1. **Dashboard** - Current glucose, chart, alerts
2. **Add Events** - Insulin, meals, activity, notes
3. **History** - Past readings and events
4. **Connections** - Share data with doctors
5. **Profile & Settings** - Alerts, preferences

### Doctor View
1. **Patient List** - All connected patients
2. **Alerts** - Critical patient notifications
3. **Patient Detail** - Individual patient data and charts
4. **Notes** - Add recommendations for patients

## Next Steps for Implementation

1. Set up Firebase project and add configuration
2. Implement Firebase Authentication
3. Create Firestore database schema
4. Integrate with CGM sensor SDK (Dexcom, Libre)
5. Add push notifications for alerts
6. Implement data export functionality
7. Add unit tests
