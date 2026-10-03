import 'package:activity_gsp/data/google_auth.dart';
import 'package:activity_gsp/data/models.dart';
import 'package:activity_gsp/main.dart';
import 'package:activity_gsp/screens/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:activity_gsp/screens/auth/forgot_password_screen.dart';
import 'package:activity_gsp/screens/auth/login_screen.dart';
import 'package:activity_gsp/screens/auth/signup_screen.dart';
import 'package:activity_gsp/screens/student/student_home_screen.dart';
import 'package:activity_gsp/screens/teacher/teacher_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('app start shows the splash, then sign-up', (
    WidgetTester tester,
  ) async {
    reduceMotion(tester);
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(const StudyyBuddyBootstrap());
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
    await pumpPastSplash(tester);
    expect(find.byType(SignUpScreen), findsOneWidget);
  });

  testWidgets('splash leads a first-time user to sign up', (
    WidgetTester tester,
  ) async {
    reduceMotion(tester);
    final TestHarness harness = await createHarness();
    await tester.pumpWidget(harness.app());

    expect(find.text('Learn together. Quiz smarter.'), findsOneWidget);
    await pumpPastSplash(tester);

    expect(find.byType(SignUpScreen), findsOneWidget);
    expect(find.text('Join as Teacher'), findsOneWidget);
    expect(find.text('Join as Student'), findsOneWidget);
  });

  testWidgets('splash goes straight home when a session exists', (
    WidgetTester tester,
  ) async {
    final TestHarness harness = await createHarness();
    await harness.signedIn(UserRole.teacher);
    await tester.pumpWidget(harness.app());
    await pumpPastSplash(tester);

    expect(find.byType(TeacherHomeScreen), findsOneWidget);
  });

  testWidgets('sign up, then log in, opens the home for the chosen role', (
    WidgetTester tester,
  ) async {
    reduceMotion(tester);
    final TestHarness harness = await createHarness();
    await tester.pumpWidget(harness.app(home: const SignUpScreen()));
    await tester.pumpAndSettle();

    await tapKey(tester, 'role_teacher');
    await enterKey(tester, 'signup_name', 'Ada Lovelace');
    await enterKey(tester, 'signup_email', 'ada@example.com');
    await enterKey(tester, 'signup_password', 'engine42');
    await enterKey(tester, 'signup_confirm', 'engine42');
    await tapKey(tester, 'signup_submit');

    // Sign-up does not sign in: the user lands on login with the email filled.
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(harness.auth.currentUser, isNull);
    expect(find.text('ada@example.com'), findsOneWidget);

    await enterKey(tester, 'login_password', 'engine42');
    await tapKey(tester, 'login_submit');

    expect(find.byType(TeacherHomeScreen), findsOneWidget);
    expect(find.text('Hi, Ada!'), findsOneWidget);
  });

  testWidgets('sign up rejects mismatched passwords', (
    WidgetTester tester,
  ) async {
    reduceMotion(tester);
    final TestHarness harness = await createHarness();
    await tester.pumpWidget(harness.app(home: const SignUpScreen()));
    await tester.pumpAndSettle();

    await enterKey(tester, 'signup_name', 'Ada');
    await enterKey(tester, 'signup_email', 'ada@example.com');
    await enterKey(tester, 'signup_password', 'engine42');
    await enterKey(tester, 'signup_confirm', 'engine43');
    await tapKey(tester, 'signup_submit');

    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(harness.auth.hasAccounts, isFalse);
  });

  testWidgets('wrong password shows an error and stays on login', (
    WidgetTester tester,
  ) async {
    reduceMotion(tester);
    final TestHarness harness = await createHarness();
    await harness.auth.signUp(
      name: 'Sam',
      email: 'sam@example.com',
      password: 'right-one',
      role: UserRole.student,
    );
    await tester.pumpWidget(harness.app(home: const LoginScreen()));
    await tester.pumpAndSettle();

    await enterKey(tester, 'login_email', 'sam@example.com');
    await enterKey(tester, 'login_password', 'wrong-one');
    await tapKey(tester, 'login_submit');

    expect(find.text('Incorrect password. Please try again.'), findsOneWidget);
    expect(harness.auth.currentUser, isNull);
  });

  testWidgets('forgot password sets a new password that then works', (
    WidgetTester tester,
  ) async {
    reduceMotion(tester);
    final TestHarness harness = await createHarness();
    await harness.auth.signUp(
      name: 'Sam',
      email: 'sam@example.com',
      password: 'old-password',
      role: UserRole.student,
    );
    await tester.pumpWidget(harness.app(home: const LoginScreen()));
    await tester.pumpAndSettle();

    await tapKey(tester, 'go_forgot');
    await enterKey(tester, 'forgot_email', 'sam@example.com');
    await tapKey(tester, 'forgot_continue');
    await enterKey(tester, 'forgot_password', 'new-password');
    await enterKey(tester, 'forgot_confirm', 'new-password');
    await tapKey(tester, 'forgot_save');

    expect(find.text('Password updated!'), findsOneWidget);
    await tapKey(tester, 'forgot_back_to_login');

    expect(find.byType(LoginScreen), findsOneWidget);
    await enterKey(tester, 'login_password', 'new-password');
    await tapKey(tester, 'login_submit');
    expect(find.byType(StudentHomeScreen), findsOneWidget);
  });

  testWidgets('forgot password reports an unknown email', (
    WidgetTester tester,
  ) async {
    reduceMotion(tester);
    final TestHarness harness = await createHarness();
    await tester.pumpWidget(harness.app(home: const LoginScreen()));
    await tester.pumpAndSettle();

    await tapKey(tester, 'go_forgot');
    await enterKey(tester, 'forgot_email', 'nobody@example.com');
    await tapKey(tester, 'forgot_continue');

    expect(find.text('No account found for this email.'), findsOneWidget);
  });

  testWidgets('first Google login asks for a role, then opens that home', (
    WidgetTester tester,
  ) async {
    reduceMotion(tester);
    final TestHarness harness = await createHarness(
      googleProfile: const GoogleProfile(
        id: 'g-1',
        email: 'grace@gmail.com',
        name: 'Grace Hopper',
      ),
    );
    await tester.pumpWidget(harness.app(home: const LoginScreen()));
    await tester.pumpAndSettle();

    await tapKey(tester, 'google_button', settle: false);
    expect(find.text('One last step'), findsOneWidget);

    await tapKey(tester, 'role_teacher', settle: false);
    await tapKey(tester, 'role_continue', settle: false);
    await tester.pumpAndSettle();

    expect(find.byType(TeacherHomeScreen), findsOneWidget);
    expect(harness.auth.currentUser?.provider, AuthProvider.google);
    expect(harness.auth.currentUser?.role, UserRole.teacher);
  });

  testWidgets('logging out returns to the login screen', (
    WidgetTester tester,
  ) async {
    reduceMotion(tester);
    final TestHarness harness = await createHarness();
    await harness.signedIn(UserRole.student);
    await tester.pumpWidget(harness.app(home: const StudentHomeScreen()));
    await tester.pumpAndSettle();

    await tapKey(tester, 'account_menu');
    await tapKey(tester, 'logout');

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(harness.auth.currentUser, isNull);
  });

  testWidgets('auth screens fit a small phone with large text', (
    WidgetTester tester,
  ) async {
    reduceMotion(tester);
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final TestHarness harness = await createHarness();

    for (final Widget screen in const <Widget>[
      SignUpScreen(),
      LoginScreen(),
      ForgotPasswordScreen(),
    ]) {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(1.6),
            disableAnimations: true,
          ),
          child: harness.app(home: screen),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$screen overflowed');
    }
  });
}
