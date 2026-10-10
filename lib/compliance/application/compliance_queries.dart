import '../../shared/domain/failure.dart';
import '../../shared/domain/value_objects.dart';
import '../domain/compliance.dart';

/// Laboratory-wide alerts, aggregated by the repository from the alerts of
/// every environment of the laboratory.
class GetLaboratoryAlerts {
  const GetLaboratoryAlerts(this._repository);

  final ComplianceRepository _repository;

  Future<List<DeviationAlert>> call(LaboratoryId laboratoryId) async {
    final alerts = await _repository.getLaboratoryAlerts(laboratoryId);
    return [...alerts]..sort(DeviationAlert.compareByPriority);
  }
}

class GetBatchAlerts {
  const GetBatchAlerts(this._repository);

  final ComplianceRepository _repository;

  Future<List<DeviationAlert>> call(int batchId) async {
    final alerts = await _repository.getBatchAlerts(batchId);
    return [...alerts]..sort(DeviationAlert.compareByPriority);
  }
}

class GetAlertDetail {
  const GetAlertDetail(this._repository);

  final ComplianceRepository _repository;

  Future<DeviationAlert> call(int alertId) => _repository.getAlert(alertId);
}

/// Command: UNRESOLVED → ACKNOWLEDGED. The backend records the signed-in user.
class AcknowledgeAlert {
  const AcknowledgeAlert(this._repository);

  final ComplianceRepository _repository;

  Future<DeviationAlert> call({required int alertId}) => _repository.acknowledge(alertId: alertId);
}

/// Command: → RESOLVED with mandatory resolution notes (backend rule).
class ResolveAlert {
  const ResolveAlert(this._repository);

  final ComplianceRepository _repository;

  Future<DeviationAlert> call({required int alertId, required String resolutionNotes}) {
    final notes = resolutionNotes.trim();
    if (notes.isEmpty) {
      throw const BadRequestFailure(code: 'RESOLUTION_NOTES_REQUIRED');
    }
    return _repository.resolve(alertId: alertId, resolutionNotes: notes);
  }
}

class GetEquipmentComplianceEvents {
  const GetEquipmentComplianceEvents(this._repository);

  final ComplianceRepository _repository;

  Future<List<ComplianceEvent>> call(int equipmentId) async =>
      _newestFirst(await _repository.getEquipmentEvents(equipmentId));
}

class GetBatchComplianceEvents {
  const GetBatchComplianceEvents(this._repository);

  final ComplianceRepository _repository;

  Future<List<ComplianceEvent>> call(int batchId) async =>
      _newestFirst(await _repository.getBatchEvents(batchId));
}

List<ComplianceEvent> _newestFirst(List<ComplianceEvent> events) => [...events]
  ..sort((a, b) {
    final left = a.timestamp;
    final right = b.timestamp;
    if (left == null && right == null) return b.id.compareTo(a.id);
    if (left == null) return 1;
    if (right == null) return -1;
    return right.compareTo(left);
  });
