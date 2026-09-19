class AdminOrganisationTranslation {
  const AdminOrganisationTranslation({
    required this.languageCode,
    required this.name,
    this.description,
  });
  final String languageCode;
  final String name;
  final String? description;

  factory AdminOrganisationTranslation.fromJson(Map<String, dynamic> json) {
    final language = json['language'] as Map<String, dynamic>?;
    return AdminOrganisationTranslation(
      languageCode: language?['code'] as String? ??
          json['languageCode'] as String? ??
          '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
    );
  }
}

class AdminOrganisation {
  const AdminOrganisation({
    required this.id,
    required this.slug,
    required this.isActive,
    required this.displayOrder,
    required this.translations,
    required this.causeIds,
    this.websiteUrl,
    this.phone,
    this.mobileNumber,
    this.email,
    this.address,
    this.city,
    this.state,
    this.country,
  });

  final String id;
  final String slug;
  final bool isActive;
  final int displayOrder;
  final List<AdminOrganisationTranslation> translations;
  final List<String> causeIds;
  final String? websiteUrl;
  final String? phone;
  final String? mobileNumber;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final String? country;

  factory AdminOrganisation.fromJson(Map<String, dynamic> json) {
    final causes = json['causes'] as List<dynamic>? ?? [];
    return AdminOrganisation(
      id: json['id'] as String,
      slug: json['slug'] as String,
      isActive: json['isActive'] as bool? ?? true,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      translations: (json['translations'] as List<dynamic>? ?? [])
          .map((item) => AdminOrganisationTranslation.fromJson(
                item as Map<String, dynamic>,
              ))
          .toList(growable: false),
      causeIds: causes
          .map((item) => ((item as Map<String, dynamic>)['cause']
              as Map<String, dynamic>)['id'] as String)
          .toList(growable: false),
      websiteUrl: json['websiteUrl'] as String?,
      phone: json['phone'] as String?,
      mobileNumber: json['mobileNumber'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
    );
  }

  String displayName(String languageCode) {
    for (final translation in translations) {
      if (translation.languageCode == languageCode) return translation.name;
    }
    for (final translation in translations) {
      if (translation.languageCode == 'en') return translation.name;
    }
    return translations.isEmpty ? slug : translations.first.name;
  }
}
