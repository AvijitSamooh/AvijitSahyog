import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../models/app_user.dart';

abstract class AuthRepository {
  Future<AppUser> signInWithGoogle();
  Future<AppUser?> restoreSession();
  Future<void> signOut();
}

class AuthNotConfiguredException implements Exception {
  const AuthNotConfiguredException();
}

class AuthDiagnosticException implements Exception {
  const AuthDiagnosticException(this.message);

  final String message;

  @override
  String toString() => message;
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    this.firebaseAuth,
    http.Client? httpClient,
    String? baseUrl,
  })  : _httpClient = httpClient ?? http.Client(),
        _baseUrl = _normalizeBaseUrl(
          baseUrl ??
              const String.fromEnvironment(
                'API_BASE_URL',
                defaultValue: 'http://localhost:3000',
              ),
        );

  final FirebaseAuth? firebaseAuth;

  FirebaseAuth get _auth => firebaseAuth ?? FirebaseAuth.instance;
  final http.Client _httpClient;
  final String _baseUrl;

  static String _normalizeBaseUrl(String value) =>
      value.endsWith('/') ? value.substring(0, value.length - 1) : value;

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      await GoogleSignIn.instance.initialize();
      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      final result = await _auth.signInWithCredential(credential);

      final user = result.user;
      if (user == null) {
        throw StateError('Firebase did not return an authenticated user.');
      }

      return await _resolveBackendUser(user);
    } on FirebaseException catch (error) {
      if (error.code == 'operation-not-allowed') {
        throw const AuthNotConfiguredException();
      }
      throw AuthDiagnosticException(
        'Firebase error: code=' + error.code + '; message=' + (error.message ?? 'none'),
      );
    } on GoogleSignInException catch (error) {
      throw AuthDiagnosticException(
        'Google Sign-In error: code=' + error.code.toString() +
        '; description=' + (error.description ?? 'none'),
      );
    } catch (error) {
      throw AuthDiagnosticException(
        'Sign-In error: ' + error.runtimeType.toString() + ': ' + error.toString(),
      );
    }
  }

  @override
  Future<AppUser?> restoreSession() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _resolveBackendUser(user);
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<AppUser> _resolveBackendUser(User firebaseUser) async {
    final token = await firebaseUser.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Unable to obtain Firebase authentication token.');
    }

    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Unable to resolve authenticated user.');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      preferredLanguage: json['preferredLanguage'] as String?,
      role: json['role'] == 'ADMIN' ? UserRole.admin : UserRole.user,
    );
  }

  void dispose() {
    _httpClient.close();
  }
}
