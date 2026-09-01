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
    return AdminBeneficiary(
      id: json['id'] as String,
      name: json['name'] as String,
      supportedYear: (json['supportedYear'] as num).toInt(),
      contributionAmount: json['contributionAmount'] as num,
      causeId: json['causeId'] as String? ?? cause?['id'] as String? ?? '',
      organisationId:
          json['organisationId'] as String? ?? organisation?['id'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      photoUrl: json['photoUrl'] as String?,
      story: json['story'] as String?,
    );
  }
}
