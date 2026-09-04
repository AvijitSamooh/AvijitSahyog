class Beneficiary {
  const Beneficiary({
    required this.id,
    required this.name,
    required this.cause,
    required this.supportedYear,
    required this.contributionAmount,
    this.photoUrl,
    this.profileImageUrl,
    this.gallery = const [],
    this.story,
    this.organisationName,
  });

  final String id;
  final String name;
  final String cause;
  final int supportedYear;
  final double contributionAmount;
  final String? photoUrl;
  final String? profileImageUrl;
  final List<String> gallery;
  final String? story;
  final String? organisationName;

  String? get primaryImageUrl => profileImageUrl ?? photoUrl;

  factory Beneficiary.fromJson(Map<String, dynamic> json) {
    final cause = json['cause'];
    final organisation = json['organisation'];
    final profileImage = json['profileImage'];
    final gallery = json['gallery'] as List<dynamic>? ?? const [];

    return Beneficiary(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      cause: cause is Map<String, dynamic>
          ? (cause['name'] as String? ?? cause['slug'] as String? ?? '')
          : json['causeName'] as String? ?? '',
      supportedYear: (json['supportedYear'] as num?)?.toInt() ?? 0,
      contributionAmount:
          double.tryParse(json['contributionAmount'].toString()) ?? 0,
      photoUrl: json['photoUrl'] as String?,
      profileImageUrl:
          profileImage is Map<String, dynamic> ? profileImage['url'] as String? : null,
      gallery: gallery
          .map((item) => item is Map<String, dynamic> ? item['url'] as String? : null)
          .whereType<String>()
          .toList(growable: false),
      story: json['story'] as String?,
      organisationName: organisation is Map<String, dynamic>
          ? (organisation['name'] as String? ?? organisation['slug'] as String?)
          : json['organisationName'] as String?,
    );
  }
}
