import '../../shared/domain/value_objects.dart';
import '../../shared/domain/failure.dart';
import '../../shared/infrastructure/http/api_client.dart';
import '../../shared/infrastructure/http/environment_directory.dart';
import '../../shared/infrastructure/http/json_utils.dart';
import '../domain/batch.dart';

class BatchDto {
  const BatchDto(this.json);

  final Map<String, dynamic> json;

  ProductionBatch toDomain() => ProductionBatch(
    id: Json.requireInt(json, 'id'),
    labId: Json.requireInt(json, 'labId'),
    environmentId: Json.optInt(json, 'environmentId'),
    productId: Json.optInt(json, 'productId'),
    productName: Json.optString(json, 'productName'),
    batchNumber: Json.requireString(json, 'batchNumber'),
    quantity: Json.optDouble(json, 'quantity'),
    unit: Json.optString(json, 'unit'),
    status: BatchStatus.fromCode(Json.optString(json, 'status')),
    startDate: Json.optString(json, 'startDate'),
    endDate: Json.optString(json, 'endDate'),
    notes: Json.optString(json, 'notes'),
  );
}

class RawMaterialUsageDto {
  const RawMaterialUsageDto(this.json);

  final Map<String, dynamic> json;

  RawMaterialUsage toDomain() => RawMaterialUsage(
    id: Json.requireInt(json, 'id'),
    batchId: Json.requireInt(json, 'batchId'),
    rawMaterialId: Json.requireInt(json, 'rawMaterialId'),
    rawMaterialName: Json.optString(json, 'rawMaterialName'),
    quantityUsed: Json.optDouble(json, 'quantityUsed'),
    unit: Json.optString(json, 'unit'),
    usageDate: Json.optDateTime(json, 'usageDate'),
    rawUsageDate: Json.optString(json, 'usageDate'),
    stockBefore: Json.optDouble(json, 'stockBefore'),
    stockAfter: Json.optDouble(json, 'stockAfter'),
    inventoryReceiptId: Json.optInt(json, 'inventoryReceiptId'),
  );
}

class BatchRemoteDataSource {
  BatchRemoteDataSource(this._client, this._laboratoryId);

  final ApiClient _client;
  final LaboratoryIdProvider _laboratoryId;
  final Map<int, String> _pathOfBatch = {};

  Future<List<BatchDto>> getByLab(int labId) async {
    final batches = Json.asList(await _client.get('/laboratories/$labId/batches'));
    for (final batch in batches) {
      final environmentId = Json.optInt(batch, 'environmentId');
      final productId = Json.optInt(batch, 'productId');
      if (environmentId == null || productId == null) continue;
      _pathOfBatch[Json.requireInt(batch, 'id')] =
          '/laboratories/$labId/environments/$environmentId/products/$productId/batches';
    }
    return batches.map(BatchDto.new).toList();
  }

  /// Batch routes hang from the environment and the product of the batch,
  /// which the laboratory batch list provides.
  Future<String> _path(int batchId) async {
    if (!_pathOfBatch.containsKey(batchId)) await getByLab(_laboratoryId());
    final base = _pathOfBatch[batchId];
    if (base == null) throw const NotFoundFailure(code: 'BATCH_NOT_FOUND');
    return '$base/$batchId';
  }

  Future<BatchDto> getById(int batchId) async =>
      BatchDto(Json.asMap(await _client.get(await _path(batchId))));

  /// The raw materials consumed by the batch come with its traceability.
  Future<List<RawMaterialUsageDto>> getUsage(int batchId) async {
    final path = await _path(batchId);
    final traceability = Json.asMap(await _client.get('$path/traceability'));
    final usages = traceability['rawMaterials'];
    if (usages == null) return const [];
    return Json.asList(usages).map((usage) => RawMaterialUsageDto({...usage, 'batchId': batchId})).toList();
  }

  Future<void> release(int batchId, {required String releaseDate, required String notes}) async =>
      _post('${await _path(batchId)}/releases', {'releaseDate': releaseDate, 'notes': notes});

  Future<void> reject(int batchId, {required String rejectionDate, required String reason}) async =>
      _post('${await _path(batchId)}/rejections', {'rejectionDate': rejectionDate, 'reason': reason});

  Future<void> _post(String path, Map<String, dynamic> body) async {
    await _client.post(path, body: body);
  }
}

class BatchRepositoryImpl implements BatchRepository {
  const BatchRepositoryImpl(this._remote);

  final BatchRemoteDataSource _remote;

  @override
  Future<List<ProductionBatch>> getByLaboratory(LaboratoryId laboratoryId) async {
    final dtos = await _remote.getByLab(laboratoryId.value);
    return dtos
        .map((d) => d.toDomain())
        .where((b) => b.labId == laboratoryId.value)
        .toList(growable: false);
  }

  @override
  Future<ProductionBatch> getById(int batchId) async => (await _remote.getById(batchId)).toDomain();

  @override
  Future<List<RawMaterialUsage>> getRawMaterialUsage(int batchId) async =>
      (await _remote.getUsage(batchId)).map((d) => d.toDomain()).toList(growable: false);

  @override
  Future<ProductionBatch> release({
    required int batchId,
    required String releaseDate,
    required String notes,
  }) async {
    await _remote.release(batchId, releaseDate: releaseDate, notes: notes);
    return getById(batchId);
  }

  @override
  Future<ProductionBatch> reject({
    required int batchId,
    required String rejectionDate,
    required String reason,
  }) async {
    await _remote.reject(batchId, rejectionDate: rejectionDate, reason: reason);
    return getById(batchId);
  }
}
