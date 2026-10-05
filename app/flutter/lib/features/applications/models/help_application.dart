class HelpApplicationMedia {
  const HelpApplicationMedia({required this.id, required this.url, this.mimeType, this.documentType});

  final String id;
  final String url;
  final String? mimeType;
  final String? documentType;

  factory HelpApplicationMedia.fromJson(Map<String, dynamic> json) =>
      HelpApplicationMedia(
        id: json['id'] as String,
        url: json['url'] as String,
        mimeType: json['mimeType'] as String?,
        documentType: json['documentType'] as String?,
      );
}

/// Prisma Decimal values are serialized by the NestJS API as JSON strings.
/// Keep the model tolerant of both the string representation and numeric
/// values used by mocks/other API implementations.
num? _parseAmount(dynamic value) {
  if (value == null || value is num) return value as num?;
  return num.tryParse(value.toString());
}

class HelpApplication {
  const HelpApplication({
    required this.id,
    required this.type,
    required this.status,
    this.applicantName,
    this.mobileNumber,
    this.email,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.requestedAmount,
    this.overallPercentage,
    this.approvedAmount,
    this.rejectionReason,
    this.clarification,
    this.motherName,
    this.fatherName,
    this.dateOfBirth,
    this.classStandard,
    this.schoolInstituteName,
    this.accomplishments,
    this.certificatePhotoMediaId,
    this.facePhotoMediaId,
    this.facePhoto,
    this.certificatePhoto,
    this.adminNote,
    this.submittedAt,
    this.reviewedAt,
    this.media = const [],
  });

  final String id;
  final String type;
  final String? applicantName;
  final String? mobileNumber;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String status;
  final num? requestedAmount;
  final num? overallPercentage;
  final num? approvedAmount;
  final String? rejectionReason;
  final String? clarification;
  final String? motherName;
  final String? fatherName;
  final DateTime? dateOfBirth;
  final String? classStandard;
  final String? schoolInstituteName;
  final String? accomplishments;
  final String? certificatePhotoMediaId;
  final String? facePhotoMediaId;
  final HelpApplicationMedia? facePhoto;
  final HelpApplicationMedia? certificatePhoto;
  final String? adminNote;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final List<HelpApplicationMedia> media;

  factory HelpApplication.fromJson(Map<String, dynamic> json) =>
      HelpApplication(
        id: json['id'] as String,
        type: json['type'] as String,
        status: json['status'] as String,
        applicantName: json['applicantName'] as String?,
        mobileNumber: json['mobileNumber'] as String?,
        email: json['email'] as String?,
        address: json['address'] as String?,
        city: json['city'] as String?,
        state: json['state'] as String?,
        pincode: json['pincode'] as String?,
        requestedAmount: _parseAmount(json['requestedAmount']),
        overallPercentage: _parseAmount(json['overallPercentage']),
        approvedAmount: _parseAmount(json['approvedAmount']),
        rejectionReason: json['rejectionReason'] as String?,
        clarification: json['clarification'] as String?,
        motherName: json['motherName'] as String?,
        fatherName: json['fatherName'] as String?,
        dateOfBirth: DateTime.tryParse(json['dateOfBirth']?.toString() ?? ''),
        classStandard: json['classStandard'] as String?,
        schoolInstituteName: json['schoolInstituteName'] as String?,
        accomplishments: json['accomplishments'] as String?,
        certificatePhotoMediaId: json['certificatePhotoMediaId'] as String?,
        facePhotoMediaId: json['facePhotoMediaId'] as String?,
        facePhoto: json['facePhoto'] == null
            ? null
            : HelpApplicationMedia.fromJson(json['facePhoto'] as Map<String, dynamic>),
        certificatePhoto: json['certificatePhoto'] == null
            ? null
            : HelpApplicationMedia.fromJson(json['certificatePhoto'] as Map<String, dynamic>),
        adminNote: json['adminNote'] as String?,
        submittedAt: DateTime.tryParse(json['submittedAt']?.toString() ?? ''),
        reviewedAt: DateTime.tryParse(json['reviewedAt']?.toString() ?? ''),
        media: (json['media'] as List<dynamic>? ?? [])
            .map((e) => HelpApplicationMedia.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );

  String get typeLabel {
    switch (type) {
      case 'MEDICAL_HELP':
        return 'medicalHelp';
      case 'PRATIBHA_SAMMAN':
        return 'pratibhaSamman';
      default:
        return 'educationHelp';
    }
  }
}
