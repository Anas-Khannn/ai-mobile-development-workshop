import 'package:flutter/material.dart';

import '../data/app_scope.dart';
import '../data/google_auth.dart';
import '../data/models.dart';
import '../ui/common.dart';
import 'auth/auth_widgets.dart';
import 'auth/login_screen.dart';
import 'student/student_home_screen.dart';
import 'teacher/teacher_home_screen.dart';

Widget homeFor(AppUser user) => switch (user.role) {
  UserRole.teacher => const TeacherHomeScreen(),
  UserRole.student => const StudentHomeScreen(),
};

/// Replaces the whole stack with the signed-in user's home screen.
void goHome(BuildContext context, AppUser user) {
  Navigator.of(context).pushAndRemoveUntil(
    fadeScaleRoute<void>(homeFor(user), milliseconds: 650),
    (_) => false,
  );
}

Future<void> logOut(BuildContext context) async {
  final AppScope scope = AppScope.of(context);
  final bool usedGoogle =
      scope.auth.currentUser?.provider == AuthProvider.google;
  await scope.auth.logOut();
  if (usedGoogle) {
    await scope.google.signOut();
  }
  if (context.mounted) {
    Navigator.of(context).pushAndRemoveUntil(
      fadeScaleRoute<void>(const LoginScreen()),
      (_) => false,
    );
  }
}

/// Runs the Google flow and opens the home screen on success.
///
/// Returns an error message to show, or null when it succeeded or the user
/// backed out. A first-time Google user gets [role] when given (sign-up
/// screen), otherwise they are asked to pick one.
Future<String?> continueWithGoogle(
  BuildContext context, {
  UserRole? role,
}) async {
  final AppScope scope = AppScope.of(context);
  try {
    final GoogleProfile? profile = await scope.google.signIn();
    if (profile == null || !context.mounted) {
      return null;
    }
    AppUser? user = await scope.auth.signInWithGoogle(profile, role: role);
    if (user == null) {
      if (!context.mounted) return null;
      final UserRole? picked = await pickRoleSheet(context);
      if (picked == null) {
        await scope.google.signOut();
        return null;
      }
      user = await scope.auth.signInWithGoogle(profile, role: picked);
    }
    if (user != null && context.mounted) {
      goHome(context, user);
    }
    return null;
  } on GoogleAuthException catch (error) {
    return error.message;
  }
}
