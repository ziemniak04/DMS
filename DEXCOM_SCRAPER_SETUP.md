# Dexcom API Data Scraper & Firestore Integration

## Overview

This document describes the complete implementation of a Dexcom API data scraper that automatically syncs glucose readings and events to Firestore for analysis and storage. The system supports both manual and automatic periodic syncing with error handling and rate limiting.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Flutter Frontend (iOS/Android)              │
│                  - Manual sync button                           │
│                  - Auto sync enable/disable                     │
│                  - Real-time Firestore streams                  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ HTTP/REST API
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Backend FastAPI Server                        │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              Sync Endpoints (/sync)                      │  │
│  │  - POST /sync/manual          (trigger sync manually)    │  │
│  │  - POST /sync/auto-enable     (enable periodic syncing)  │  │
│  │  - POST /sync/auto-disable    (disable periodic syncing) │  │
│  │  - GET  /sync/status          (get sync status)          │  │
│  │  - GET  /sync/readings        (get stored readings)      │  │
│  │  - GET  /sync/events          (get stored events)        │  │
│  │  - GET  /sync/daily-stats     (get daily statistics)     │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │           Background Components                          │  │
│  │  - DexcomScraper (scrapes data from Dexcom API)         │  │
│  │  - JobScheduler  (APScheduler for periodic jobs)        │  │
│  │  - FirestoreService (stores/retrieves Firestore data)   │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────┬──────────────────────┬────────────────┬────────────────┘
         │                      │                │
         │ HTTP/REST API        │ Database       │ Firestore
         ▼                      ▼                ▼
    ┌─────────────┐      ┌─────────────┐  ┌──────────────┐
    │ Dexcom API  │      │ PostgreSQL  │  │  Google      │
    │             │      │             │  │  Firestore   │
    │ - OAuth     │      │ - Tokens    │  │  Database    │
    │ - EGVs      │      │ - Users     │  │              │
    │ - Events    │      │ - Settings  │  │ - Readings   │
    │ - Alerts    │      │             │  │ - Events     │
    │ - Devices   │      │             │  │ - Daily Stats│
    └─────────────┘      └─────────────┘  └──────────────┘
```

## Components

### 1. Backend Services

#### FirestoreService (`backend/app/services/firestore_service.py`)
Singleton service for all Firestore operations:

**Glucose Readings:**
```python
await firestore_service.store_glucose_reading(user_id, egv_data)
readings = await firestore_service.get_glucose_readings(user_id, days=7)
latest = await firestore_service.get_latest_glucose(user_id)
```

**Events (Meals, Insulin, Activity):**
```python
await firestore_service.store_event(user_id, event_type, event_data)
events = await firestore_service.get_events(user_id, days=7, event_type="meal")
```

**Statistics:**
```python
await firestore_service.store_daily_stats(user_id, stats_data)
stats = await firestore_service.get_monthly_stats(user_id, year, month)
```

**Firestore Database Structure:**
```
firestore/
├── users/
│   ├── {userId}/
│   │   ├── readings/
│   │   │   ├── {readingId}
│   │   │   │   ├── value: 145
│   │   │   │   ├── trend: "FLAT"
│   │   │   │   ├── timestamp: Timestamp
│   │   │   │   ├── dexcomId: "string"
│   │   │   │   └── ...
│   │   ├── events/
│   │   │   ├── {eventId}
│   │   │   │   ├── type: "meal"|"insulin"|"activity"|"note"
│   │   │   │   ├── timestamp: Timestamp
│   │   │   │   ├── data: {...}
│   │   │   │   └── createdAt: Timestamp
│   │   └── daily_stats/
│   │       ├── {dateISO}
│   │       │   ├── date: "2024-01-07"
│   │       │   ├── average: 145.3
│   │       │   ├── min: 110
│   │       │   ├── max: 190
│   │       │   ├── timeInRange: 78.5
│   │       │   ├── timeLow: 5.2
│   │       │   └── timeHigh: 16.3
│   └── ...
├── dexcom_tokens/
│   ├── {userId}
│   │   ├── userId: string
│   │   ├── dexcomAccountId: string
│   │   ├── lastSyncTime: Timestamp
│   │   ├── syncStatus: "active"|"paused"|"error"
│   │   ├── statusMessage: string
│   │   └── updatedAt: Timestamp
│   └── ...
```

#### DexcomScraper (`backend/app/services/dexcom_scraper.py`)
Background task for scraping Dexcom data:

**Features:**
- Scrapes latest glucose readings (EGVs)
- Fetches events (meals, insulin, activity)
- Calculates daily statistics (average, min, max, time in range)
- Handles errors gracefully with status updates
- Rate limiting to avoid Dexcom API throttling

**Methods:**
```python
scraper = DexcomScraper()
# Scrape single user
success = await scraper.scrape_user_data(user_id)

