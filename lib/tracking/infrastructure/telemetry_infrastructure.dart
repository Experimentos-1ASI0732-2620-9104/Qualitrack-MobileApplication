import '../../shared/domain/failure.dart';
import '../../shared/infrastructure/http/api_client.dart';
import '../../shared/infrastructure/http/environment_directory.dart';
import '../../shared/infrastructure/http/json_utils.dart';
import '../domain/telemetry.dart';

/// `DeviceTelemetryStatusResource`: the connection state of an IoT device.
class TelemetryStatusDto {
  const TelemetryStatusDto(this.json);

  final Map<String, dynamic> json;

  EquipmentTelemetryStatus toDomain() {
    final connected = Json.optString(json, 'connectionStatus') == 'CONNECTED';
    return EquipmentTelemetryStatus(
      equipmentId: Json.requireInt(json, 'deviceId'),
      isOnline: connected,
      currentStatus: connected ? TelemetryStatus.operational : TelemetryStatus.offline,
      lastHeartbeat: Json.optDateTime(json, 'lastCommunicationAt'),
      rawLastHeartbeat: Json.optString(json, 'lastCommunicationAt'),
    );
  }
}

/// `MeasurementResource` of a device. `equipmentId` is the device the readings
/// were requested for.
class MeasurementDto {
  const MeasurementDto(this.json);

  final Map<String, dynamic> json;

  Measurement toDomain() => Measurement(
    id: Json.requireInt(json, 'id'),
    equipmentId: Json.requireInt(json, 'equipmentId'),
    parameterName: Json.requireString(json, 'metric'),
    value: Json.requireDouble(json, 'value'),
    unit: Json.optString(json, 'unit'),
    timestamp: Json.optDateTime(json, 'measuredAt'),
    rawTimestamp: Json.optString(json, 'measuredAt'),
  );
}

/// A reading of the period; readings above the warning or critical threshold
/// (`state`) are the anomalies of the chart.
class TelemetryHistoryPointDto {
  const TelemetryHistoryPointDto(this.json);

  final Map<String, dynamic> json;

  TelemetryHistoryPoint toDomain() {
    final state = Json.optString(json, 'state');
    return TelemetryHistoryPoint(
      id: Json.requireInt(json, 'id'),
      equipmentId: Json.requireInt(json, 'equipmentId'),
      parameterName: Json.requireString(json, 'metric'),
      recordedValue: Json.requireDouble(json, 'value'),
      isAnomaly: state == 'WARNING' || state == 'CRITICAL',
      timestamp: Json.optDateTime(json, 'measuredAt'),
      rawTimestamp: Json.optString(json, 'measuredAt'),
    );
  }
}

class _Device {
  const _Device({required this.environmentId, required this.type});

  final int environmentId;
  final String type;
}

/// Read-only access to Tracking. The POST/PUT acquisition endpoints are
/// intentionally not exposed: the mobile app never publishes telemetry.
///
/// Telemetry belongs to IoT devices (equipment with a `deviceType`) inside an
/// environment, so the device is resolved from the equipment first.
class TelemetryRemoteDataSource {
  TelemetryRemoteDataSource(this._client, this._laboratoryId);

  final ApiClient _client;
  final LaboratoryIdProvider _laboratoryId;
  final Map<int, _Device> _devices = {};

  Future<_Device> _device(int equipmentId) async {
    final cached = _devices[equipmentId];
    if (cached != null) return cached;
    final equipment = Json.asMap(
      await _client.get('/laboratories/${_laboratoryId()}/equipments/$equipmentId'),
    );
    final environmentId = Json.optInt(equipment, 'environmentId');
    final type = Json.optString(equipment, 'deviceType');
    if (environmentId == null || type == null) {
      throw const NotFoundFailure(code: 'DEVICE_NOT_FOUND', message: 'The equipment has no IoT device');
    }
    return _devices[equipmentId] = _Device(environmentId: environmentId, type: type);
  }

  String _environmentPath(_Device device) =>
      '/laboratories/${_laboratoryId()}/environments/${device.environmentId}';

  Future<TelemetryStatusDto> getStatus(int equipmentId) async {
    final device = await _device(equipmentId);
    return TelemetryStatusDto(
      Json.asMap(await _client.get('${_environmentPath(device)}/devices/$equipmentId/telemetry-status')),
    );
  }

  /// Readings of the period (by default the last 24 hours), oldest first.
  /// Readings without a numeric value (text readings such as RFID tags) are
  /// not plotted.
  Future<List<Map<String, dynamic>>> getReadings(int equipmentId, {String? from, String? to}) async {
    final device = await _device(equipmentId);
    final path = device.type == 'CONTAINER_MONITOR'
        ? '${_environmentPath(device)}/container-monitors/$equipmentId/telemetry-measurements'
        : '${_environmentPath(device)}/telemetry-measurements';
    final readings = Json.asList(await _client.get(path, query: {'from': from, 'to': to}));
    return readings
        .where((reading) => Json.optDouble(reading, 'value') != null)
        .map((reading) => {...reading, 'equipmentId': equipmentId})
        .toList(growable: false);
  }
}

class TelemetryRepositoryImpl implements TelemetryRepository {
  const TelemetryRepositoryImpl(this._remote);

  final TelemetryRemoteDataSource _remote;

  @override
  Future<EquipmentTelemetryStatus> getStatus(int equipmentId) async =>
      (await _remote.getStatus(equipmentId)).toDomain();

  @override
  Future<List<Measurement>> getLatestMeasurements(int equipmentId) async =>
      (await _remote.getReadings(equipmentId)).map((r) => MeasurementDto(r).toDomain()).toList(growable: false);

  /// Same wire format as Web: `Date.toISOString()` (UTC, milliseconds, `Z`).
  @override
  Future<List<TelemetryHistoryPoint>> getHistory(
    int equipmentId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final readings = await _remote.getReadings(
      equipmentId,
      from: from == null ? null : toIsoMillis(from),
      to: to == null ? null : toIsoMillis(to),
    );
    return readings.map((r) => TelemetryHistoryPointDto(r).toDomain()).toList(growable: false);
  }
}

/// `2026-06-14T15:50:00.000Z`, identical to JavaScript `Date.toISOString()`.
String toIsoMillis(DateTime value) => DateTime.fromMillisecondsSinceEpoch(
  value.millisecondsSinceEpoch,
  isUtc: true,
).toIso8601String();
