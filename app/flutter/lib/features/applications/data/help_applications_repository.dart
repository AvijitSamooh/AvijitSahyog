import '../../../core/network/api_client.dart';
import '../models/help_application.dart';
import '../models/application_window.dart';

class HelpApplicationsRepository {
  HelpApplicationsRepository(this.client);

  final ApiClient client;

  Future<HelpApplication> create({
    required String type,
    required double? requestedAmount,
    required List<String> mediaIds,
    required String applicantName,
    required String mobileNumber,
    String? email,
    required String address,
    required String city,
    required String state,
    required String pincode,
    String? clarification,
  }) async {
    final trimmedClarification = clarification?.trim();
    return HelpApplication.fromJson(await client.createHelpApplication({
      'type': type,
      'applicantName': applicantName.trim(),
      'mobileNumber': mobileNumber.trim(),
      'email': ?(email?.trim().isNotEmpty == true ? email!.trim() : null),
      'address': address.trim(),
      'city': city.trim(),
      'state': state.trim(),
      'pincode': pincode.trim(),
      'requestedAmount': ?requestedAmount,
      'mediaIds': mediaIds,
      'clarification': ?(trimmedClarification?.isNotEmpty == true ? trimmedClarification : null),
    }));
  }

  Future<List<ApplicationWindow>> applicationWindows() async {
    final result = await client.getApplicationWindows();
    final windows = (result['windows'] as List<dynamic>? ?? const []);
    return windows
        .map((item) => ApplicationWindow.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<ApplicationWindow> startApplicationWindow({
    required String type,
    DateTime? startsAt,
  }) async {
    return ApplicationWindow.fromJson(
      await client.startApplicationWindow(
        type,
        startsAt: startsAt,
      ),
    );
  }

  Future<ApplicationWindow> closeApplicationWindow(String type) async {
    return ApplicationWindow.fromJson(
      await client.closeApplicationWindow(type),
    );
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
      'requestedAmount': ?requestedAmount,
    }));
  }

  Future<void> delete(String id) => client.deleteMyHelpApplication(id);

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
