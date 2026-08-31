import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../models/auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(),
);

final authProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref.read(authRepositoryProvider)),
);

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(const AuthState.guest());

  final AuthRepository _repository;

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
