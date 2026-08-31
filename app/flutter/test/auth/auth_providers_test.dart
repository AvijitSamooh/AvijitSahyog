import 'package:flutter_test/flutter_test.dart';

import 'package:avijit_sahyog/features/auth/data/auth_repository.dart';
import 'package:avijit_sahyog/features/auth/models/app_user.dart';
import 'package:avijit_sahyog/features/auth/models/auth_state.dart';
import 'package:avijit_sahyog/features/auth/providers/auth_providers.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.user);

  final AppUser user;
  bool signedOut = false;

  @override
  Future<AppUser> signInWithGoogle() async => user;

  @override
  Future<void> signOut() async {
    signedOut = true;
  }
}

void main() {
  test('auth controller transitions from guest to authenticated user', () async {
    final repository = _FakeAuthRepository(
      const AppUser(
        id: 'user-1',
        email: 'user@example.com',
        displayName: 'Test User',
        role: UserRole.user,
      ),
    );
    final controller = AuthController(repository);

    expect(controller.state.isAuthenticated, isFalse);
    await controller.signInWithGoogle();
    expect(controller.state.isAuthenticated, isTrue);
    expect(controller.state.user?.email, 'user@example.com');
  });

  test('auth controller returns to guest on logout', () async {
    final repository = _FakeAuthRepository(
      const AppUser(
        id: 'admin-1',
        email: 'admin@example.com',
        displayName: 'Admin',
        role: UserRole.admin,
      ),
    );
    final controller = AuthController(repository);

    await controller.signInWithGoogle();
    await controller.signOut();

    expect(repository.signedOut, isTrue);
    expect(controller.state, isA<AuthState>());
    expect(controller.state.isAuthenticated, isFalse);
  });
}
