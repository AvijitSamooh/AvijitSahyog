import '../models/app_user.dart';

abstract class AuthRepository {
  Future<AppUser> signInWithGoogle();
  Future<void> signOut();
}

class AuthNotConfiguredException implements Exception {
  const AuthNotConfiguredException();
}

class FirebaseAuthRepository implements AuthRepository {
  @override
  Future<AppUser> signInWithGoogle() {
    throw const AuthNotConfiguredException();
  }

  @override
  Future<void> signOut() async {}
}
