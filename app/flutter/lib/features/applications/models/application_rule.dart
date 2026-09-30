class ApplicationRule {
  const ApplicationRule({
    required this.id,
    required this.type,
    required this.displayOrder,
    required this.text,
  });

  final String id;
  final String type;
  final int displayOrder;
  final String text;

  factory ApplicationRule.fromJson(Map<String, dynamic> json) => ApplicationRule(
    id: json['id'] as String,
    type: json['type'] as String? ?? '',
    displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
    text: json['text'] as String? ?? '',
  );
}
