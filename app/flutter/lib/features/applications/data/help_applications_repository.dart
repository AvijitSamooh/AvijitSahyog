import '../../../core/network/api_client.dart';
import '../models/help_application.dart';

class HelpApplicationsRepository {
  HelpApplicationsRepository(this.client);

  final ApiClient client;

  Future<HelpApplication> create({
    required String type,
    required double? requestedAmount,
    required List<String> mediaIds,
    String? clarification,
  }) async {
    return HelpApplication.fromJson(await client.createHelpApplication({
      'type': type,
      if (requestedAmount != null) 'requestedAmount': requestedAmount,
      'mediaIds': mediaIds,
      if (clarification != null && clarification.trim().isNotEmpty)
        'clarification': clarification.trim(),
    }));
  }

  Future<List<HelpApplication>> mine() async {
    final result = await client.getMyHelpApplications();
    return result.map(HelpApplication.fromJson).toList(growable: false);
  }

  Future<HelpApplication> resubmit({
    required String id,
    required String clarification,
    required List<String> mediaIds,
    double? requestedAmount,
  }) async {
    return HelpApplication.fromJson(await client.resubmitHelpApplication(id, {
      'clarification': clarification,
      'mediaIds': mediaIds,
      if (requestedAmount != null) 'requestedAmount': requestedAmount,
    }));
  }

  Future<String> uploadImage(String path) async {
    final json = await client.uploadApplicationImage(path);
    return json['id'] as String;
  }

  Future<List<Map<String, dynamic>>> adminList({String? type, String? status}) =>
      client.getAdminHelpApplications(type: type, status: status);

  Future<void> vote(String id, int score, {String? comment}) =>
      client.voteHelpApplication(id, score, comment: comment);

  Future<Map<String, dynamic>> review(String id, Map<String, dynamic> payload) =>
      client.reviewHelpApplication(id, payload);
}
