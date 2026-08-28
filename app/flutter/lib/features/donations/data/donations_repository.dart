import '../../../core/network/api_client.dart';
import '../models/create_donation.dart';

class DonationsRepository {
  DonationsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> createDonation(CreateDonation input) {
    return _apiClient.createDonation(input.toJson());
  }
}
