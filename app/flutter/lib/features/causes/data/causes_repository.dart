import '../../../core/network/api_client.dart';
import '../models/cause.dart';

class CausesRepository {
  CausesRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Cause>> getCauses(String languageCode) async {
    final data = await _apiClient.getCauses(languageCode);
    return data
        .map((item) => Cause.fromJson(item))
        .toList(growable: false);
  }

  Future<Cause> getCause(String slug, String languageCode) async {
    final data = await _apiClient.getCause(slug, languageCode);
    return Cause.fromJson(data);
  }
}
