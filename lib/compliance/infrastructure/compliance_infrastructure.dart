import '../../shared/domain/value_objects.dart';
import '../../shared/infrastructure/http/api_client.dart';
import '../../shared/infrastructure/http/environment_directory.dart';
import '../../shared/infrastructure/http/json_utils.dart';
import '../domain/compliance.dart';

class DeviationAlertDto {
  const DeviationAlertDto(this.json);

  final Map<String, dynamic> json;

  DeviationAlert toDomain() => DeviationAlert(
    id: Json.requireInt(json, 'id'),
    equipmentId: Json.requireInt(json, 'equipmentId'),
    batchId: Json.optInt(json, 'batchId'),
    parameterName: Json.requireString(json, 'parameterName'),
    recordedValue: Json.optDouble(json, 'recordedValue'),
    thresholdValue: Json.optDouble(json, 'thresholdValue'),
    unit: Json.optString(json, 'unit'),
    timestamp: Json.optDateTime(json, 'timestamp'),
    rawTimestamp: Json.optString(json, 'timestamp'),
    severity: AlertSeverity.fromCode(Json.optString(json, 'severity')),
    status: AlertStatus.fromCode(Json.optString(json, 'status')),
    acknowledgedBy: Json.optInt(json, 'acknowledgedBy'),
    resolvedBy: Json.optInt(json, 'resolvedBy'),
    resolutionNotes: Json.optString(json, 'resolutionNotes'),
  );
}

class ComplianceEventDto {
  const ComplianceEventDto(this.json);

  final Map<String, dynamic> json;

  ComplianceEvent toDomain() => ComplianceEvent(
    id: Json.requireInt(json, 'id'),
    eventType: Json.requireString(json, 'eventType'),
    relatedEntityId: Json.optInt(json, 'relatedEntityId'),
    description: Json.optString(json, 'description'),
    timestamp: Json.optDateTime(json, 'timestamp'),
    rawTimestamp: Json.optString(json, 'timestamp'),
    resolvedBy: Json.optInt(json, 'resolvedBy'),
  );
}

class ComplianceRemoteDataSource {
  const ComplianceRemoteDataSource(this._client, this._environments, this._laboratoryId);

  final ApiClient _client;
  final EnvironmentDirectory _environments;
  final LaboratoryIdProvider _laboratoryId;

  /// Alerts are listed per environment (they include its container monitors),
  /// so the laboratory alerts are the union of the environments.
  Future<List<DeviationAlertDto>> getLaboratoryAlerts(int labId) async {
    final alerts = <DeviationAlertDto>[];
    for (final environmentId in await _environments.ids(labId)) {
      final items = Json.asList(
        await _client.get('/laboratories/$labId/environments/$environmentId/deviation-alerts'),
      );
      alerts.addAll(items.map(DeviationAlertDto.new));
    }
    return alerts;
  }

  Future<DeviationAlertDto> getAlert(int alertId) async =>
      DeviationAlertDto(Json.asMap(await _client.get('/deviation-alerts/$alertId')));

  Future<DeviationAlertDto> acknowledge(int alertId) async => DeviationAlertDto(
    Json.asMap(await _client.post('/deviation-alerts/$alertId/acknowledgements')),
  );

  Future<DeviationAlertDto> resolve(int alertId, String resolutionNotes) async => DeviationAlertDto(
    Json.asMap(
      await _client.post(
        '/deviation-alerts/$alertId/resolutions',
        body: {'resolutionNotes': resolutionNotes},
      ),
    ),
  );

  Future<List<ComplianceEventDto>> getEquipmentEvents(int equipmentId) async => Json.asList(
    await _client.get('/laboratories/${_laboratoryId()}/equipments/$equipmentId/compliance-events'),
  ).map(ComplianceEventDto.new).toList();

  Future<List<ComplianceEventDto>> getBatchEvents(int batchId) async => Json.asList(
    await _client.get('/batches/$batchId/compliance-events'),
  ).map(ComplianceEventDto.new).toList();
}

class ComplianceRepositoryImpl implements ComplianceRepository {
  const ComplianceRepositoryImpl(this._remote, this._laboratoryId);

  final ComplianceRemoteDataSource _remote;
  final LaboratoryIdProvider _laboratoryId;

  @override
  Future<List<DeviationAlert>> getLaboratoryAlerts(LaboratoryId laboratoryId) async =>
      (await _remote.getLaboratoryAlerts(laboratoryId.value)).map((d) => d.toDomain()).toList();

  /// The backend has no per-batch alert route: the alerts of the laboratory
  /// that reference the batch are the alerts of the batch.
  @override
  Future<List<DeviationAlert>> getBatchAlerts(int batchId) async {
    final alerts = await _remote.getLaboratoryAlerts(_laboratoryId());
    return alerts.map((d) => d.toDomain()).where((a) => a.batchId == batchId).toList();
  }

  @override
  Future<DeviationAlert> getAlert(int alertId) async => (await _remote.getAlert(alertId)).toDomain();

  @override
  Future<DeviationAlert> acknowledge({required int alertId}) async =>
      (await _remote.acknowledge(alertId)).toDomain();

  @override
  Future<DeviationAlert> resolve({required int alertId, required String resolutionNotes}) async =>
      (await _remote.resolve(alertId, resolutionNotes)).toDomain();

  @override
  Future<List<ComplianceEvent>> getEquipmentEvents(int equipmentId) async =>
      (await _remote.getEquipmentEvents(equipmentId)).map((d) => d.toDomain()).toList();

  @override
  Future<List<ComplianceEvent>> getBatchEvents(int batchId) async =>
      (await _remote.getBatchEvents(batchId)).map((d) => d.toDomain()).toList();
}
