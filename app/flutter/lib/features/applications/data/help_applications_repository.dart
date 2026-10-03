import '../../../core/network/api_client.dart';
import '../models/help_application.dart';
import '../models/application_window.dart';
import '../models/application_rule.dart';

class HelpApplicationsRepository {
  HelpApplicationsRepository(this.client);

  final ApiClient client;

  Future<HelpApplication> create({
    required String type,
    required double? requestedAmount,
    required double overallPercentage,
    required List<String> mediaIds,
    required String applicantName,
    required String mobileNumber,
    String? email,
    required String address,
    required String city,
    required String state,
    required String pincode,
    String? clarification,
    String? motherName,
    String? fatherName,
    DateTime? dateOfBirth,
    String? classStandard,
    String? schoolInstituteName,
    String? accomplishments,
    String? certificatePhotoMediaId,
    required String facePhotoMediaId,
    required List<String> acceptedRuleIds,
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
      'overallPercentage': overallPercentage,
      'mediaIds': mediaIds,
      'acceptedRuleIds': acceptedRuleIds,
      'clarification': ?(trimmedClarification?.isNotEmpty == true ? trimmedClarification : null),
      'motherName': ?(motherName?.trim().isNotEmpty == true ? motherName!.trim() : null),
      'fatherName': ?(fatherName?.trim().isNotEmpty == true ? fatherName!.trim() : null),
      'dateOfBirth': ?dateOfBirth?.toUtc().toIso8601String(),
      'classStandard': ?(classStandard?.trim().isNotEmpty == true ? classStandard!.trim() : null),
      'schoolInstituteName': ?(schoolInstituteName?.trim().isNotEmpty == true ? schoolInstituteName!.trim() : null),
      'accomplishments': ?(accomplishments?.trim().isNotEmpty == true ? accomplishments!.trim() : null),
      'certificatePhotoMediaId': ?certificatePhotoMediaId,
      'facePhotoMediaId': facePhotoMediaId,
    }));
  }

  Future<List<ApplicationRule>> applicationRules(String type, String languageCode) async {
    final result = await client.getApplicationRules(type, languageCode);
    return result.map(ApplicationRule.fromJson).toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> adminApplicationRules(String type) => client.getAdminApplicationRules(type);

  Future<Map<String, dynamic>> createAdminApplicationRule(Map<String, dynamic> payload) => client.createAdminApplicationRule(payload);

  Future<Map<String, dynamic>> updateAdminApplicationRule(String id, Map<String, dynamic> payload) => client.updateAdminApplicationRule(id, payload);

  Future<void> deleteAdminApplicationRule(String id) => client.deleteAdminApplicationRule(id);

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
    DateTime? registrationEndsAt,
    DateTime? eventAt,
  }) async {
    return ApplicationWindow.fromJson(
      await client.startApplicationWindow(
        type,
        startsAt: startsAt,
        registrationEndsAt: registrationEndsAt,
        eventAt: eventAt,
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
    required List<String> acceptedRuleIds,
    required double overallPercentage,
    double? requestedAmount,
    String? motherName,
    String? fatherName,
    DateTime? dateOfBirth,
    String? classStandard,
    String? schoolInstituteName,
    String? accomplishments,
    String? certificatePhotoMediaId,
  }) async {
    return HelpApplication.fromJson(await client.resubmitHelpApplication(id, {
      'clarification': clarification,
      'mediaIds': mediaIds,
      'acceptedRuleIds': acceptedRuleIds,
      'requestedAmount': ?requestedAmount,
      'overallPercentage': overallPercentage,
      'motherName': ?motherName,
      'fatherName': ?fatherName,
      'dateOfBirth': ?dateOfBirth?.toUtc().toIso8601String(),
      'classStandard': ?classStandard,
      'schoolInstituteName': ?schoolInstituteName,
      'accomplishments': ?accomplishments,
      'certificatePhotoMediaId': ?certificatePhotoMediaId,
    }));
  }

  Future<void> delete(String id) => client.deleteMyHelpApplication(id);

  Future<HelpApplication> update({required String id, required String type, required String applicantName, required String mobileNumber, String? email, required String address, required String city, required String state, required String pincode, required double overallPercentage, double? requestedAmount, String? clarification, String? motherName, String? fatherName, DateTime? dateOfBirth, String? classStandard, String? schoolInstituteName, String? accomplishments, String? certificatePhotoMediaId, required String facePhotoMediaId, required List<String> mediaIds, required List<String> acceptedRuleIds}) async {
    return HelpApplication.fromJson(await client.updateMyHelpApplication(id, {
      'applicantName': applicantName.trim(),
      'mobileNumber': mobileNumber.trim(),
      'email': ?(email?.trim().isNotEmpty == true ? email!.trim() : null),
      'address': address.trim(),
      'city': city.trim(),
      'state': state.trim(),
      'pincode': pincode.trim(),
      'requestedAmount': ?requestedAmount,
      'overallPercentage': overallPercentage,
      'clarification': ?(clarification?.trim().isNotEmpty == true ? clarification!.trim() : null),
      'motherName': ?(motherName?.trim().isNotEmpty == true ? motherName!.trim() : null),
      'fatherName': ?(fatherName?.trim().isNotEmpty == true ? fatherName!.trim() : null),
      'dateOfBirth': ?dateOfBirth?.toUtc().toIso8601String(),
      'classStandard': ?(classStandard?.trim().isNotEmpty == true ? classStandard!.trim() : null),
      'schoolInstituteName': ?(schoolInstituteName?.trim().isNotEmpty == true ? schoolInstituteName!.trim() : null),
      'accomplishments': ?(accomplishments?.trim().isNotEmpty == true ? accomplishments!.trim() : null),
      'certificatePhotoMediaId': ?certificatePhotoMediaId,
      'facePhotoMediaId': facePhotoMediaId,
      'mediaIds': mediaIds,
      'acceptedRuleIds': acceptedRuleIds,
    }));
  }

  Future<void> deleteImage(String id) => client.deleteApplicationImage(id);

  Future<String> uploadImage(String path) async {
    final json = await client.uploadApplicationImage(path);
    return json['id'] as String;
  }

  Future<Map<String, dynamic>> adminSummary({String? type}) =>
      client.getAdminApplicationSummary(type: type);

  Future<List<Map<String, dynamic>>> adminList({String? type, String? status}) =>
      client.getAdminHelpApplications(type: type, status: status);

  Future<List<Map<String, dynamic>>> photoManifest({String? type, String? status}) =>
      client.getAdminApplicationPhotoManifest(type: type, status: status);

  Future<Map<String, dynamic>> createCertificatePhotoExport({String? type, String? status}) =>
      client.createCertificatePhotoExport(type: type, status: status);

  Future<void> vote(String id, int score, {String? comment}) =>
      client.voteHelpApplication(id, score, comment: comment);

  Future<Map<String, dynamic>> review(String id, Map<String, dynamic> payload) =>
      client.reviewHelpApplication(id, payload);
}
