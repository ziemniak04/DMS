# Dexcom CGM Integration Guide

This document explains how the Dexcom continuous glucose monitor (CGM) integration has been implemented in the DMS app.

## Overview

The integration uses the `dexcom` package (v1.0.7) which provides access to Dexcom Share API for real-time glucose monitoring.

## Implementation Details

### 1. Files Added/Modified

**New Files:**
- `lib/services/dexcom_service.dart` - Core service for Dexcom API integration
- `lib/features/settings/screens/dexcom_connection_screen.dart` - UI for authentication

**Modified Files:**
- `pubspec.yaml` - Added `dexcom: ^1.0.7` dependency
- `lib/providers/glucose_provider.dart` - Integrated Dexcom service
- `lib/core/router/app_router.dart` - Added route for Dexcom connection screen
- `lib/features/settings/screens/settings_screen.dart` - Added navigation to Dexcom settings

### 2. Features Implemented

#### DexcomService (`lib/services/dexcom_service.dart`)

**Key Methods:**
- `initialize()` - Auto-authenticate with stored credentials
- `authenticate(username, password, region, saveCredentials)` - Manual authentication
- `getCurrentReading(patientId)` - Get latest glucose reading
- `getReadings(patientId, minutes, maxCount)` - Get historical readings
- `streamReadings(patientId, seconds)` - Stream real-time glucose data
- `signOut()` - Disconnect and clear credentials
- `hasStoredCredentials()` - Check if credentials are saved

**Features:**
- Automatic credential storage using SharedPreferences
- Multi-region support (US, Outside US, Japan)
- Automatic session recovery on connection failure
- Trend conversion (Dexcom → App format)

#### GlucoseProvider Updates

**New Methods:**
- `initializeDexcom(patientId)` - Initialize with Dexcom service
- `authenticateDexcom(...)` - Authenticate user
- `loadGlucoseReadings(patientId, hours)` - Load glucose history
- `startGlucoseStream(patientId, intervalSeconds)` - Start real-time streaming
- `stopGlucoseStream()` - Stop streaming
- `refreshCurrentReading(patientId)` - Manually refresh current reading
- `hasDexcomCredentials()` - Check for saved credentials
- `disconnectSensor()` - Sign out from Dexcom

**Backward Compatibility:**
- `initializeMockData()` - Still available for testing without Dexcom
- `connectSensor()` - Now checks Dexcom authentication status

#### Dexcom Connection Screen

**Features:**
- Username/password authentication form
- Region selection (US, Outside US, Japan)
- Save credentials toggle
- Connection status display
- Medical disclaimer warning
- Help information section
- Disconnect functionality

**Navigation:**
Settings → Dane → Połączenie Dexcom

### 3. Usage

#### Initialize Dexcom on App Start

```dart
final glucoseProvider = Provider.of<GlucoseProvider>(context, listen: false);
final authProvider = Provider.of<AuthProvider>(context, listen: false);
final patientId = authProvider.user?.uid ?? '';

// Try to auto-connect with saved credentials
await glucoseProvider.initializeDexcom(patientId);

// Check if connected
if (glucoseProvider.sensorConnected) {
  // Start real-time streaming (updates every 5 minutes)
  await glucoseProvider.startGlucoseStream(patientId);
}
```

#### Manual Authentication

```dart
final success = await glucoseProvider.authenticateDexcom(
  patientId,
  'user@example.com',  // Dexcom Share username
  'password',          // Dexcom Share password
  region: 'us',        // 'us', 'ous', or 'jp'
  saveCredentials: true,
);

if (success) {
  // Start streaming
  await glucoseProvider.startGlucoseStream(patientId);
}
```

#### Access Glucose Data

```dart
// Current reading
final current = glucoseProvider.currentReading;
print('${current?.value} mg/dL - ${current?.trend}');

// All readings
final readings = glucoseProvider.readings;

// Last 8 hours
final recent = glucoseProvider.getReadingsForTimeRange(8);

// Statistics
final stats = glucoseProvider.getStatistics(24); // 24 hours
print('Average: ${stats['average']} mg/dL');
print('Time in Range: ${stats['inRange']}%');
```

#### Refresh Data

