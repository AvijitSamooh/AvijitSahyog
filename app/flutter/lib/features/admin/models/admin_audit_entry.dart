class AdminAuditEntry {
  const AdminAuditEntry({
    required this.id,
    required this.action,
    required this.fromRole,
    required this.toRole,
    required this.createdAt,
    this.actorName,
    this.actorEmail,
    this.targetName,
    this.targetEmail,
  });

  final String id;
  final String action;
  final String? fromRole;
  final String? toRole;
  final DateTime createdAt;
  final String? actorName;
  final String? actorEmail;
  final String? targetName;
  final String? targetEmail;

  String get actorLabel =>
      actorName?.trim().isNotEmpty == true ? actorName! : (actorEmail ?? 'Administrator');
  String get targetLabel =>
      targetName?.trim().isNotEmpty == true ? targetName! : (targetEmail ?? 'User');

  factory AdminAuditEntry.fromJson(Map<String, dynamic> json) {
    final actor = json['actor'] as Map<String, dynamic>?;
    final target = json['targetUser'] as Map<String, dynamic>?;
    return AdminAuditEntry(
      id: json['id'] as String,
      action: json['action'] as String? ?? '',
      fromRole: json['fromRole'] as String?,
      toRole: json['toRole'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      actorName: actor?['displayName'] as String?,
      actorEmail: actor?['email'] as String?,
      targetName: target?['displayName'] as String?,
      targetEmail: target?['email'] as String?,
    );
  }
}
