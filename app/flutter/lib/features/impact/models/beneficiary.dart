class Beneficiary {
  const Beneficiary({
    required this.id,
    required this.name,
    required this.cause,
    required this.supportedYear,
    required this.contributionAmount,
    this.photoUrl,
    this.story,
    this.organisationName,
  });
  final String id;
  final String name;
  final String cause;
  final int supportedYear;
  final double contributionAmount;
  final String? photoUrl;
  final String? story;
  final String? organisationName;

  factory Beneficiary.fromJson(Map<String,dynamic> json) => Beneficiary(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    cause: json['causeName'] as String? ?? json['cause'] as String? ?? '',
    supportedYear: (json['supportedYear'] as num?)?.toInt() ?? 0,
    contributionAmount: (json['contributionAmount'] as num?)?.toDouble() ?? 0,
    photoUrl: json['photoUrl'] as String?,
    story: json['story'] as String?,
    organisationName: json['organisationName'] as String?,
  );
}