```dart
// Manual refresh
await glucoseProvider.refreshCurrentReading(patientId);

// Load more history
await glucoseProvider.loadGlucoseReadings(patientId, hours: 48);
```

#### Disconnect

```dart
await glucoseProvider.disconnectSensor();
```

### 4. Data Flow

1. User enters credentials in `DexcomConnectionScreen`
2. `GlucoseProvider.authenticateDexcom()` is called
3. `DexcomService` authenticates with Dexcom Share API
4. If successful, credentials are saved to SharedPreferences
5. `startGlucoseStream()` begins streaming glucose readings every 5 minutes
6. New readings are automatically added to `GlucoseProvider._readings`
7. UI updates via `notifyListeners()`

### 5. Data Model

Dexcom readings are converted to the app's `GlucoseReading` model:

```dart
GlucoseReading {
  id: 'dexcom_{timestamp}',
  patientId: '{userId}',
  value: 120.0,              // mg/dL
  timestamp: DateTime,
  trend: 'rising',           // 'rising_fast', 'rising', 'stable', 'falling', 'falling_fast'
  source: 'sensor',
}
```

### 6. Trend Mapping

| Dexcom Trend | App Trend |
|--------------|-----------|
| DoubleUp | rising_fast |
| SingleUp | rising |
| FortyFiveUp | rising |
| Flat | stable |
| FortyFiveDown | falling |
| SingleDown | falling |
| DoubleDown | falling_fast |

### 7. Important Notes

#### Medical Disclaimer
This integration uses the **unofficial Dexcom Share API**. The app displays a prominent warning:

> DO NOT USE THIS FOR CRITICAL MEDICAL TREATMENT DECISIONS.
> This uses an unofficial API and should be used for informational purposes only.
> Always consult your healthcare provider.

#### Requirements
- User must have a Dexcom CGM device
- Dexcom Share must be enabled in the official Dexcom app
- User must have Dexcom Share credentials (email/password)
- Active internet connection required

#### Limitations
- Data updates every 5 minutes (Dexcom limitation)
- Requires Dexcom Share to be running on another device
- Unofficial API - may break if Dexcom makes changes
- No access to official API features (alerts, calibrations, device info)

#### Data Storage
- Credentials stored in SharedPreferences (consider encryption for production)
- Only last 24 hours of readings kept in memory
- Historical data should be synced to Firebase (TODO)

### 8. Future Enhancements

- [ ] Encrypt stored credentials
- [ ] Sync glucose readings to Firestore
- [ ] Add background fetch for iOS
- [ ] Implement local notifications for glucose alerts
- [ ] Add data export functionality
- [ ] Support for other CGM devices (Libre, Guardian)
- [ ] Offline mode with cached data

### 9. Testing

#### Without Dexcom Account
Use the mock data functionality:
```dart
await glucoseProvider.initializeMockData(patientId);
```

#### With Dexcom Test Account
1. Go to Settings → Dane → Połączenie Dexcom
2. Enter test credentials
3. Select region
4. Toggle "Save credentials" if desired
5. Tap "Connect to Dexcom"

### 10. Troubleshooting

**"Failed to authenticate with Dexcom"**
- Verify credentials are correct
- Check that Dexcom Share is enabled
- Verify correct region is selected
- Check internet connection

**"Not authenticated with Dexcom"**
- Credentials may have expired
- Re-authenticate through Settings

**No new readings**
- Dexcom Share must be actively running on another device
- Check that CGM sensor is active
- Verify internet connection

**Stream not updating**
- Call `startGlucoseStream()` after authentication
- Check that app is in foreground (background limitations)

## Security Considerations

For production deployment:

1. **Encrypt credentials** - SharedPreferences stores data in plain text
2. **Use secure storage** - Consider `flutter_secure_storage` package
3. **Add certificate pinning** - Prevent man-in-the-middle attacks
4. **Implement token refresh** - Handle session expiration gracefully
5. **Add rate limiting** - Prevent API abuse
6. **Log security events** - Track authentication attempts

## Resources

- [Dexcom Package on pub.dev](https://pub.dev/packages/dexcom)
- [Dexcom Developer Portal](https://developer.dexcom.com/)
- Dexcom Share: Enable in official Dexcom G6/G7 mobile app
