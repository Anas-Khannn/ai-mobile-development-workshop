import 'package:activity_gsp/data/auth_service.dart';
import 'package:activity_gsp/data/google_auth.dart';
import 'package:activity_gsp/data/models.dart';
import 'package:activity_gsp/data/quiz_store.dart';
import 'package:activity_gsp/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Google sign-in stand-in: returns [profile] (or null, as if cancelled).
class FakeGoogleAuth implements GoogleAuthClient {
  FakeGoogleAuth([this.profile]);

  GoogleProfile? profile;
  int signOuts = 0;

  @override
  Future<GoogleProfile?> signIn() async => profile;

  @override
  Future<void> signOut() async => signOuts++;
}

class TestHarness {
  TestHarness(this.auth, this.quizzes, this.google);

  final AuthService auth;
  final QuizStore quizzes;
  final FakeGoogleAuth google;

  StudyyBuddyApp app({Widget? home}) => home == null
      ? StudyyBuddyApp(auth: auth, quizzes: quizzes, google: google)
      : StudyyBuddyApp(
          auth: auth,
          quizzes: quizzes,
          google: google,
          home: home,
        );

  Future<AppUser> signedIn(UserRole role, {String name = 'Sam Lee'}) async {
    final String email = '${role.name}@example.com';
    await auth.signUp(
      name: name,
      email: email,
      password: 'secret123',
      role: role,
    );
    return auth.logIn(email: email, password: 'secret123');
  }
}

Future<TestHarness> createHarness({GoogleProfile? googleProfile}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return TestHarness(
    AuthService(prefs),
    QuizStore(prefs),
    FakeGoogleAuth(googleProfile),
  );
}

/// The auth screens have a looping background; turning on reduced motion
/// stops it so `pumpAndSettle` can finish.
void reduceMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

/// Lets the splash finish and its route transition play out.
Future<void> pumpPastSplash(WidgetTester tester) async {
  for (int i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}

/// Scrolls a lazily built list until [finder] exists, then into view.
Future<void> revealFinder(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
}

/// Taps the widget with [key]. With [settle] false it pumps a fixed second
/// instead, for screens with a spinner that never settles.
Future<void> tapKey(
  WidgetTester tester,
  String key, {
  bool settle = true,
}) async {
  final Finder finder = find.byKey(ValueKey<String>(key));
  await revealFinder(tester, finder);
  await (settle
      ? tester.pumpAndSettle()
      : tester.pump(const Duration(seconds: 1)));
  await tester.tap(finder);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
}

Future<void> enterKey(WidgetTester tester, String key, String text) async {
  final Finder finder = find.descendant(
    of: find.byKey(ValueKey<String>(key)),
    matching: find.byType(EditableText),
  );
  await tester.ensureVisible(finder);
  await tester.enterText(finder, text);
}
