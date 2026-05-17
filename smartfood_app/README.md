# SmartFood App

Flutter app for food ordering with 2 main roles:
- User: browse products, add to cart, checkout, manage orders, review products.
- Admin: manage products/orders/users/categories/promotions and view statistics.

## Tech Stack

- Flutter (SDK `^3.5.0`)
- Provider (state management)
- HTTP API integration
- Shared Preferences (local auth/session storage)
- fl_chart (statistics charts)

## Project Structure

Main directories:
- `lib/screen/user/`: user-facing screens and features
- `lib/screen/admin/`: admin dashboard and management pages
- `lib/services/api/`: API layer
- `lib/routes/`: route declarations and navigation helpers
- `lib/models/`: data models

Entry point:
- `lib/main.dart`

## Prerequisites

- Flutter SDK compatible with `pubspec.yaml`
- Dart SDK compatible with Flutter version
- Android Studio / VS Code + Flutter extension
- Running backend API

## Setup

1. Install dependencies:

```bash
flutter pub get
```

2. Run the app with default local API:

```bash
flutter run
```

3. (Optional) Override API URL via `dart-define`:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:7145/api
```

`API_BASE_URL` is optional. If not provided, app uses fallback URL in `lib/core/constants.dart`.

## Build

Android APK:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://your-api-domain/api
```

Windows:

```bash
flutter build windows --release --dart-define=API_BASE_URL=https://your-api-domain/api
```

## Quality Checks

Run these before merging/deploying:

```bash
flutter analyze
flutter test
```

## Security Note (SSL in Development)

- In debug/profile, the app allows self-signed certificates for local development.
- In release mode, SSL certificate bypass is disabled.

This keeps local development convenient while improving production safety.

## Main Routes

Defined in `lib/routes/app_route.dart`:
- `/login`
- `/main`
- `/home`
- `/cart`
- `/favorite`
- `/account`
- `/checkout`
- `/order-list`
- `/order-detail`
- `/admin-dashboard`

## Troubleshooting

- App cannot connect to API:
  - Check backend is running.
  - Verify `API_BASE_URL` (or fallback URL).
  - For Android emulator, use `10.0.2.2` to access host machine.
- Build errors after dependency changes:
  - Run `flutter clean`
  - Run `flutter pub get`

## Suggested Next Improvements

- Add unit/widget tests for critical flows (auth, cart, checkout, statistics).
- Replace local token storage with secure storage for production.
- Add staging/prod environment profiles and release documentation.
