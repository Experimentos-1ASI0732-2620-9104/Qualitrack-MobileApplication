# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.2] - 2026-10-10

### Fixed
- The KPI dashboard did not load: the platform calculates it on every request and answers it without an `id`, which the app required. The `id` is now optional.

### Added
- Readings summary (average, minimum and maximum per device metric, last 7 days) in the KPI dashboard.

### Changed
- Telemetry metric names (`TEMPERATURE`, `HUMIDITY`, `LUMINOSITY`, `AIR_QUALITY`, `MOTION`, `RFID_TAG`) are shown translated in Spanish and English in telemetry, alerts, BPM limits, trends and the KPI dashboard.
- Platform KPI names (`equipment-count`, `unresolved-alert-count`, `batch-count`, `released-batch-count`) are shown as readable labels and the unknown status badge is hidden.
- Test suite grows to 94 tests.

## [1.0.1] - 2026-10-10

### Fixed
- Every screen except sign-in failed against the deployed platform v1.0.0, which reorganized its REST API. Equipment, inventory, billing, reports, products, alerts, batches and telemetry now use the laboratory and environment scoped routes.
- Alert acknowledge/resolve and batch release/reject use the new POST actions; the backend takes the user from the token, so `performedBy` is no longer sent.
- Telemetry is read per IoT device; readings in `WARNING` or `CRITICAL` state are shown as anomalies in the chart.
- Billing history reads the laboratory subscriptions list and an empty list means no active subscription.

### Changed
- Products, alerts and raw materials are aggregated from the environments of the laboratory (`EnvironmentDirectory`).
- `docs/mobile-api-mapping.md` rewritten against the platform v1.0.0 controllers.
- Test suite grows to 91 tests.

## [1.0.0] - 2026-10-10

### Added
- Initial release of the QualiTrack Mobile companion app, built with Flutter and organized by Bounded Context (`iam`, `laboratory`, `equipment`, `tracking`, `compliance`, `batch`, `inventory`, `reporting`, `subscription`, `command_center`).
- Secure sign-in with the JWT stored in the device keystore, session restore, expiry handling and logout.
- Command Center with real operational metrics.
- Telemetry dashboard with live polling, charts and anomalies, and the raw telemetry log.
- Compliance alerts with filters and detail, plus acknowledge and resolve actions for QA Manager and Admin.
- Production batches with raw materials used, traceability, and release/reject actions for QA Manager and Admin.
- Inventory, equipment, product catalog, KPI dashboard, report history and billing summary views.
- English and Spanish localization, generated from `l10n/strings.tsv` with `tool/generate_l10n.py`.
- Backend URL injected at build time through `--dart-define=API_BASE_URL`.
- Android project (`android/`) with the application id `com.iotech.qualitrack_mobile_app` and the `INTERNET` permission.
- GitHub Actions workflow that analyzes, tests and builds the release APK, and distributes it to Firebase App Distribution on `v*` tags.
- Unit, bloc and widget test suite (79 tests).
- Project documentation in `docs/` (analysis, architecture and API mapping), `README.md`, `CHANGELOG.md` and `LICENSE.md`.

### Changed
- `.gitignore` aligned with the official Flutter template, including Firebase credentials.

### Fixed
- Test suite failing to compile because `registerFallbackValue` was called with type arguments, which mocktail 1.0.5 does not accept.
- Analyzer warnings: redundant string interpolation in the generated localizations (fixed in the generator), deprecated `value` in the telemetry dropdowns and a missing `const` in `ApiConfig`.
- Invalid `secrets` context in the step-level condition of the Firebase distribution step.

[1.0.0]: https://github.com/Experimentos-1ASI0732-2620-9104/Qualitrack-MobileApplication/releases/tag/v1.0.0
