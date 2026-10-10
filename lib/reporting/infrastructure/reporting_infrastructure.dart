import '../../shared/domain/value_objects.dart';
import '../../shared/infrastructure/http/api_client.dart';
import '../../shared/infrastructure/http/environment_directory.dart';
import '../../shared/infrastructure/http/json_utils.dart';
import '../domain/reporting.dart';

class KpiDashboardDto {
  const KpiDashboardDto(this.json);

  final Map<String, dynamic> json;

  KpiDashboard toDomain() => KpiDashboard(
    id: Json.optInt(json, 'id'),
    laboratoryId: Json.requireInt(json, 'laboratoryId'),
    overallHealthScore: Json.optDouble(json, 'overallHealthScore'),
    timestamp: Json.optDateTime(json, 'timestamp'),
    metrics: json['metrics'] == null
        ? const []
        : Json.asList(json['metrics']).map(_metric).toList(growable: false),
    summaries: json['measurementSummaries'] == null
        ? const []
        : Json.asList(json['measurementSummaries']).map(_summary).toList(growable: false),
  );

  static MeasurementSummary _summary(Map<String, dynamic> s) => MeasurementSummary(
    environmentId: Json.optInt(s, 'environmentId'),
    deviceId: Json.optInt(s, 'deviceId'),
    metric: Json.requireString(s, 'metric'),
    unit: Json.optString(s, 'unit'),
    readings: Json.optInt(s, 'readings') ?? 0,
    average: Json.optDouble(s, 'average'),
    minimum: Json.optDouble(s, 'minimum'),
    maximum: Json.optDouble(s, 'maximum'),
  );

  static KpiMetric _metric(Map<String, dynamic> m) => KpiMetric(
    id: Json.optInt(m, 'id'),
    name: Json.requireString(m, 'name'),
    value: Json.optDouble(m, 'value'),
    unit: Json.optString(m, 'unit'),
    targetValue: Json.optDouble(m, 'targetValue'),
    status: KpiMetricStatus.fromCode(Json.optString(m, 'status')),
    recordedAt: Json.optDateTime(m, 'recordedAt'),
  );
}

class AuditReportDto {
  const AuditReportDto(this.json);

  final Map<String, dynamic> json;

  AuditReport toDomain() => AuditReport(
    id: Json.requireInt(json, 'id'),
    reportType: Json.optString(json, 'reportType') ?? 'UNKNOWN',
    laboratoryId: Json.optInt(json, 'laboratoryId'),
    batchId: Json.optInt(json, 'batchId'),
    equipmentId: Json.optInt(json, 'equipmentId'),
    generatedByName: Json.optString(json, 'generatedByName'),
    dateRangeFrom: Json.optString(json, 'dateRangeFrom'),
    dateRangeTo: Json.optString(json, 'dateRangeTo'),
    generatedAt: Json.optDateTime(json, 'generatedAt'),
    checksum: Json.optString(json, 'checksum'),
  );
}

class DeviationTrendDto {
  const DeviationTrendDto(this.json);

  final Map<String, dynamic> json;

  DeviationTrend toDomain() => DeviationTrend(
    id: Json.requireInt(json, 'id'),
    parameterName: Json.requireString(json, 'parameterName'),
    direction: TrendDirection.fromCode(Json.optString(json, 'trendDirection')),
    dataPoints: json['dataPoints'] == null
        ? const []
        : Json.asList(json['dataPoints'])
              .map(
                (p) => TrendDataPoint(
                  timestamp: Json.optDateTime(p, 'timestamp'),
                  recordedValue: Json.optDouble(p, 'recordedValue'),
                  upperThreshold: Json.optDouble(p, 'upperThreshold'),
                  lowerThreshold: Json.optDouble(p, 'lowerThreshold'),
                ),
              )
              .toList(growable: false),
  );
}

class AuditLogEntryDto {
  const AuditLogEntryDto(this.json);

  final Map<String, dynamic> json;

