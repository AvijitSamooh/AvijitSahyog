import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../models/auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) {
    final repository = FirebaseAuthRepository();
    ref.onDispose(repository.dispose);
    return repository;
  },
);

final authProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref.read(authRepositoryProvider)),
);

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(const AuthState.loading()) {
    _restoreSession();
  }

  final AuthRepository _repository;

  Future<void> _restoreSession() async {
    try {
      final user = await _repository.restoreSession();
      if (!mounted) return;
      state = user == null
          ? const AuthState.guest()
          : AuthState.authenticated(user);
    } catch (_) {
      if (mounted) state = const AuthState.guest();
    }
  }

  Future<void> refreshSession() async {
    try {
      final user = await _repository.refreshSession();
      if (!mounted || user == null) return;
      state = AuthState.authenticated(user);
    } catch (_) {
      // Keep the current authenticated state when a background refresh fails.
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AuthState.loading();
    try {
      state = AuthState.authenticated(await _repository.signInWithGoogle());
    } on AuthNotConfiguredException {
      state = const AuthState.error('authNotConfigured');
    } catch (_) {
      state = const AuthState.error('authSignInFailed');
    }
  }

  Future<void> signOut() async {
    state = const AuthState.loading();
    try {
      await _repository.signOut();
      state = const AuthState.guest();
    } catch (_) {
      state = const AuthState.error('authSignOutFailed');
    }
  }
}
