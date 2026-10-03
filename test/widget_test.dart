import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:activity_gsp/data/models.dart';
import 'package:activity_gsp/main.dart';
import 'package:activity_gsp/screens/student/student_home_screen.dart';

import 'test_utils.dart';

Future<StudyyBuddyApp> studentHomeApp() async {
  final TestHarness harness = await createHarness();
  await harness.signedIn(UserRole.student);
  return harness.app(home: const StudentHomeScreen());
}

Future<void> pumpStudentHome(WidgetTester tester) async {
  await tester.pumpWidget(await studentHomeApp());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('home screen lists every topic card', (
    WidgetTester tester,
  ) async {
    await pumpStudentHome(tester);

    expect(find.text('Studyy Buddy'), findsOneWidget);
    for (int i = 0; i < 3; i++) {
      final Finder topic = find.byKey(ValueKey<String>('topic_$i'));
      await revealFinder(tester, topic);
      expect(topic, findsOneWidget);
    }
  });

  testWidgets('quiz shows a progress bar and one question at a time', (
    WidgetTester tester,
  ) async {
    await pumpStudentHome(tester);

    await tapKey(tester, 'topic_2');

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Question 1 of 3'), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('next_button')), findsOneWidget);
  });

  testWidgets('answering reveals feedback and advances to the score screen', (
    WidgetTester tester,
  ) async {
    await pumpStudentHome(tester);

    await tapKey(tester, 'topic_0');

    for (int question = 0; question < 3; question++) {
      final Finder option = find.byKey(const ValueKey<String>('option_0'));
      await tester.ensureVisible(option);
      await tester.tap(option);
      await tester.pumpAndSettle();

      final bool feedbackShown =
          find.text('Correct!').evaluate().isNotEmpty ||
          find.text('Wrong').evaluate().isNotEmpty;
      expect(feedbackShown, isTrue, reason: 'no feedback after answering');

      final Finder next = find.byKey(const ValueKey<String>('next_button'));
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pumpAndSettle();
    }

    expect(
      find.byKey(const ValueKey<String>('restart_button')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('back_button')), findsOneWidget);
    expect(find.textContaining(RegExp(r'^\d+/3$')), findsWidgets);
  });

  testWidgets('restart replays the quiz from the first question', (
    WidgetTester tester,
  ) async {
    await pumpStudentHome(tester);

    await tapKey(tester, 'topic_0');

    for (int question = 0; question < 3; question++) {
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('option_0')),
      );
      await tester.tap(find.byKey(const ValueKey<String>('option_0')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('next_button')),
      );
      await tester.tap(find.byKey(const ValueKey<String>('next_button')));
      await tester.pumpAndSettle();
    }

    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('restart_button')),
    );
    await tester.tap(find.byKey(const ValueKey<String>('restart_button')));
    await tester.pumpAndSettle();

    expect(find.text('Question 1 of 3'), findsOneWidget);
    expect(find.text('Score 0'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('restart_button')), findsNothing);
  });

  testWidgets('option tiles stop accepting taps after an answer', (
    WidgetTester tester,
  ) async {
    await pumpStudentHome(tester);

    await tapKey(tester, 'topic_1');

    await tester.ensureVisible(find.byKey(const ValueKey<String>('option_0')));
    await tester.tap(find.byKey(const ValueKey<String>('option_0')));
    await tester.pumpAndSettle();

    final String before = find.text('Score 1').evaluate().isNotEmpty
        ? 'Score 1'
        : 'Score 0';
    await tester.tap(find.byKey(const ValueKey<String>('option_1')));
    await tester.pumpAndSettle();

    expect(find.text(before), findsOneWidget);
  });

  testWidgets('small screen with large text never overflows', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: await studentHomeApp(),
      ),
    );
    expect(tester.takeException(), isNull);

    final Finder topic = find.byKey(const ValueKey<String>('topic_0'));
    await tester.dragUntilVisible(
      topic,
      find.byType(ListView).first,
      const Offset(0, -60),
    );
    await tester.pumpAndSettle();
    await tester.tap(topic);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    for (int question = 0; question < 3; question++) {
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('option_0')),
      );
      await tester.tap(find.byKey(const ValueKey<String>('option_0')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('next_button')),
      );
      await tester.tap(find.byKey(const ValueKey<String>('next_button')));
      await tester.pumpAndSettle();
    }

    expect(
      find.byKey(const ValueKey<String>('restart_button')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
