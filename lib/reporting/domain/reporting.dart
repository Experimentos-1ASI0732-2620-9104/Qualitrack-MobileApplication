import 'package:equatable/equatable.dart';

import '../../shared/domain/value_objects.dart';

enum KpiMetricStatus {
  onTrack('ON_TRACK'),
  atRisk('AT_RISK'),
  critical('CRITICAL'),
  unknown('UNKNOWN');

  const KpiMetricStatus(this.code);

  final String code;

  static KpiMetricStatus fromCode(String? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return KpiMetricStatus.unknown;
  }
}

final class KpiMetric extends Equatable {
  const KpiMetric({
    required this.name,
    required this.status,
    this.id,
    this.value,
    this.unit,
    this.targetValue,
    this.recordedAt,
  });

  final int? id;
  final String name;
  final double? value;
  final String? unit;
  final double? targetValue;
  final KpiMetricStatus status;
  final DateTime? recordedAt;

  @override
  List<Object?> get props => [id, name, value, unit, targetValue, status, recordedAt];
}

/// Average, minimum and maximum of the readings of a device metric in the
/// period of the dashboard (`MeasurementSummaryResource`).
final class MeasurementSummary extends Equatable {
  const MeasurementSummary({
    required this.metric,
    required this.readings,
    this.environmentId,
    this.deviceId,
    this.unit,
    this.average,
    this.minimum,
    this.maximum,
  });

  final int? environmentId;
  final int? deviceId;
  final String metric;
  final String? unit;
  final int readings;
  final double? average;
  final double? minimum;
  final double? maximum;

  @override
  List<Object?> get props => [environmentId, deviceId, metric, unit, readings, average, minimum, maximum];
}

/// `KpiDashboardResource`. The platform calculates it on every request, so it
/// has no identifier and no overall health score.
final class KpiDashboard extends Equatable {
  const KpiDashboard({
    required this.laboratoryId,
    required this.metrics,
    this.id,
    this.summaries = const [],
    this.overallHealthScore,
    this.timestamp,
  });

  final int? id;
  final int laboratoryId;
  final double? overallHealthScore;
  final DateTime? timestamp;
  final List<KpiMetric> metrics;
  final List<MeasurementSummary> summaries;

  int get atRiskCount => metrics
      .where((m) => m.status == KpiMetricStatus.atRisk || m.status == KpiMetricStatus.critical)
      .length;

  @override
  List<Object?> get props => [id, laboratoryId, overallHealthScore, timestamp, metrics, summaries];
}

/// `AuditReportResource`.
final class AuditReport extends Equatable {
  const AuditReport({
    required this.id,
    required this.reportType,
    this.laboratoryId,
    this.batchId,
    this.equipmentId,
    this.generatedByName,
    this.dateRangeFrom,
    this.dateRangeTo,
    this.generatedAt,
    this.checksum,
  });

  final int id;
  final String reportType;
  final int? laboratoryId;
  final int? batchId;
  final int? equipmentId;
  final String? generatedByName;
  final String? dateRangeFrom;
  final String? dateRangeTo;
  final DateTime? generatedAt;
  final String? checksum;

  @override
  List<Object?> get props => [
    id,
    reportType,
    laboratoryId,
    batchId,
    equipmentId,
    generatedByName,
    dateRangeFrom,
    dateRangeTo,
    generatedAt,
    checksum,
  ];
}

enum TrendDirection {
  increasing('INCREASING'),
  decreasing('DECREASING'),
  stable('STABLE'),
  unknown('UNKNOWN');

  const TrendDirection(this.code);

  final String code;

  static TrendDirection fromCode(String? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return TrendDirection.unknown;
  }
}

final class TrendDataPoint extends Equatable {
  const TrendDataPoint({this.timestamp, this.recordedValue, this.upperThreshold, this.lowerThreshold});

  final DateTime? timestamp;
  final double? recordedValue;
  final double? upperThreshold;
  final double? lowerThreshold;

  @override
  List<Object?> get props => [timestamp, recordedValue, upperThreshold, lowerThreshold];
}

/// `DeviationTrendResource`.
final class DeviationTrend extends Equatable {
  const DeviationTrend({
    required this.id,
    required this.parameterName,
    required this.direction,
    required this.dataPoints,
  });

  final int id;
  final String parameterName;
  final TrendDirection direction;
  final List<TrendDataPoint> dataPoints;

  @override
  List<Object?> get props => [id, parameterName, direction, dataPoints];
}

/// `AuditLogEntryResource`.
final class AuditLogEntry extends Equatable {
  const AuditLogEntry({
    required this.id,
    required this.action,
    this.entityType,
    this.entityId,
    this.performedBy,
    this.timestamp,
    this.rawTimestamp,
    this.details,
  });

  final int id;
  final String action;
  final String? entityType;
  final int? entityId;
  final int? performedBy;
  final DateTime? timestamp;
  final String? rawTimestamp;
  final String? details;

  @override
  List<Object?> get props => [id, action, entityType, entityId, performedBy, timestamp, rawTimestamp, details];
}

abstract interface class ReportingRepository {
  /// Returns null when no KPI dashboard has been calculated yet (HTTP 404).
  Future<KpiDashboard?> getKpiDashboard(LaboratoryId laboratoryId);
  Future<List<AuditReport>> getLaboratoryReports(LaboratoryId laboratoryId);
  Future<List<DeviationTrend>> getDeviationTrends(int equipmentId);
  Future<List<AuditLogEntry>> getEquipmentAuditLogs(int equipmentId);
  Future<List<AuditLogEntry>> getBatchAuditLogs(int batchId);
}
