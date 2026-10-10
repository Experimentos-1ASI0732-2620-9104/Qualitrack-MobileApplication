# QualiTrack Mobile

## Overview

Official Flutter companion app of **QualiTrack**, the pharmaceutical Quality
Management System by IoTech. It lets QA Managers, Supervisors and Lab Operators
monitor and review — from their phone — what is registered and configured in
QualiTrack Web: IoT telemetry, deviation alerts, production batches, inventory,
equipment, KPIs and billing.

> Creation and configuration (laboratories, products, materials, receipts,
> equipment, sensors, limits, batches, users, plans, checkout) stay in
> **QualiTrack Web**. The app never publishes telemetry.

## Features

- **Secure sign-in**: JWT stored in Keychain/Keystore, session restore, expiry handling and logout.
- **Command Center**: real operational metrics only.
- **Telemetry dashboard**: live polling (15 s), charts and anomalies, plus the raw telemetry log.
- **Compliance alerts**: filters, detail, **acknowledge** and **resolve** (QA Manager/Admin).
- **Production batches**: raw materials used, traceability, **release/reject** of existing batches (QA Manager/Admin).
- **Inventory**: usable/physical/minimum stock, receipts and movements.
- **Equipment**: telemetry status, BPM limits, maintenance, trends and audit log.
- **Catalog, KPIs and billing**: product catalog, KPI dashboard and report history, billing summary.
- **Multilingual support**: English and Spanish.
- **Accessible and responsive**: badges with icon and text, layouts from 360×640.

## Technologies

- Flutter and Dart (SDK `^3.7.0`), Material Design.
- BLoC (`flutter_bloc`) for state management.
- `get_it` for dependency injection.
- `go_router` for navigation.
- `dio` as the single HTTP client.
- `flutter_secure_storage` for the session token.
- `fl_chart` for telemetry and KPI charts.
- `equatable` and `intl`.
- Testing with `flutter_test`, `bloc_test` and `mocktail`.
- GitHub Actions and Firebase App Distribution for delivery.

## Architecture

Domain-Driven Design, one module per Bounded Context, each with
`domain / application / infrastructure / presentation` layers.

```
lib/
├── main.dart
├── app/            # composition root: theme, router, DI, MaterialApp
├── shared/         # failures, ApiClient, secure storage, l10n, widgets
├── iam/            # Identity & Access Management
├── laboratory/     # Laboratory Management (lab, products)
├── equipment/      # Equipment Management
├── tracking/       # Tracking & Telemetry
├── compliance/     # Compliance & Alerting
├── batch/          # Product Batch Management
├── inventory/      # Inventory Management
├── reporting/      # Reporting & Audit
├── subscription/   # Payments & Subscriptions
└── command_center/ # UI composition of the home screen
```

## Documentation

- **Architecture**: [docs/architecture.md](docs/architecture.md)
- **API mapping**: endpoint mapping in [docs/mobile-api-mapping.md](docs/mobile-api-mapping.md)
- **Initial analysis**: [docs/analysis.md](docs/analysis.md)
- **Changelog**: follow the project's evolution in [CHANGELOG.md](CHANGELOG.md)
- **License**: [LICENSE.md](LICENSE.md)

## Requirements

- Flutter stable 3.29 or newer (Dart ≥ 3.7)
- Android Studio / Android SDK
- A running `qualitrack-platform` backend

## Installation

The `android/` project is versioned, so there is no need to run `flutter create`.

```bash
git clone https://github.com/Experimentos-1ASI0732-2620-9104/Qualitrack-MobileApplication.git
cd Qualitrack-MobileApplication
flutter pub get
```

The Android application id is `com.iotech.qualitrack_mobile_app`.

## Environment variables

The backend URL is injected at build time with `--dart-define`; there is no
hardcoded default. If it is missing, the app shows a configuration screen.

| Variable | Description |
|---|---|
| `API_BASE_URL` | Host root of the QualiTrack backend, without `/api/v1` (it is appended automatically). |

| Target | Command |
|---|---|
| Android emulator (backend on your PC) | `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080` |
| Physical device (same Wi-Fi) | `flutter run --dart-define=API_BASE_URL=http://<your-PC-IP>:8080` |
| Deployed backend | `flutter run --dart-define=API_BASE_URL=https://<host>` |

For plain `http://` on Android 9+, allow cleartext traffic for development
(`android:usesCleartextTraffic="true"` in the debug manifest) or use HTTPS.

## Tests and quality

```bash
dart format .
flutter analyze
flutter test
```

On Windows you can run everything at once and keep a log in `tool/logs/verify.log`:

```powershell
powershell -ExecutionPolicy Bypass -File tool\verify.ps1
```

Localized strings are edited in `l10n/strings.tsv`, then regenerated with
`python tool/generate_l10n.py`. Do not edit `app_localizations.dart` by hand.

## Build APK

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://<host>
```

The APK is generated in `build/app/outputs/flutter-apk/app-release.apk`.
Push notifications are not implemented because the backend does not provide
them yet.

## Delivery

The workflow [`build-and-distribute-apk.yml`](.github/workflows/build-and-distribute-apk.yml)
runs `flutter analyze` and `flutter test`, builds the release APK and, when the
secrets are set, distributes it to the `qa-testers` group in Firebase App
Distribution. It runs on every `v*` tag and can also be started manually.

| Kind | Name | Value |
|---|---|---|
| Secret | `FIREBASE_APP_ID` | Firebase app id of `com.iotech.qualitrack_mobile_app` |
| Secret | `FIREBASE_SERVICE_ACCOUNT` | JSON of a service account with the *Firebase App Distribution Admin* role |
| Variable | `API_BASE_URL` | Backend host root |

## Versioning and workflow

- **Versions** follow [Semantic Versioning](https://semver.org/).
- **Branches** follow [Gitflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow):
  `main`, `develop`, `feature/*`, `release/*` and `hotfix/*`.
- **Commits** follow [Conventional Commits](https://www.conventionalcommits.org/).
- **Changes** are listed in [CHANGELOG.md](CHANGELOG.md), which follows
  [Keep a Changelog](https://keepachangelog.com/).

## License

This project is licensed under the MIT License. See [LICENSE.md](LICENSE.md).
