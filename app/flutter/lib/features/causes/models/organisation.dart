class Organisation {
  const Organisation({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
    this.logoUrl,
    this.gallery = const [],
    this.websiteUrl,
    this.phone,
    this.mobileNumber,
    this.email,
    this.address,
    this.city,
    this.state,
    this.country,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String slug;
  final String name;
  final String? description;
  final String? logoUrl;
  final List<String> gallery;
  final String? websiteUrl;
  final String? phone;
  final String? mobileNumber;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final double? latitude;
  final double? longitude;

  factory Organisation.fromJson(Map<String, dynamic> json) {
    return Organisation(
      id: json['id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      logoUrl: json['logoUrl'] as String?,
      gallery: ((json['gallery'] as List<dynamic>?) ?? const [])
          .map((item) => item is Map<String, dynamic> ? item['url'] as String? : null)
          .whereType<String>()
          .toList(growable: false),
      websiteUrl: json['websiteUrl'] as String?,
      phone: json['phone'] as String?,
      mobileNumber: json['mobileNumber'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}
