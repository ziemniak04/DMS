# Quick Setup Guide: Dexcom Scraper

## 30-Minute Setup

### Backend

**1. Install Dependencies**
```bash
cd backend
pip install -r requirements.txt
# Includes new: apscheduler==3.10.4
```

**2. Configure Environment**
```bash
# Create .env file
GOOGLE_APPLICATION_CREDENTIALS=/path/to/firebase-key.json
DEXCOM_CLIENT_ID=your_id
DEXCOM_CLIENT_SECRET=your_secret
DATABASE_URL=postgresql://user:pass@localhost/dms
```

**3. Start Backend**
```bash
python -m uvicorn app.main:app --reload
# Server running at: http://localhost:8000
```

### Flutter

**1. Add HTTP Dependency**
```yaml
# pubspec.yaml
dependencies:
  http: ^1.1.0
```

**2. Run `flutter pub get`**

**3. Use in Code**
```dart
import 'package:dms_app/services/data_sync_service.dart';

final syncService = DataSyncService(
  backendUrl: 'http://localhost:8000'
);

// Manual sync
await syncService.manualSync();

// Enable auto sync every 5 minutes
await syncService.enableAutoSync(intervalMinutes: 5);

// Get readings
final readings = await syncService.getGlucoseReadings(days: 7);
```

## Firestore Database Structure

The scraper automatically creates:

```
firestore/
├── users/{userId}/readings/          ← Glucose readings (EGVs)
├── users/{userId}/events/             ← Meals, insulin, activity
├── users/{userId}/daily_stats/        ← Daily average, min, max, etc.
└── dexcom_tokens/{userId}             ← Sync status & metadata
```

## Key APIs

### Manual Sync
```
POST /sync/manual
Response: {status: "sync_started", user_id, timestamp}
```

### Auto Sync
```
POST /sync/auto-enable?interval_minutes=5
POST /sync/auto-disable
GET  /sync/status
```

### Data Retrieval
```
GET /sync/readings?days=7&limit=100
GET /sync/latest-reading
GET /sync/events?days=7
GET /sync/daily-stats?year=2024&month=1
```

## What Gets Synced

✅ **Glucose Readings (EGVs)**
- Value, trend, timestamp
- Real-time and historical data

✅ **Events**
- Meals, insulin, activity
- User notes

✅ **Daily Statistics**
- Average glucose
- Min/Max values
- Time in range (%)
- Time high (%)
- Time low (%)

✅ **Metadata**
- Sync status
- Last sync time
- Error messages

## Real-Time Updates

```dart
// Watch readings in real-time
syncService.watchGlucoseReadings(days: 7).listen((readings) {
  setState(() => _readings = readings);
});

// Watch events
syncService.watchEvents(days: 7).listen((events) {
  setState(() => _events = events);
});
```

## Troubleshooting

### Sync won't start
- ✓ Verify backend is running: `curl http://localhost:8000/health`
- ✓ Check user has Dexcom token in Firestore
- ✓ Review backend logs

### No data appearing
- ✓ Check Firestore is initialized
- ✓ Verify GOOGLE_APPLICATION_CREDENTIALS env var set
- ✓ Ensure user authenticated with Firebase

### Stale data
- ✓ Manually trigger sync via app
- ✓ Check sync interval setting
- ✓ Verify backend can reach Dexcom API

## Files Modified/Created

### New Backend Files
- `app/services/firestore_service.py` - Firestore operations
- `app/services/dexcom_scraper.py` - Scraper logic
- `app/services/job_scheduler.py` - Background jobs (APScheduler)
- `app/routers/sync.py` - Sync endpoints

### New Flutter Files
- `lib/services/data_sync_service.dart` - Frontend integration

### Modified Backend Files
- `app/main.py` - Added Firestore init & sync router
- `requirements.txt` - Added apscheduler

## Next Steps

1. ✓ Deploy backend to cloud (Firebase Cloud Run)
2. ✓ Update Flutter app with sync UI
3. ✓ Test with real Dexcom account
4. ✓ Set up push notifications for alerts
5. ✓ Add data export functionality
6. ✓ Implement doctor data sharing

## Support

Detailed documentation: See `DEXCOM_SCRAPER_SETUP.md`

For issues:
1. Check backend logs: `docker logs dms-backend`
2. Verify Firestore in Firebase Console
3. Review sync status: `GET /sync/status`
4. Check scheduled jobs: `GET /sync/admin/jobs`
