import 'app_user.dart';

class AuthState {
  const AuthState._({this.user, this.isLoading = false, this.errorMessage, this.errorDetails});

  const AuthState.guest() : this._();

  const AuthState.loading() : this._(isLoading: true);

  const AuthState.authenticated(AppUser user) : this._(user: user);

  const AuthState.error(String message, {String? details}) : this._(errorMessage: message, errorDetails: details);

  final AppUser? user;
  final bool isLoading;
  final String? errorMessage;
  final String? errorDetails;

  bool get isAuthenticated => user != null;
}
