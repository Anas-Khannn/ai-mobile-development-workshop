import 'package:flutter/widgets.dart';

import 'auth_service.dart';
import 'google_auth.dart';
import 'quiz_store.dart';

/// Hands the app's services to every screen below it.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.auth,
    required this.quizzes,
    required this.google,
    required super.child,
  });

  final AuthService auth;
  final QuizStore quizzes;
  final GoogleAuthClient google;

  static AppScope of(BuildContext context) {
    final AppScope? scope = context
        .dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope above this context.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      auth != oldWidget.auth ||
      quizzes != oldWidget.quizzes ||
      google != oldWidget.google;
}
