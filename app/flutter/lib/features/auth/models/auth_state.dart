import 'app_user.dart';

class AuthState {
  const AuthState._({this.user, this.isLoading = false, this.errorMessage});

  const AuthState.guest() : this._();

  const AuthState.loading() : this._(isLoading: true);

  const AuthState.authenticated(AppUser user) : this._(user: user);

  const AuthState.error(String message) : this._(errorMessage: message);

  final AppUser? user;
  final bool isLoading;
  final String? errorMessage;

  bool get isAuthenticated => user != null;
}
