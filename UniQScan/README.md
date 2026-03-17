# RIT OD Manager

Cross-platform Flutter application for managing On-Duty requests at an engineering college. The app supports five role-specific experiences:

- Student
- Mentor
- Event Coordinator
- HoD
- Verifier

## Stack

- Flutter 3.19+
- Dart 3.3+
- flutter_bloc
- dio
- go_router
- flutter_secure_storage
- mobile_scanner
- qr_flutter
- fl_chart
- flutter_pdfview
- firebase_messaging
- get_it

## Architecture

The app is organized in a Clean Architecture style under `lib/`:

- `core/` for shared constants, theme, services, networking, widgets, and models
- `features/auth` for splash, login, session restore, and auth state
- `features/student` for dashboard, OD creation, history, and request detail
- `features/mentor` for queue review and approval/rejection flow
- `features/event_coordinator` for queue, event registration, and PDF upload flow
- `features/hod` for queue, analytics, active session monitor, and bulk actions
- `features/verification` for QR scan and OD verification

## Mock Mode

Mock mode is enabled through a Dart define and is the fastest way to run the app without a backend.

Available mock users:

- Student
- Mentor
- Event Coordinator
- HoD
- Verifier

The login screen includes a role selector when mock mode is enabled.

## Required Dart Defines

Use these flags when running the app:

```bash
flutter run --dart-define=USE_MOCK=true --dart-define=API_BASE_URL=https://example.com
```

For real backend mode:

```bash
flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=https://your-api-host
```

## Setup

1. Install Flutter SDK and verify with `flutter doctor`.
2. Run `flutter pub get`.
3. If you need Firebase Messaging in a real environment, add platform Firebase configuration files.
4. Start the app with the appropriate `--dart-define` values.

## Notes

- Firebase initialization is wrapped defensively so local mock mode still starts even if Firebase is not configured.
- The current implementation uses `flutter_pdfview` as the PDF viewer dependency to avoid package resolution conflicts.
- Queue and history lists include pull-to-refresh and page-based loading hooks.

## Testing and Analysis

Useful commands:

```bash
flutter analyze
flutter test
```
