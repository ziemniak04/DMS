# DMS - Diabetes Management System

[![Flutter](https://img.shields.io/badge/Flutter-3.9.2+-02569B?logo=flutter)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115.0-009688?logo=fastapi)](https://fastapi.tiangolo.com)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A comprehensive cross-platform diabetes management system featuring real-time glucose monitoring, AI-powered insights, and seamless integration with Dexcom CGM sensors.

## Features

### For Patients
- Real-time glucose monitoring with Dexcom CGM integration
- Interactive glucose charts with multiple time ranges (3h, 6h, 12h, 24h)
- Diabetes event tracking (meals, insulin doses, exercise, sleep)
- AI-powered glucose analysis and personalized recommendations
- Smart notifications for high/low glucose alerts
- Historical data visualization and trend analysis

### For Doctors
- Patient dashboard with real-time glucose monitoring
- Alert management system for patient glucose levels
- Patient invitation and connection system (planned)
- Historical data review and analysis

### Backend Features
- Secure Dexcom API integration with OAuth 2.0
- Firebase Authentication and Firestore database
- Encrypted token storage for sensitive data
- Rate-limited API access (60,000 requests/hour)
- Docker containerization with PostgreSQL support

## Quick Start

### Prerequisites
- **Flutter SDK**: 3.9.2 or higher ([Install Flutter](https://docs.flutter.dev/get-started/install))
- **Dart SDK**: Included with Flutter
- **Firebase Account**: For authentication ([Firebase Console](https://console.firebase.google.com))
- **Docker** (optional): For running the backend ([Install Docker](https://docs.docker.com/get-docker/))

### Frontend Setup

1. **Clone the repository**
```bash
git clone https://github.com/ziemniak04/DMS.git
cd DMS
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure Firebase** (if using real Firebase)
   - Add your `google-services.json` (Android) to `android/app/`
   - Add your `GoogleService-Info.plist` (iOS) to `ios/Runner/`
   - Update `lib/firebase_options.dart` with your Firebase config

4. **Run the app**
```bash
# Web (recommended for development)
flutter run -d chrome

# Android
flutter run -d android

# iOS
flutter run -d ios

# Windows/Linux/macOS
flutter run -d windows  # or linux, macos
```

### Backend Setup (Optional)

The backend is required for Dexcom integration and production deployment.

1. **Navigate to backend directory**
```bash
cd backend
```

2. **Create environment file**
```bash
cp .env.example .env
# Edit .env with your configuration
```

3. **Start with Docker Compose**
```bash
docker-compose up -d
```

The backend API will be available at `http://localhost:8000`

API Documentation: `http://localhost:8000/docs`

## Demo Credentials

Test the app immediately with the included mock account:

**Mock Patient Account:**
- Email: `mocked@test.pl`
- Password: `123456`

This account comes with 7 days of realistic Type 1 Diabetes mock data including:
- Glucose readings (5-minute intervals)
- Meal events (breakfast, lunch, dinner)
- Insulin doses
- Sleep tracking

**Note**: The mock account generates data automatically on first login.

## Project Structure

```
DMS/
├── lib/                          # Flutter application source
│   ├── core/                     # Core utilities and config
│   │   ├── config.dart          # Application configuration
│   │   ├── constants/           # App constants
│   │   ├── router/              # Navigation setup
│   │   └── theme/               # Material Design theme
│   ├── features/                # Feature modules
│   │   ├── auth/                # Authentication screens
│   │   ├── patient/             # Patient dashboard & screens
│   │   ├── doctor/              # Doctor dashboard & screens
│   │   └── settings/            # Settings screens
│   ├── models/                  # Data models
│   ├── providers/               # State management (Provider pattern)
│   ├── services/                # Business logic services
│   │   ├── ai_assistant_service.dart
│   │   ├── dexcom_service.dart
│   │   ├── firestore_service.dart
│   │   ├── mock_data_service.dart
│   │   └── notification_service.dart
│   └── widgets/                 # Reusable UI components
│
├── backend/                      # FastAPI backend
│   ├── app/
│   │   ├── routers/             # API endpoints
│   │   ├── services/            # Business logic
│   │   ├── models/              # Pydantic models
│   │   └── utils/               # Utilities
│   ├── docker-compose.yml       # Docker setup
│   ├── Dockerfile               # Container definition
│   └── requirements.txt         # Python dependencies
│
├── android/                      # Android-specific files
├── ios/                          # iOS-specific files
├── web/                          # Web-specific files
├── windows/                      # Windows-specific files
├── linux/                        # Linux-specific files
└── macos/                        # macOS-specific files
```

## Configuration

### Frontend Configuration

Edit `lib/core/config.dart` to customize:
- AI Assistant API endpoint and credentials
- Feature flags (enable/disable features)
- Mock account settings
- Backend API URL
- Glucose target ranges

**Important**: For production deployment, move sensitive credentials to secure environment variables.

### Backend Configuration

Edit `backend/.env` with your settings:
```bash
# Dexcom API (get from https://developer.dexcom.com)
DEXCOM_CLIENT_ID=your_client_id
DEXCOM_CLIENT_SECRET=your_client_secret
DEXCOM_REDIRECT_URI=http://localhost:8000/dexcom/auth/callback

# Firebase
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_CREDENTIALS_PATH=/app/firebase-credentials.json

# Database
DATABASE_URL=postgresql://dms_user:dms_password@postgres:5432/dms

# Encryption Key (generate with: python -c "from cryptography.fernet import Fernet; debugPrint(Fernet.generate_key().decode())")
ENCRYPTION_KEY=your_encryption_key

# CORS
CORS_ORIGINS=http://localhost:3000,http://localhost:8080

# Debug mode (set to false in production)
DEBUG=true
```

## MVP Features Status

### ✅ Completed for MVP
- Authentication (Email/Password with Firebase)
- Mock patient account with realistic data
- Patient glucose dashboard with real-time display
- Interactive glucose charts (multiple time ranges)
- Glucose statistics and trends
- AI-powered glucose analysis
- Event tracking (meals, insulin, exercise)
- Notification system with customizable alerts
- Dexcom CGM integration (backend & frontend)
- Dark mode support
- Responsive Material Design 3 UI

### 🚧 Planned Features
- Doctor-patient connection system
- Patient search for doctors
- Detailed event timeline
- Data export (PDF reports)
- Multi-language support
- Apple Health / Google Fit integration
- Medication reminders
- Carb counting calculator

## Contributing

### Branch Strategy

We use a **three-branch workflow**:
- `master`: Production-ready code
- `dev`: Integration branch for testing
- `feature/*` or `fix/*`: Individual work branches

### Contribution Workflow

1. Create a feature branch from `dev`
2. Make your changes with clear commit messages
3. Create a Pull Request to `dev`
4. After review and testing, code is merged to `dev`
5. Periodically, `dev` is merged to `master` for releases

For detailed contribution guidelines, see [`.github/copilot-instructions.md`](.github/copilot-instructions.md).

## Troubleshooting

### Flutter App Won't Build
```bash
# Clean build cache
flutter clean
flutter pub get
flutter pub upgrade

# For iOS
cd ios && pod install && cd ..
```

### Firebase Connection Issues
- Ensure `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) are in the correct locations
- Check that your Firebase project has Authentication and Firestore enabled
- Verify your Firebase configuration in `lib/firebase_options.dart`

### Backend Won't Start
```bash
# Check Docker logs
docker-compose logs backend

# Rebuild containers
docker-compose down
docker-compose up --build
```

### Mock Account Not Generating Data
- The data is generated automatically on first login
- Check Firestore console for `glucoseReadings` collection
- Ensure Firebase credentials are properly configured

## Security Notes

For MVP demonstration purposes, this project includes:
- A mock patient account with demo credentials
- Configuration values in source code

**For production deployment:**
- Move all API keys and credentials to environment variables
- Enable Firebase security rules
- Use proper secret management (e.g., AWS Secrets Manager, Azure Key Vault)
- Set `DEBUG=false` in backend configuration
- Configure proper CORS origins (no wildcards)
- Enable HTTPS for all endpoints
- Implement proper authentication middleware in backend

## License

This project is developed as part of a cross-platform development course at Wrocław University of Science and Technology.

## Acknowledgments

- **Dexcom**: For providing the CGM API
- **Firebase**: For authentication and database services
- **Flutter Team**: For the amazing cross-platform framework
- **FastAPI**: For the high-performance Python backend framework

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Documentation](https://dart.dev/)
- [Material Design 3](https://m3.material.io/)
- [Provider Package](https://pub.dev/packages/provider)
- [GoRouter Package](https://pub.dev/packages/go_router)
- [Dexcom Developer Portal](https://developer.dexcom.com/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)

## Support

For issues and feature requests, please use the [GitHub Issues](https://github.com/ziemniak04/DMS/issues) page.
