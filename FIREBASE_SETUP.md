# Firebase Authentication Setup Guide

This document explains how to set up and use Firebase Authentication with Firestore in your DMS app.

## What's Been Implemented

### 1. Firebase Dependencies
- `firebase_core` - Core Firebase functionality
- `firebase_auth` - Authentication services
- `cloud_firestore` - Cloud database

### 2. Services Created

#### FirebaseAuthService (`lib/services/firebase_auth_service.dart`)
Handles all authentication operations:
- Email/password sign in
- Email/password registration
- Password reset
- Sign out
- Email verification
- Account deletion

#### FirestoreService (`lib/services/firestore_service.dart`)
Handles all database operations:
- User CRUD operations
- Patient-Doctor relationships
- Data streams for real-time updates

### 3. Updated Components

#### AuthProvider (`lib/providers/auth_provider.dart`)
- Now uses Firebase Auth instead of mock authentication
- Listens to auth state changes
- Manages user session with Firestore

#### User Model (`lib/models/user.dart`)
- Updated to handle Firestore timestamps
- Supports both String and Timestamp deserialization

#### Login Screen (`lib/features/auth/screens/login_screen.dart`)
- Fully functional password reset dialog
- Real Firebase authentication

## Firebase Console Setup

### Step 1: Enable Authentication Methods

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `glucosync-925f3`
3. Navigate to **Authentication** → **Sign-in method**
4. Enable **Email/Password** authentication:
   - Click on "Email/Password"
   - Toggle "Enable"
   - Click "Save"

### Step 2: Deploy Firestore Security Rules

The security rules have been created in `firestore.rules`. Deploy them using:

```bash
firebase deploy --only firestore:rules
```

Or manually copy the rules from `firestore.rules` to Firebase Console:
1. Go to **Firestore Database** → **Rules**
2. Copy the contents of `firestore.rules`
3. Click "Publish"

### Step 3: Create Firestore Database

1. Go to **Firestore Database**
2. Click **Create database**
3. Choose **Production mode** (our rules will handle security)
4. Select your preferred location
5. Click **Enable**

## Security Rules Overview

The Firestore security rules (`firestore.rules`) implement:

### User Access Control
- Users can read/update/delete their own profile
- Doctors can read patient profiles
- Doctors can assign themselves to patients

### Glucose Readings
- Users can manage their own readings
- Doctors can read their patients' readings

### Diabetes Events
- Users can manage their own events
- Doctors can read their patients' events

## How to Use

### Register a New User

```dart
// Patient registration
await authProvider.register(
  'patient@example.com',
  'password123',
  'Jan Kowalski',
  'patient',
);

// Doctor registration
await authProvider.register(
  'doctor@example.com',
  'password123',
  'Dr. Anna Nowak',
  'doctor',
);
```

### Sign In

```dart
await authProvider.login(
  'patient@example.com',
  'password123',
);
```

### Password Reset

```dart
await authProvider.sendPasswordResetEmail('patient@example.com');
```

### Sign Out

```dart
await authProvider.logout();
```

## Data Structure

### Users Collection

```json
{
  "id": "firebase_auth_uid",
  "email": "user@example.com",
  "name": "Jan Kowalski",
  "role": "patient", // or "doctor"
  "createdAt": "2024-01-01T00:00:00.000Z",

  // Doctor-specific fields
  "specialization": "Endocrinology",
  "licenseNumber": "12345",

  // Patient-specific fields
  "doctorId": "doctor_firebase_uid",
  "dateOfBirth": "1990-01-01T00:00:00.000Z",
  "diabetesType": "Type 1"
}
```

## Testing

### Test Registration Flow

1. Run the app:
   ```bash
   flutter run -d edge  # For web
   flutter run -d android  # For Android
   ```

2. Navigate to the registration screen
3. Fill in the form with valid data
4. Select role (Patient or Doctor)
5. Click "Zarejestruj się"
6. You should be automatically logged in and redirected

### Test Login Flow

1. Use credentials from a registered account
2. Enter email and password
3. Click "Zaloguj się"
4. You should be redirected to the appropriate dashboard

### Test Password Reset

1. Click "Zapomniałeś hasła?" on login screen
2. Enter your email address
3. Click "Wyślij"
4. Check your email for the password reset link
5. Follow the link to reset your password

## Error Handling

All Firebase errors are translated to Polish user-friendly messages:

| Error Code | Polish Message |
|------------|----------------|
| `user-not-found` | Nie znaleziono użytkownika z tym adresem email. |
| `wrong-password` | Nieprawidłowe hasło. |
| `email-already-in-use` | Ten adres email jest już używany. |
| `invalid-email` | Nieprawidłowy format adresu email. |
| `weak-password` | Hasło jest zbyt słabe. Użyj minimum 6 znaków. |
| `too-many-requests` | Zbyt wiele prób. Spróbuj ponownie później. |

## Next Steps

### Optional Enhancements

1. **Email Verification**
   - Require users to verify their email before accessing the app
   - Call `_authService.sendEmailVerification()` after registration

2. **Google Sign-In**
   - Add `google_sign_in` package
   - Implement Google authentication flow

3. **Profile Picture Upload**
   - Add Firebase Storage
   - Allow users to upload profile pictures

4. **Patient-Doctor Connections**
   - Implement invite/accept flow
   - Add patient search for doctors

## Troubleshooting

### "Permission denied" errors
- Check Firestore security rules are deployed
- Verify user is authenticated
- Ensure user has correct role in Firestore

### Authentication errors
- Verify Email/Password auth is enabled in Firebase Console
- Check network connection
- Ensure Firebase project is correctly configured

### Build errors
- Run `flutter clean`
- Run `flutter pub get`
- Rebuild the app

## Support

For Firebase documentation:
- [Firebase Auth Docs](https://firebase.google.com/docs/auth)
- [Firestore Docs](https://firebase.google.com/docs/firestore)
- [FlutterFire Docs](https://firebase.flutter.dev/)
