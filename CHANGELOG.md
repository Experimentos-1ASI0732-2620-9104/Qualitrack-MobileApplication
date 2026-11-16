# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-11-16

### Added
- Profile (`profile`): the signed-in user sees their personal data, changes the photo from the avatar and confirms signing out.
- Command Center: the Home puts the most urgent alerts first, shows each active alert against its normal range, and can be seen as a list or as a dashboard; the choice is remembered.
- Equipment: the list is filtered from a menu with a summary card, and Edge Gateways are named, filtered and shown without BPM limits.
- Inventory: each material shows its usable stock as a bar against the minimum, with lots, movements and usages in tabs.
- Production batches: the detail summarizes the batch cycle, shows its history, and release and rejection are decided from a fixed bottom bar.
- Telemetry: the chart shades the normal range, the window is chosen among 15 minutes, 1, 6 and 24 hours, every device stays in sight and a help sheet explains the readings.
- Compliance alerts: each alert shows the limit next to its value, the lists say how current they are, and "mark all as read" can be undone before it reaches the server.
- Reports: the reports are split into tabs with their own lists of measurements, deviations and generated reports, and a period filter.
- Rubik typeface and the theme of the QualiTrack style guide.
- Architecture tests that enforce the DDD layer, bounded context and style guide rules. The test suite grows from 98 to 248 tests.

### Changed
- Every bounded context is restructured in `domain` (entities, interface and logic), `application` (a facade service), `infrastructure` (data providers, models and a single repository) and `presentation`, and talks to the others only through its `api` entry point.
- The `shared` folder is now `common`, and the localization directory `l10n` is now `i18n`; the strings are generated with `dart run tool/generate_i18n.dart` instead of the Python script.
- The Alerts tab comes right after Home, and the More tab opens on its menu.
- Backend codes (statuses, metrics, roles and types) are shown translated, and counts use the singular when they are 1.
- Lists and details share one layout, with the title in the app bar, detail rows and pull-to-refresh.
- The live telemetry reads the last 24 hours when it opens and then only the new readings on every 15 second poll (it asked for the last hour since 1.0.3).
- The Android app is labeled "QualiTrack", and the debug and profile builds allow a local backend over plain HTTP.
- App version set to `1.1.0+6`.

### Removed
- `tool/generate_l10n.py`, replaced by `tool/generate_i18n.dart`.

## [1.0.4] - 2026-10-10

### Changed
- The telemetry chart refreshes on every 15 second poll again, like the live readings (it was every 5 minutes since 1.0.3). The live readings keep the one-hour window.
- The deviation trends of the equipment detail cover the platform default of 7 days again instead of the last 6 hours.
- Test suite grows to 98 tests.

## [1.0.3] - 2026-10-10

### Fixed
- Telemetry showed an error for the equipment without an IoT device (the platform answers `404 DEVICE_NOT_FOUND`), and the first equipment alphabetically opened in error. The telemetry dashboard and the raw log now list only the equipment with a device, and the connection statuses are requested only for them.

### Changed
- The platform answers every reading of the requested period, so the live telemetry asks only for the last hour (about 60 KB instead of 870 KB per container), a device silent for that hour falls back to the last 24 hours once, the history refreshes every 5 minutes instead of every minute, and the trends of the equipment detail cover the last 6 hours instead of 7 days.
- Test suite grows to 97 tests.

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