  AuditLogEntry toDomain() => AuditLogEntry(
    id: Json.requireInt(json, 'id'),
    action: Json.optString(json, 'action') ?? 'UNKNOWN',
    entityType: Json.optString(json, 'entityType'),
    entityId: Json.optInt(json, 'entityId'),
    performedBy: Json.optInt(json, 'performedBy'),
    timestamp: Json.optDateTime(json, 'timestamp'),
    rawTimestamp: Json.optString(json, 'timestamp'),
    details: Json.optString(json, 'details'),
  );
}

class ReportingRemoteDataSource {
  ReportingRemoteDataSource(this._client, this._laboratoryId, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// The platform answers the last 7 days by default (about 1.8 MB for an
  /// environment); the equipment detail only needs the recent trend.
  static const Duration trendsWindow = Duration(hours: 6);

  final ApiClient _client;
  final LaboratoryIdProvider _laboratoryId;
  final DateTime Function() _clock;

  Future<KpiDashboardDto?> getKpiDashboard(int labId) => nullOnNotFound(
    () async => KpiDashboardDto(Json.asMap(await _client.get('/laboratories/$labId/kpi-dashboards'))),
  );

  Future<List<AuditReportDto>> getLaboratoryReports(int labId) async => Json.asList(
    await _client.get('/laboratories/$labId/reports'),
  ).map(AuditReportDto.new).toList();

  /// Trends are calculated per environment, so the ones of the environment of
  /// the equipment are filtered down to the equipment.
  Future<List<DeviationTrendDto>> getTrends(int equipmentId) async {
    final labId = _laboratoryId();
    final equipment = Json.asMap(await _client.get('/laboratories/$labId/equipments/$equipmentId'));
    final environmentId = Json.optInt(equipment, 'environmentId');
    if (environmentId == null) return const [];
    final trends = Json.asList(
      await _client.get(
        '/laboratories/$labId/environments/$environmentId/deviation-trends',
        query: {'from': _clock().toUtc().subtract(trendsWindow).toIso8601String()},
      ),
    );
    return trends
        .where((trend) => Json.optInt(trend, 'equipmentId') == equipmentId)
        .map(DeviationTrendDto.new)
        .toList();
  }

  Future<List<AuditLogEntryDto>> getEquipmentAuditLogs(int equipmentId) async => Json.asList(
    await _client.get('/laboratories/${_laboratoryId()}/equipments/$equipmentId/audit-logs'),
  ).map(AuditLogEntryDto.new).toList();

  Future<List<AuditLogEntryDto>> getBatchAuditLogs(int batchId) async => Json.asList(
    await _client.get('/batches/$batchId/audit-logs'),
  ).map(AuditLogEntryDto.new).toList();
}

class ReportingRepositoryImpl implements ReportingRepository {
  const ReportingRepositoryImpl(this._remote);

  final ReportingRemoteDataSource _remote;

  @override
  Future<KpiDashboard?> getKpiDashboard(LaboratoryId laboratoryId) async =>
      (await _remote.getKpiDashboard(laboratoryId.value))?.toDomain();

  @override
  Future<List<AuditReport>> getLaboratoryReports(LaboratoryId laboratoryId) async =>
      (await _remote.getLaboratoryReports(laboratoryId.value)).map((d) => d.toDomain()).toList();

  @override
  Future<List<DeviationTrend>> getDeviationTrends(int equipmentId) async =>
      (await _remote.getTrends(equipmentId)).map((d) => d.toDomain()).toList();

  @override
  Future<List<AuditLogEntry>> getEquipmentAuditLogs(int equipmentId) async =>
      (await _remote.getEquipmentAuditLogs(equipmentId)).map((d) => d.toDomain()).toList();

  @override
  Future<List<AuditLogEntry>> getBatchAuditLogs(int batchId) async =>
      (await _remote.getBatchAuditLogs(batchId)).map((d) => d.toDomain()).toList();
}
