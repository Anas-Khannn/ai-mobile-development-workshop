import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'google_auth.dart';
import 'models.dart';

/// A user-facing auth failure; [message] is safe to show in the UI.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Accounts and the signed-in session, stored on the device.
///
/// Passwords are never stored: each email account keeps a random salt and the
/// SHA-256 of salt + password.
class AuthService extends ChangeNotifier {
  AuthService(this._prefs) {
    _users = _readUsers();
    final String? sessionId = _prefs.getString(_sessionKey);
    _currentUser = _users.where((AppUser u) => u.id == sessionId).firstOrNull;
  }

  static const String _usersKey = 'auth.users';
  static const String _sessionKey = 'auth.session';
  static const int minPasswordLength = 6;

  final SharedPreferences _prefs;
  final Random _random = Random.secure();

  late List<AppUser> _users;
  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;
  bool get hasAccounts => _users.isNotEmpty;

  AppUser? findByEmail(String email) {
    final String key = _normalize(email);
    return _users.where((AppUser u) => u.email == key).firstOrNull;
  }

  /// Creates an email account. It does not sign in: the user logs in next.
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    if (findByEmail(email) != null) {
      throw const AuthException('An account with this email already exists.');
    }
    final String salt = _newSalt();
    final AppUser user = AppUser(
      id: _newId(),
      name: name.trim(),
      email: _normalize(email),
      role: role,
      provider: AuthProvider.email,
      salt: salt,
      passwordHash: _hash(password, salt),
    );
    _users = <AppUser>[..._users, user];
    await _writeUsers();
    notifyListeners();
    return user;
  }

  Future<AppUser> logIn({
    required String email,
    required String password,
  }) async {
    final AppUser? user = findByEmail(email);
    if (user == null) {
      throw const AuthException(
        'No account found for this email. Sign up first.',
      );
    }
    if (!user.hasPassword) {
      throw const AuthException(
        'This account uses Google. Tap "Continue with Google" instead.',
      );
    }
    if (_hash(password, user.salt!) != user.passwordHash) {
      throw const AuthException('Incorrect password. Please try again.');
    }
    await _startSession(user);
    return user;
  }

  /// Signs in an existing account for this Google profile, or creates one when
  /// [role] is given. Returns null when the account is new and needs a role.
  Future<AppUser?> signInWithGoogle(
    GoogleProfile profile, {
    UserRole? role,
  }) async {
    AppUser? user = findByEmail(profile.email);
    if (user == null) {
      if (role == null) {
        return null;
      }
      user = AppUser(
        id: _newId(),
        name: profile.name.trim().isEmpty
            ? profile.email.split('@').first
            : profile.name.trim(),
        email: _normalize(profile.email),
        role: role,
        provider: AuthProvider.google,
      );
      _users = <AppUser>[..._users, user];
      await _writeUsers();
    }
    await _startSession(user);
    return user;
  }

  /// Sets a new password for an existing email account.
  Future<void> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final AppUser? user = findByEmail(email);
    if (user == null) {
      throw const AuthException('No account found for this email.');
    }
    final String salt = _newSalt();
    final AppUser updated = user.copyWith(
      salt: salt,
      passwordHash: _hash(newPassword, salt),
    );
    _users = <AppUser>[
      for (final AppUser u in _users) u.id == user.id ? updated : u,
    ];
    await _writeUsers();
    notifyListeners();
  }

  Future<void> logOut() async {
    _currentUser = null;
    await _prefs.remove(_sessionKey);
    notifyListeners();
  }

  Future<void> _startSession(AppUser user) async {
    _currentUser = user;
    await _prefs.setString(_sessionKey, user.id);
    notifyListeners();
  }

  List<AppUser> _readUsers() {
    final String? raw = _prefs.getString(_usersKey);
    if (raw == null) {
      return <AppUser>[];
    }
    try {
      return <AppUser>[
        for (final dynamic u in jsonDecode(raw) as List<dynamic>)
          AppUser.fromJson(u as Map<String, dynamic>),
      ];
    } on Object catch (error) {
      debugPrint('Ignoring unreadable user list: $error');
      return <AppUser>[];
    }
  }

  Future<void> _writeUsers() => _prefs.setString(
    _usersKey,
    jsonEncode(<Map<String, dynamic>>[
      for (final AppUser u in _users) u.toJson(),
    ]),
  );

  static String _normalize(String email) => email.trim().toLowerCase();

  static String _hash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  String _newSalt() =>
      base64Url.encode(List<int>.generate(16, (_) => _random.nextInt(256)));

  String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 32)}';
}
