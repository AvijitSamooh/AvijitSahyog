class AdminCauseTranslation {
  const AdminCauseTranslation({
    required this.languageCode,
    required this.name,
    this.description,
  });

  final String languageCode;
  final String name;
  final String? description;

  factory AdminCauseTranslation.fromJson(Map<String, dynamic> json) {
    final language = json['language'] as Map<String, dynamic>?;
    return AdminCauseTranslation(
      languageCode:
          language?['code'] as String? ?? json['languageCode'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'languageCode': languageCode,
        'name': name,
        if (description?.trim().isNotEmpty ?? false) 'description': description,
      };
}

class AdminCause {
  const AdminCause({
    required this.id,
    required this.slug,
    required this.isActive,
    required this.displayOrder,
    required this.translations,
    this.parentId,
    this.children = const [],
  });

  final String id;
  final String slug;
  final bool isActive;
  final int displayOrder;
  final List<AdminCauseTranslation> translations;
  final String? parentId;
  final List<AdminCause> children;

  factory AdminCause.fromJson(Map<String, dynamic> json) {
    return AdminCause(
      id: json['id'] as String,
      slug: json['slug'] as String,
      isActive: json['isActive'] as bool? ?? true,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      parentId: json['parentId'] as String?,
      children: (json['children'] as List<dynamic>? ?? [])
          .map((item) => AdminCause.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      translations: (json['translations'] as List<dynamic>? ?? [])
          .map((item) => AdminCauseTranslation.fromJson(
                item as Map<String, dynamic>,
              ))
          .toList(growable: false),
    );
  }

  String get displayName =>
      translations.where((item) => item.languageCode == 'en').firstOrNull?.name ??
      (translations.isEmpty ? slug : translations.first.name);
}

extension FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    for (final item in this) {
      return item;
    }
    return null;
  }
}
