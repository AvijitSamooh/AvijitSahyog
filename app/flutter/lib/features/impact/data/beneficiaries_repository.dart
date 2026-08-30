import '../../../core/network/api_client.dart';
import '../models/beneficiary.dart';

class BeneficiariesRepository {
  BeneficiariesRepository(this._api);
  final ApiClient _api;

  Future<List<Beneficiary>> getBeneficiaries({
    String? search,
    String? sort,
  }) async {
    final data = await _api.getBeneficiaries(search: search, sort: sort);
    return data.map(Beneficiary.fromJson).toList(growable: false);
  }
}
