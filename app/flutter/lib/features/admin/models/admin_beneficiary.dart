class AdminBeneficiary {
  const AdminBeneficiary({
    required this.id,
    required this.name,
    required this.supportedYear,
    required this.contributionAmount,
    required this.causeId,
    required this.isActive,
    required this.displayOrder,
    this.organisationId,
    this.photoUrl,
    this.story,
  });

  final String id;
  final String name;
  final int supportedYear;
  final num contributionAmount;
  final String causeId;
  final String? organisationId;
  final bool isActive;
  final int displayOrder;
  final String? photoUrl;
  final String? story;

  factory AdminBeneficiary.fromJson(Map<String, dynamic> json) {
    final cause = json['cause'] as Map<String, dynamic>?;
    final organisation = json['organisation'] as Map<String, dynamic>?;
    final supportedYear = _asNum(json['supportedYear']);
    final contributionAmount = _asNum(json['contributionAmount']);
    if (supportedYear == null || contributionAmount == null) {
      throw const FormatException('Beneficiary response contains invalid numeric values.');
    }
    return AdminBeneficiary(
      id: json['id'] as String,
      name: json['name'] as String,
      supportedYear: supportedYear.toInt(),
      contributionAmount: contributionAmount,
      causeId: json['causeId'] as String? ?? cause?['id'] as String? ?? '',
      organisationId:
          json['organisationId'] as String? ?? organisation?['id'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      displayOrder: (_asNum(json['displayOrder']) ?? 0).toInt(),
      photoUrl: json['photoUrl'] as String?,
      story: json['story'] as String?,
    );
  }

  static num? _asNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }
}
