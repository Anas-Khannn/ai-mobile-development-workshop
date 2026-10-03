import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/app_scope.dart';
import 'data/auth_service.dart';
import 'data/google_auth.dart';
import 'data/models.dart';
import 'data/quiz_store.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/navigation.dart';
import 'screens/splash_screen.dart';

void main() {
  // No awaiting before runApp: the animated splash must draw at once, even
  // if on-device storage is slow to answer.
  runApp(const StudyyBuddyBootstrap());
}

/// Plays the splash while storage loads, then hands over to [StudyyBuddyApp].
class StudyyBuddyBootstrap extends StatefulWidget {
  const StudyyBuddyBootstrap({super.key});

  @override
  State<StudyyBuddyBootstrap> createState() => _StudyyBuddyBootstrapState();
}

class _StudyyBuddyBootstrapState extends State<StudyyBuddyBootstrap> {
  final GoogleAuthClient _google = GoogleSignInClient();
  AuthService? _auth;
  QuizStore? _quizzes;
  bool _splashDone = false;
  bool _storageFailed = false;

  @override
  void initState() {
    super.initState();
    _loadStorage();
  }

  Future<void> _loadStorage() async {
    setState(() => _storageFailed = false);
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      setState(() {
        _auth = AuthService(prefs);
        _quizzes = QuizStore(prefs);
      });
    } on Object catch (error) {
      debugPrint('Could not open on-device storage: $error');
      if (mounted) setState(() => _storageFailed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthService? auth = _auth;
    final QuizStore? quizzes = _quizzes;
    final Widget child;
    if (_splashDone && auth != null && quizzes != null) {
      final AppUser? user = auth.currentUser;
      child = StudyyBuddyApp(
        key: const ValueKey<String>('app'),
        auth: auth,
        quizzes: quizzes,
        google: _google,
        home: user != null
            ? homeFor(user)
            : auth.hasAccounts
            ? const LoginScreen()
            : const SignUpScreen(),
      );
    } else {
      child = MaterialApp(
        key: const ValueKey<String>('splash'),
        title: 'Studyy Buddy',
        debugShowCheckedModeBanner: false,
        theme: StudyyBuddyApp.theme(Brightness.light),
        darkTheme: StudyyBuddyApp.theme(Brightness.dark),
        home: _splashDone && _storageFailed
            ? _StorageErrorScreen(onRetry: _loadStorage)
            : SplashScreen(
                onFinished: () => setState(() => _splashDone = true),
              ),
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      layoutBuilder: (Widget? current, List<Widget> previous) => Stack(
        alignment: Alignment.center,
        children: <Widget>[...previous, ?current],
      ),
      child: child,
    );
  }
}

class _StorageErrorScreen extends StatelessWidget {
  const _StorageErrorScreen({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.sd_storage_outlined, size: 56),
                const SizedBox(height: 16),
                const Text(
                  'Could not open app storage',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The device is busy. Please try again.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// App + theme (Material 3, orange, light and dark)
// ---------------------------------------------------------------------------

class StudyyBuddyApp extends StatelessWidget {
  const StudyyBuddyApp({
    super.key,
    required this.auth,
    required this.quizzes,
    required this.google,
    this.home = const SplashScreen(),
  });

  final AuthService auth;
  final QuizStore quizzes;
  final GoogleAuthClient google;

  /// The first screen; tests can skip the splash with this.
  final Widget home;

  static const Color _seed = Color(0xFFFF6D00);

  static ThemeData theme(Brightness brightness) {
    ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      // Fidelity keeps primary close to the brand orange instead of brown.
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      brightness: brightness,
    );
    // Tertiary marks correct answers and passing scores, so make it green.
    final ColorScheme success = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E7D32),
      brightness: brightness,
    );
    scheme = scheme.copyWith(
      tertiary: success.primary,
      onTertiary: success.onPrimary,
      tertiaryContainer: success.primaryContainer,
      onTertiaryContainer: success.onPrimaryContainer,
    );

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      auth: auth,
      quizzes: quizzes,
      google: google,
      child: MaterialApp(
        title: 'Studyy Buddy',
        debugShowCheckedModeBanner: false,
        theme: theme(Brightness.light),
        darkTheme: theme(Brightness.dark),
        home: home,
      ),
    );
  }
}
