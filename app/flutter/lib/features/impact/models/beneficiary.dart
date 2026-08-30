class Beneficiary {
  const Beneficiary({required this.id, required this.name, required this.cause, required this.supportedYear, required this.contributionAmount, this.photoUrl, this.story, this.organisationName});
  final String id; final String name; final String cause; final int supportedYear; final double contributionAmount; final String? photoUrl; final String? story; final String? organisationName;
  factory Beneficiary.fromJson(Map<String, dynamic> json) {
    final cause = json['cause'];
    final organisation = json['organisation'];
    return Beneficiary(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      cause: cause is Map<String, dynamic> ? (cause['name'] as String? ?? cause['slug'] as String? ?? '') : json['causeName'] as String? ?? '',
      supportedYear: (json['supportedYear'] as num?)?.toInt() ?? 0,
      contributionAmount: double.tryParse(json['contributionAmount'].toString()) ?? 0,
      photoUrl: json['photoUrl'] as String?,
      story: json['story'] as String?,
      organisationName: organisation is Map<String, dynamic> ? (organisation['name'] as String? ?? organisation['slug'] as String?) : json['organisationName'] as String?,
    );
  }
}