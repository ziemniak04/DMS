# Firebase Console Setup - Step by Step

## Current Issue
The Android app is getting `CONFIGURATION_NOT_FOUND` error because Firebase services haven't been enabled in the console yet.

## Required Steps (Do these in order)

### Step 1: Enable Email/Password Authentication

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **glucosync-925f3**
3. Click **Authentication** in left menu
4. Click **Get Started** (if first time)
5. Go to **Sign-in method** tab
6. Click **Email/Password**
7. Toggle **Enable**
8. Click **Save**

### Step 2: Create Firestore Database

1. In Firebase Console, click **Firestore Database** in left menu
2. Click **Create database**
3. Select **Start in production mode** (we have security rules ready)
4. Click **Next**
5. Choose location: **us-central1** (or closest to you)
6. Click **Enable**
7. Wait for database to be created (1-2 minutes)

### Step 3: Deploy Firestore Security Rules

Once Firestore is created:

1. In Firebase Console, go to **Firestore Database** → **Rules**
2. Replace the default rules with our custom rules from `firestore.rules`
3. Or use Firebase CLI:
   ```bash
   firebase deploy --only firestore:rules
   ```

### Step 4: Update google-services.json (For Android)

After enabling services:

1. In Firebase Console, click gear icon ⚙️ → **Project settings**
2. Scroll to **Your apps** section
3. Find the Android app: `com.dms.dms_app`
4. Click **google-services.json** download button
5. Replace `android/app/google-services.json` with the new file

### Step 5: Test the App

**For Web (Recommended for first test):**
```bash
# Already running at http://localhost:8080
# Just open in browser
```

**For Android:**
```bash
flutter run -d android
```

## Quick Test Checklist

After completing setup:

- [ ] Authentication enabled in Firebase Console
- [ ] Firestore database created
- [ ] Security rules deployed
- [ ] Can register new user in app
- [ ] Can login with registered user
- [ ] Can see user data in Firestore Console

## Verification

### Check Authentication is enabled:
1. Firebase Console → Authentication → Sign-in method
2. Email/Password should show as "Enabled"

### Check Firestore is created:
1. Firebase Console → Firestore Database
2. Should see empty database with collections ready

### Check Security Rules:
1. Firebase Console → Firestore Database → Rules
2. Should see custom rules (not default)

## Expected Firestore Collections

After users register, you'll see these collections:

```
users/
  └── {userId}/
      ├── id
      ├── email
      ├── name
      ├── role
      └── ...

glucoseReadings/
  └── {readingId}/
      ├── userId
      ├── value
      ├── timestamp
      └── ...

diabetesEvents/
  └── {eventId}/
      ├── userId
      ├── type
      ├── timestamp
      └── ...
```

## Troubleshooting

### Web app shows "No Firebase App"
- Clear browser cache
- Hard reload (Ctrl+Shift+R)
- Check browser console for errors

### Android shows CONFIGURATION_NOT_FOUND
- Verify google-services.json is updated
- Clean and rebuild: `flutter clean && flutter pub get`
- Check package name matches in Firebase Console

### Can't login after registering
- Check Firestore security rules are deployed
- Verify user was created in Authentication tab
- Check browser/app console for specific error

## Firebase CLI Commands (Optional)

If you have Firebase CLI installed:

```bash
# Login to Firebase
firebase login

# Initialize (if needed)
firebase init

# Deploy rules only
firebase deploy --only firestore:rules

# View logs
firebase projects:list
```
