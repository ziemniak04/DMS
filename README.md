# DMS - Diabetes Management System

A comprehensive Flutter application for tracking glucose levels using continuous glucose monitoring (CGM) sensors. The app supports two user roles: **Patients** and **Doctors**.

## Getting Started

### Prerequisites
- Flutter SDK (3.9.2+)
- Dart SDK
- Android Studio, Xcode, or Visual Studio Code
- Android device/emulator or web browser

### Installation

1. Clone the repository
```bash
git clone <repo-url>
cd DMS/dms_app
```

2. Get dependencies
```bash
flutter pub get
```

3. Run the app
```bash
flutter run        # For desktop (requires Visual Studio setup)
flutter run -d edge # For web (recommended for development)
flutter run -d android # For Android emulator
```

### Demo Credentials

Test the app with these mock credentials:

**Patient Login:**
- Email: `patient@demo.com`
- Password: (any non-empty string)

**Doctor Login:**
- Email: `doctor@demo.com` 
- Password: (any non-empty string)

## Contributing

### Branch Strategy

We follow a **three-phase branching strategy** to keep development organized and ensure code quality:

```
Your Work Branch (fix/feature-name)
    ↓
    └──→ Pull Request to: dev (Development)
         └──→ Tested & Reviewed
              └──→ Merge to: master (Production)
                   └──→ Tag as Major Release
```

### Workflow for Contributors

1. **Create a Feature/Fix Branch**
   ```bash
   git checkout dev
   git pull origin dev
   git checkout -b fix/your-feature-name
   ```
   - Use `fix/` for bug fixes
   - Use `feature/` for new features
   - Use `docs/` for documentation updates

2. **Make Your Changes**
   - Write clean, well-documented code
   - Follow Flutter best practices
   - Add placeholders with `TODO: [PLACEHOLDER]` for incomplete features
   - Test thoroughly before committing

3. **Push to Your Branch**
   ```bash
   git add .
   git commit -m "Clear description of changes"
   git push origin fix/your-feature-name
   ```

4. **Create a Pull Request to `dev`**
   - Go to GitHub and create a PR from `fix/your-feature-name` → `dev`
   - Describe what you changed and why
   - Wait for review and address feedback
   - Once approved, your code is merged to `dev`

5. **On Major Changes: Release to `master`**
   - When a significant feature is complete and tested in `dev`
   - Create a PR from `dev` → `master`
   - Tag the commit with a version number (e.g., `v1.0.0`)
   - This becomes the official production release

### Branch Rules

- ✅ **Always work on your own branch** (`fix/`, `feature/`, `docs/`)
- ✅ **Always PR to `dev` first** for review and testing
- ✅ **Only merge to `master`** when code is production-ready
- ✅ **Tag releases** on `master` with semantic versioning
- ❌ **Never commit directly** to `dev` or `master`

### Example Timeline

```
Week 1: You work on fix/glucose-chart-colors
        └─ Create PR: fix/glucose-chart-colors → dev ✓ Merged

Week 2: You work on feature/bluetooth-sensor
        └─ Create PR: feature/bluetooth-sensor → dev ✓ Merged

Week 3: Another contributor works on feature/firebase-setup
        └─ Create PR: feature/firebase-setup → dev ✓ Merged

Week 4: All features tested in dev. Time for release!
        └─ Create PR: dev → master
        └─ Tag as v0.2.0
        └─ Production release ready! 🚀
```

## Project Structure

See [`.github/copilot-instructions.md`](.github/copilot-instructions.md) for detailed project structure and placeholder locations.

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Documentation](https://dart.dev/)
- [Material Design 3](https://m3.material.io/)
- [Provider Package](https://pub.dev/packages/provider)
- [GoRouter Package](https://pub.dev/packages/go_router)