# Scrape all users with active connections
results = await scraper.scrape_all_users()
# Returns: {"total": X, "successful": Y, "failed": Z, "users": [...]}
```

#### JobScheduler (`backend/app/services/job_scheduler.py`)
APScheduler-based job scheduler for periodic syncing:

**Features:**
- Singleton pattern for single scheduler instance
- Support for per-user and global sync jobs
- Configurable interval between syncs
- Job listing and management

**Methods:**
```python
scheduler = JobScheduler()
scheduler.start()

# Add periodic scraper for all users
scheduler.add_dexcom_scraper_job(scrape_all_users_func, minutes=5)

# Add scraper for specific user
scheduler.add_user_scraper_job(user_id, scrape_user_func, minutes=5)

# Remove user's scraper
scheduler.remove_user_scraper_job(user_id)

# List all jobs
jobs = scheduler.list_jobs()
```

### 2. FastAPI Endpoints

#### Sync Endpoints (`backend/app/routers/sync.py`)

**Manual Sync:**
```
POST /sync/manual
Headers: X-User-ID: {userId}
Response: {status: "sync_started", user_id, timestamp}
```

**Auto Sync Control:**
```
POST /sync/auto-enable?interval_minutes=5
POST /sync/auto-disable
GET  /sync/status
```

**Data Retrieval:**
```
GET /sync/readings?days=7&limit=100
GET /sync/latest-reading
GET /sync/events?days=7&event_type=meal
GET /sync/daily-stats?year=2024&month=1
```

**Admin Endpoints:**
```
POST /sync/admin/sync-all          (sync all users)
GET  /sync/admin/jobs              (view scheduled jobs)
```

### 3. Flutter Integration

#### DataSyncService (`lib/services/data_sync_service.dart`)

**Manual Sync:**
```dart
final service = DataSyncService(backendUrl: 'http://localhost:8000');

// Trigger manual sync
final result = await service.manualSync();
```

**Auto Sync:**
```dart
// Enable auto sync every 5 minutes
await service.enableAutoSync(intervalMinutes: 5);

// Check status
final status = await service.getSyncStatus();

// Disable auto sync
await service.disableAutoSync();
```

**Retrieve Data:**
```dart
// Get glucose readings
final readings = await service.getGlucoseReadings(days: 7);

// Get latest reading
final latest = await service.getLatestReading();

// Get events
final events = await service.getEvents(days: 7, eventType: 'meal');

// Get daily stats
final stats = await service.getDailyStats(year: 2024, month: 1);
```

**Real-time Firestore Streams:**
```dart
// Watch glucose readings in real-time
service.watchGlucoseReadings(days: 7).listen((readings) {
  print('Updated readings: ${readings.length}');
});

// Watch events in real-time
service.watchEvents(days: 7).listen((events) {
  print('Updated events: ${events.length}');
});
```

## Setup & Configuration

### Backend Setup

1. **Install Dependencies:**
```bash
cd backend
pip install -r requirements.txt
```

2. **Environment Variables:**
Create a `.env` file:
```env
# Firebase
GOOGLE_APPLICATION_CREDENTIALS=/path/to/firebase-service-account.json

# Dexcom OAuth
DEXCOM_CLIENT_ID=your_client_id
DEXCOM_CLIENT_SECRET=your_client_secret
DEXCOM_REDIRECT_URI=http://localhost:8000/dexcom/auth/callback
DEXCOM_ENVIRONMENT=sandbox  # or 'production'

# Database
DATABASE_URL=postgresql://user:password@localhost/dms_db

# App
APP_NAME=DMS Backend
APP_VERSION=1.0.0
DEBUG=true
```

3. **Initialize Firestore:**
```bash
# Make sure GOOGLE_APPLICATION_CREDENTIALS points to your Firebase service account key
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json
```

4. **Run Backend:**
```bash
python -m uvicorn app.main:app --reload
```

### Flutter Setup

1. **Add http package to pubspec.yaml:**
```yaml
dependencies:
  http: ^1.1.0
```

2. **Initialize DataSyncService:**
```dart
import 'package:dms_app/services/data_sync_service.dart';

