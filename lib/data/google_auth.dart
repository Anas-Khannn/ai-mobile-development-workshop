import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// The parts of a Google account the app needs.
class GoogleProfile {
  const GoogleProfile({
    required this.id,
    required this.email,
    required this.name,
  });

  final String id;
  final String email;
  final String name;
}

class GoogleAuthException implements Exception {
  const GoogleAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Seam over Google sign-in so widget tests can use a fake.
abstract class GoogleAuthClient {
  /// Returns null when the user closes the account picker.
  Future<GoogleProfile?> signIn();

  Future<void> signOut();
}

/// Real Google sign-in through `package:google_sign_in`.
///
/// Android needs the OAuth *web* client ID from Google Cloud, passed at build
/// time: `flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=<id>`. iOS also
/// takes `GOOGLE_CLIENT_ID`. See the README for the full setup.
class GoogleSignInClient implements GoogleAuthClient {
  static const String _clientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
  static const String _serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  Future<void>? _initialization;

  @override
  Future<GoogleProfile?> signIn() async {
    final GoogleSignIn google = GoogleSignIn.instance;
    try {
      await (_initialization ??= google.initialize(
        clientId: _clientId.isEmpty ? null : _clientId,
        serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
      ));
      if (!google.supportsAuthenticate()) {
        throw const GoogleAuthException(
          'Google sign-in is available in the Android and iOS apps.',
        );
      }
      final GoogleSignInAccount account = await google.authenticate();
      return GoogleProfile(
        id: account.id,
        email: account.email,
        name: account.displayName ?? '',
      );
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled ||
          error.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      debugPrint('Google sign-in failed: ${error.code} ${error.description}');
      throw GoogleAuthException(
        error.code == GoogleSignInExceptionCode.clientConfigurationError
            ? 'Google sign-in is not configured for this build yet.'
            : 'Google sign-in failed. Please try again.',
      );
    } on GoogleAuthException {
      rethrow;
    } on Object catch (error) {
      // Desktop has no Google sign-in plugin, and a missing client ID fails
      // during initialize(); either way the user gets a readable message.
      _initialization = null;
      debugPrint('Google sign-in unavailable: $error');
      throw const GoogleAuthException(
        'Google sign-in is not available on this device.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    if (_initialization == null) {
      return;
    }
    try {
      await GoogleSignIn.instance.signOut();
    } on Object catch (error) {
      debugPrint('Google sign-out failed: $error');
    }
  }
}
