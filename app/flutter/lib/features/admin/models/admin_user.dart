class AdminUser {
  const AdminUser({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    required this.role,
    required this.createdAt,
  });

  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String role;
  final DateTime createdAt;

  bool get isAdmin => role == 'ADMIN';

  String get label =>
      displayName?.trim().isNotEmpty == true ? displayName! : (email ?? 'User');

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: json['id'] as String,
        email: json['email'] as String?,
        displayName: json['displayName'] as String?,
        photoUrl: json['photoUrl'] as String?,
        role: json['role'] as String? ?? 'USER',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