final syncService = DataSyncService(
  backendUrl: 'http://10.0.2.2:8000',  // Android emulator
  // or 'http://localhost:8000' for physical device on same network
);
```

## Data Flow

### Manual Sync Flow

```
User taps "Sync Now"
          ↓
    manualSync()
          ↓
   POST /sync/manual
          ↓
    Backend DexcomScraper
          ├─ Get Dexcom tokens from DB
          ├─ Fetch EGVs from Dexcom API
          ├─ Store readings to Firestore
          ├─ Fetch events from Dexcom API
          ├─ Store events to Firestore
          ├─ Calculate daily statistics
          └─ Update sync status
          ↓
      Return status
          ↓
  Display confirmation to user
  Real-time Firestore listeners update UI
```

### Auto Sync Flow

```
enableAutoSync(intervalMinutes: 5)
          ↓
 POST /sync/auto-enable
          ↓
 JobScheduler creates periodic task
          ↓
 Every 5 minutes:
   └─ DexcomScraper.scrape_user_data()
       └─ Same as manual sync flow
          ↓
 User sees real-time updates via Firestore
```

### Real-time Data Updates

```
Firestore Data Updated
          ↓
Flutter watchGlucoseReadings() stream fires
          ↓
GlucoseProvider notifies listeners
          ↓
UI rebuilds with new data
```

## Configuration Options

### Sync Intervals
- **5 minutes** (default): Good for active monitoring
- **15 minutes**: Balanced for most users
- **30 minutes**: Less frequent updates
- **60 minutes**: Minimal backend load

### Glucose Targets
Set in `backend/app/config.py`:
```python
GLUCOSE_TARGET_MIN = 80  # mg/dL
GLUCOSE_TARGET_MAX = 180  # mg/dL
```

### Rate Limiting
Dexcom API allows 60,000 requests/hour per account.

For N users syncing every M minutes:
- Requests per minute = N / M
- Hourly requests = (N / M) × 60

## Error Handling

### Network Errors
- Sync automatically retries on network timeout
- Queues data for next sync attempt
- Updates status to "error" in Firestore

### API Errors
- Dexcom API rate limits: Wait and retry
- Invalid token: Mark user for re-authentication
- Other errors: Log and notify user

### Firebase Errors
- Connection failures: Gracefully degrade to cached data
- Write failures: Retry on next sync
- Read failures: Show cached data

## Monitoring & Debugging

### View Sync Status
```dart
final status = await syncService.getSyncStatus();
print('Status: ${status['syncStatus']}');
print('Last sync: ${status['lastSyncTime']}');
```

### View Scheduled Jobs (Admin)
```bash
curl http://localhost:8000/sync/admin/jobs \
  -H "Authorization: Bearer $TOKEN"
```

### View Recent Data
```bash
curl http://localhost:8000/sync/readings?days=1&limit=10 \
  -H "X-User-ID: {userId}"
```

### Backend Logs
```bash
# View real-time logs
docker logs -f dms-backend

# Or if running locally
# Check console output for INFO/ERROR messages
```

## Performance Optimizations

### Firestore Indexes
Create composite indexes for common queries:
```
Collection: users/{userId}/readings
Composite Index:
  - timestamp (Descending)
  - value (Ascending)
```

### Batch Operations
Scraper batches Firestore writes to reduce API calls.

### Caching
- Latest reading cached in app memory
- Daily stats cached in Firestore

### Pagination
- Limit API responses to 100 readings max
- Client-side pagination for large datasets

## Troubleshooting

### Sync Not Starting
1. Verify user has Dexcom token: Check `dexcom_tokens` collection
2. Check backend logs for errors
3. Verify backend is running: `curl http://localhost:8000/health`

### Stale Data
1. Trigger manual sync
2. Check `lastSyncTime` in Firestore
3. Verify backend has network access to Dexcom API

### High Firestore Costs
1. Reduce sync frequency
2. Implement data retention policy
3. Archive old readings to Cloud Storage

### Performance Issues
1. Add Firestore indexes for common queries
2. Reduce limit parameter in API calls
3. Optimize daily stat calculations

## Security Considerations

### Authentication
- All endpoints require Firebase authentication (TODO)
- User can only access their own data
- Admin endpoints protected by role-based access

### OAuth Tokens
- Stored encrypted in PostgreSQL
- Refresh tokens stored securely
- Tokens rotated automatically

