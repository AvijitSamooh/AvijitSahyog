import 'package:flutter_test/flutter_test.dart';

import 'package:avijit_sahyog/features/auth/data/auth_repository.dart';
import 'package:avijit_sahyog/features/auth/models/app_user.dart';
import 'package:avijit_sahyog/features/auth/providers/auth_providers.dart';

void main() {
  const user = AppUser(
    id: 'user-1',
    email: 'user@example.com',
    displayName: 'Test User',
    role: UserRole.user,
  );

  test('restores an existing authenticated session', () async {
    final controller = AuthController(_FakeAuthRepository(restoredUser: user));

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.user, user);
    expect(controller.state.isAuthenticated, isTrue);
  });

  test('starts as guest when no Firebase session exists', () async {
    final controller = AuthController(_FakeAuthRepository());

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.isAuthenticated, isFalse);
    expect(controller.state.isLoading, isFalse);
  });

  test('signs in and exposes the resolved backend user', () async {
    final controller = AuthController(_FakeAuthRepository(signInUser: user));

    await Future<void>.delayed(Duration.zero);
    await controller.signInWithGoogle();

    expect(controller.state.user, user);
    expect(controller.state.isAuthenticated, isTrue);
  });

  test('returns to guest state after sign out', () async {
    final controller = AuthController(
      _FakeAuthRepository(restoredUser: user),
    );

    await Future<void>.delayed(Duration.zero);
    await controller.signOut();

    expect(controller.state.isAuthenticated, isFalse);
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.restoredUser, this.signInUser});

  final AppUser? restoredUser;
  final AppUser? signInUser;

  @override
  Future<AppUser?> restoreSession() async => restoredUser;

  @override
  Future<AppUser> signInWithGoogle() async {
    return signInUser ?? (throw StateError('No sign-in user configured.'));
  }

  @override
  Future<void> signOut() async {}
}
