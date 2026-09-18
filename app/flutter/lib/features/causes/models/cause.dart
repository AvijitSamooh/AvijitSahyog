import 'organisation.dart';

class Cause {
  const Cause({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
    this.displayOrder = 0,
    this.parentId,
    this.children = const [],
    this.organisations = const [],
  });

  final String id;
  final String slug;
  final String name;
  final String? description;
  final int displayOrder;
  final String? parentId;
  final List<Cause> children;
  final List<Organisation> organisations;

  bool get isParent => children.isNotEmpty;
  bool get isLeaf => children.isEmpty;

  Iterable<Cause> get leafCauses sync* {
    if (children.isEmpty) {
      yield this;
      return;
    }
    for (final child in children) {
      yield* child.leafCauses;
    }
  }

  factory Cause.fromJson(Map<String, dynamic> json) {
    return Cause(
      id: json['id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      parentId: json['parentId'] as String?,
      children: (json['children'] as List<dynamic>? ?? [])
          .map((item) => Cause.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      organisations: (json['organisations'] as List<dynamic>? ?? [])
          .map((item) => Organisation.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}