### Rate Limiting
- Per-user rate limits
- Dexcom API rate limit handling
- Backend request throttling

### Data Privacy
- User data encrypted at rest in Firestore
- Encrypted in transit (HTTPS)
- GDPR compliance (data export, deletion)

## Future Enhancements

1. **Push Notifications:** Alert users of highs/lows
2. **Data Export:** CSV/PDF export functionality
3. **Advanced Analytics:** Trends, patterns, recommendations
4. **Doctor Integration:** Share data with healthcare providers
5. **ML Predictions:** Glucose forecasting
6. **Offline Support:** Store data locally with sync when online

## Dependencies Added

```
apscheduler==3.10.4  # Background job scheduling
```

Already in requirements:
- firebase-admin==6.5.0
- httpx[http2]==0.27.2
- sqlalchemy==2.0.35
- fastapi==0.115.0

## API Response Examples

### Get Readings
```json
{
  "user_id": "firebase-uid",
  "count": 25,
  "readings": [
    {
      "id": "doc-id",
      "value": 145,
      "unit": "mg/dL",
      "trend": "FLAT",
      "trendRate": 0,
      "timestamp": "2024-01-07T10:30:00",
      "dexcomId": "dexcom-id"
    }
  ],
  "timestamp": "2024-01-07T11:00:00"
}
```

### Get Daily Stats
```json
{
  "user_id": "firebase-uid",
  "year": 2024,
  "month": 1,
  "count": 7,
  "stats": [
    {
      "id": "2024-01-01",
      "date": "2024-01-01",
      "average": 142.5,
      "min": 110,
      "max": 190,
      "timeInRange": 78.5,
      "timeHigh": 16.3,
      "timeLow": 5.2,
      "readingCount": 288
    }
  ],
  "timestamp": "2024-01-07T11:00:00"
}
```

## References

- [Dexcom API Documentation](https://developer.dexcom.com/build/latest)
- [Firebase Firestore Guide](https://firebase.google.com/docs/firestore)
- [APScheduler Documentation](https://apscheduler.readthedocs.io/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)

---

## 📊 Analysis Demo Feature

### Overview

A new demo feature has been added to showcase the analysis and data visualization functionality of the app. This feature generates mock glucose data and demonstrates:
- Statistics calculation (average, min, max, standard deviation)
- Time in range analysis (high, normal, low)
- HbA1c estimation
- Trend analysis
- Health recommendations

### Components

#### MockAnalysisService (`lib/services/mock_analysis_service.dart`)

Generates realistic mock data and performs analysis:

```dart
// Generate 24 hours of mock glucose readings
final readings = MockAnalysisService.generateMockReadings(hours: 24);

// Calculate statistics
final stats = MockAnalysisService.calculateStatistics(readings);
// Returns: average, min, max, stdev, timeInRange, timeHigh, timeLow

// Analyze trend
final trend = MockAnalysisService.analyzeTrend(readings);
// Returns: '📈 Rising trend' or '📉 Falling trend' or '→ Stable trend'

// Analyze daily pattern
final pattern = MockAnalysisService.analyzeDailyPattern(readings);
// Returns: '✓ Good control' or '⚠ Consider reviewing...'

// Estimate HbA1c
final hba1c = MockAnalysisService.estimateHbA1c(145.2);
// Returns: '6.8' (percentage)
```

#### AnalysisDemoDialog (`lib/widgets/analysis_demo_dialog.dart`)

A beautiful, tabbed dialog showing mocked analysis with three tabs:
- **Overview Tab:** Quick stats, current values, trend indicators
- **Statistics Tab:** Detailed metrics, progress bars for time in range
- **Insights Tab:** HbA1c estimation, daily patterns, health recommendations

### Integration with Dashboard

A new "View Analysis Demo" button on the patient dashboard next to the sensor connection button:

```dart
ElevatedButton.icon(
  onPressed: () {
    showDialog(
      context: context,
      builder: (context) => const AnalysisDemoDialog(),
    );
  },
  icon: const Icon(Icons.analytics),
  label: const Text('View Analysis Demo'),
)
```

### Files Created/Modified

**New Files:**
- `lib/services/mock_analysis_service.dart`
- `lib/widgets/analysis_demo_dialog.dart`

**Modified Files:**
- `lib/features/patient/screens/patient_dashboard_screen.dart`

---

**Complete Implementation:** January 7, 2026  
**All Components:** Backend scraper, Firestore integration, Flutter UI, Analysis demo
