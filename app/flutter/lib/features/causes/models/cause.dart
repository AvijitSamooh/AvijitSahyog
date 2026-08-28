import 'organisation.dart';

class Cause {
  const Cause({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
    this.displayOrder = 0,
    this.organisations = const [],
  });

  final String id;
  final String slug;
  final String name;
  final String? description;
  final int displayOrder;
  final List<Organisation> organisations;

  factory Cause.fromJson(Map<String, dynamic> json) {
    return Cause(
      id: json['id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      organisations: (json['organisations'] as List<dynamic>? ?? [])
          .map((item) => Organisation.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}
