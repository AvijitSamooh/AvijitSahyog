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

  static Future<void>? _googleSignInInitialization;

  final FirebaseAuth? firebaseAuth;

  FirebaseAuth get _auth => firebaseAuth ?? FirebaseAuth.instance;
  final http.Client _httpClient;
  final String _baseUrl;

  Future<void> _initializeGoogleSignIn() {
    return _googleSignInInitialization ??= GoogleSignIn.instance.initialize();
  }

  static String _normalizeBaseUrl(String value) =>
      value.endsWith('/') ? value.substring(0, value.length - 1) : value;

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      await _initializeGoogleSignIn();
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
        'Firebase error: code=${error.code}; message=${error.message ?? 'none'}',
      );
    } on GoogleSignInException catch (error) {
      throw AuthDiagnosticException(
        'Google Sign-In error: code=${error.code}; '
        'description=${error.description ?? 'none'}',
      );
    } on AuthDiagnosticException {
      rethrow;
    } catch (error) {
      throw AuthDiagnosticException(
        'Sign-In error: ${error.runtimeType}: $error',
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
      throw const AuthDiagnosticException(
        'Backend auth failed: Firebase returned an empty ID token.',
      );
    }

    final endpoint = '$_baseUrl/auth/me';
    late http.Response response;
    try {
      response = await _httpClient.get(
        Uri.parse(endpoint),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (error) {
      throw AuthDiagnosticException(
        'Backend request failed: endpoint=$endpoint; '
        'error=${error.runtimeType}: $error',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = response.body.length > 1000
          ? '${response.body.substring(0, 1000)}…'
          : response.body;
      throw AuthDiagnosticException(
        'Backend auth failed: endpoint=$endpoint; '
        'status=${response.statusCode}; '
        'body=$body',
      );
    }

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return AppUser(
        id: json['id'] as String,
        email: json['email'] as String?,
        displayName: json['displayName'] as String?,
        photoUrl: json['photoUrl'] as String?,
        preferredLanguage: json['preferredLanguage'] as String?,
        role: json['role'] == 'ADMIN' ? UserRole.admin : UserRole.user,
      );
    } catch (error) {
      throw AuthDiagnosticException(
        'Backend response parse failed: endpoint=$endpoint; '
        'status=${response.statusCode}; '
        'error=${error.runtimeType}: $error',
      );
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
