enum UserRole { user, admin }

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.photoUrl,
    this.preferredLanguage,
  });

  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final UserRole role;
  final String? preferredLanguage;

  bool get isAdmin => role == UserRole.admin;
}
