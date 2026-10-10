import '../l10n/app_localizations.dart';

/// Telemetry metrics of the platform (`TEMPERATURE`, `HUMIDITY`, …) as readable
/// labels. Only the displayed text changes; limits and chart series keep
/// matching on the original name. Unknown metrics are shown as received.
String metricLabel(AppLocalizations l10n, String metric) {
  final key = metric.trim().toUpperCase().replaceAll(RegExp(r'[\s-]+'), '_');
  return switch (key) {
    'TEMPERATURE' => l10n.metricTemperature,
    'HUMIDITY' => l10n.metricHumidity,
    'LUMINOSITY' => l10n.metricLuminosity,
    'AIR_QUALITY' => l10n.metricAirQuality,
    'MOTION' => l10n.metricMotion,
    'RFID_TAG' => l10n.metricRfidTag,
    _ => metric,
  };
}
