class HelpApplicationMedia {
  const HelpApplicationMedia({required this.id, required this.url, this.mimeType});

  final String id;
  final String url;
  final String? mimeType;

  factory HelpApplicationMedia.fromJson(Map<String, dynamic> json) =>
      HelpApplicationMedia(
        id: json['id'] as String,
        url: json['url'] as String,
        mimeType: json['mimeType'] as String?,
      );
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
    this.approvedAmount,
    this.rejectionReason,
    this.clarification,
    this.adminNote,
    this.submittedAt,
    this.reviewedAt,
    this.media = const [],
  });

  final String id;
  final String type;
  final String status;
  final String? applicantName;
  final String? mobileNumber;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final num? requestedAmount;
  final num? approvedAmount;
  final String? rejectionReason;
  final String? clarification;
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
        requestedAmount: (json['requestedAmount'] as num?),
        approvedAmount: (json['approvedAmount'] as num?),
        rejectionReason: json['rejectionReason'] as String?,
        clarification: json['clarification'] as String?,
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
