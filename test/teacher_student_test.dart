import 'package:activity_gsp/data/models.dart';
import 'package:activity_gsp/screens/student/student_home_screen.dart';
import 'package:activity_gsp/screens/teacher/teacher_home_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('a teacher publishes a quiz from the quiz builder', (
    WidgetTester tester,
  ) async {
    final TestHarness harness = await createHarness();
    await harness.signedIn(UserRole.teacher, name: 'Ms Rivera');
    await tester.pumpWidget(harness.app(home: const TeacherHomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('No quizzes yet'), findsOneWidget);
    await tapKey(tester, 'new_quiz');

    await enterKey(tester, 'quiz_title', 'Capitals');
    await enterKey(tester, 'question_0', 'Capital of France?');
    await enterKey(tester, 'q0_option_0', 'Berlin');
    await enterKey(tester, 'q0_option_1', 'Paris');
    // Mark option B as the right answer.
    final Finder markB = find.byTooltip('Mark as correct').first;
    await tester.ensureVisible(markB);
    await tester.pumpAndSettle();
    await tester.tap(markB);
    await tester.pumpAndSettle();
    await tapKey(tester, 'publish_quiz');

    expect(find.byType(TeacherHomeScreen), findsOneWidget);
    expect(find.text('Capitals'), findsOneWidget);

    final TeacherQuiz quiz = harness.quizzes.quizzes.single;
    expect(quiz.teacherName, 'Ms Rivera');
    // Blank optional options C and D are dropped.
    expect(quiz.questions.single.options, <String>['Berlin', 'Paris']);
    expect(quiz.questions.single.correctIndex, 1);
  });

  testWidgets('the quiz builder refuses an incomplete quiz', (
    WidgetTester tester,
  ) async {
    final TestHarness harness = await createHarness();
    await harness.signedIn(UserRole.teacher);
    await tester.pumpWidget(harness.app(home: const TeacherHomeScreen()));
    await tester.pumpAndSettle();

    await tapKey(tester, 'new_quiz');
    await tapKey(tester, 'publish_quiz');

    expect(find.text('Give the quiz a title'), findsOneWidget);
    expect(harness.quizzes.quizzes, isEmpty);
  });

  testWidgets('a student solves a teacher quiz and the teacher sees it', (
    WidgetTester tester,
  ) async {
    final TestHarness harness = await createHarness();
    final AppUser teacher = await harness.signedIn(UserRole.teacher);
    await harness.quizzes.addQuiz(
      teacher: teacher,
      title: 'Capitals',
      description: 'Europe',
      questions: const <QuizQuestion>[
        QuizQuestion(
          question: 'Capital of France?',
          options: <String>['Paris', 'Berlin'],
          correctIndex: 0,
        ),
      ],
    );
    await harness.auth.logOut();
    final AppUser student = await harness.signedIn(
      UserRole.student,
      name: 'Kim Park',
    );

    await tester.pumpWidget(harness.app(home: const StudentHomeScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Capitals'), findsOneWidget);

    await tapKey(tester, 'teacher_quiz_0');
    await tester.tap(find.text('Paris'));
    await tester.pumpAndSettle();
    await tapKey(tester, 'next_button');

    expect(find.text('Great job!'), findsOneWidget);
    final QuizAttempt attempt = harness.quizzes.attemptsBy(student.id).single;
    expect(attempt.score, 1);
    expect(attempt.total, 1);
    expect(attempt.studentName, 'Kim Park');

    await tapKey(tester, 'back_button');
    expect(find.text('Best 1/1'), findsOneWidget);

    // The teacher's view of the same quiz now lists the attempt.
    await harness.auth.logOut();
    await harness.auth.logIn(
      email: 'teacher@example.com',
      password: 'secret123',
    );
    await tester.pumpWidget(harness.app(home: const TeacherHomeScreen()));
    await tester.pumpAndSettle();
    expect(find.text('1 attempt'), findsOneWidget);

    await tester.tap(find.text('Capitals'));
    await tester.pumpAndSettle();
    expect(find.text('Kim Park'), findsOneWidget);
    expect(find.text('1/1'), findsOneWidget);
  });

  testWidgets('deleting a quiz removes it for everyone', (
    WidgetTester tester,
  ) async {
    final TestHarness harness = await createHarness();
    final AppUser teacher = await harness.signedIn(UserRole.teacher);
    await harness.quizzes.addQuiz(
      teacher: teacher,
      title: 'Old quiz',
      description: '',
      questions: const <QuizQuestion>[
        QuizQuestion(
          question: 'Q?',
          options: <String>['A', 'B'],
          correctIndex: 0,
        ),
      ],
    );
    await tester.pumpWidget(harness.app(home: const TeacherHomeScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Old quiz'));
    await tester.pumpAndSettle();
    await tapKey(tester, 'delete_quiz');
    await tapKey(tester, 'confirm_delete');

    expect(find.byType(TeacherHomeScreen), findsOneWidget);
    expect(find.text('Old quiz'), findsNothing);
    expect(harness.quizzes.quizzes, isEmpty);
  });
}
