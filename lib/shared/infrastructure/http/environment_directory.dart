import 'api_client.dart';
import 'json_utils.dart';

/// Returns the laboratory of the current session.
typedef LaboratoryIdProvider = int Function();

/// Most v1.0.0 resources hang from `/laboratories/{lab}/environments/{env}`.
/// This directory lists the environments of a laboratory once and keeps them
/// until [clear] is called, so data sources can fan out over them.
class EnvironmentDirectory {
  EnvironmentDirectory(this._client);

  final ApiClient _client;
  final Map<int, List<int>> _cache = {};

  Future<List<int>> ids(int laboratoryId) async {
    final cached = _cache[laboratoryId];
    if (cached != null) return cached;
    final data = await _client.get('/laboratories/$laboratoryId/environments');
    final ids = Json.asList(data).map((e) => Json.requireInt(e, 'id')).toList(growable: false);
    return _cache[laboratoryId] = ids;
  }

  void clear() => _cache.clear();
}
