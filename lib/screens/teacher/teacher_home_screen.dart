import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/models.dart';
import '../../data/quiz_store.dart';
import '../../ui/common.dart';
import '../home_widgets.dart';
import 'create_quiz_screen.dart';
import 'quiz_results_screen.dart';

/// A teacher's quizzes, with how many students have taken each one.
class TeacherHomeScreen extends StatelessWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppScope scope = AppScope.of(context);
    final AppUser? user = scope.auth.currentUser;
    if (user == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return ListenableBuilder(
      listenable: scope.quizzes,
      builder: (BuildContext context, _) {
        final QuizStore store = scope.quizzes;
        final List<TeacherQuiz> quizzes = store.quizzesBy(user.id);
        final int attempts = quizzes.fold<int>(
          0,
          (int sum, TeacherQuiz q) => sum + store.attemptsFor(q.id).length,
        );
        final int questions = quizzes.fold<int>(
          0,
          (int sum, TeacherQuiz q) => sum + q.questions.length,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Studyy Buddy'),
            actions: <Widget>[AccountButton(user: user)],
          ),
          floatingActionButton: _NewQuizButton(
            onPressed: () =>
                Navigator.of(context)
                    .push(slideRoute<void>(const CreateQuizScreen())),
          ),
          body: SafeArea(
            child: ListView(
              padding: pagePadding.copyWith(bottom: 96),
              children: <Widget>[
                FadeSlideIn(
                  index: 0,
                  child: GreetingCard(
                    user: user,
                    message: 'Create quizzes and see how your students do.',
                    stats: <HeaderStat>[
                      HeaderStat(quizzes.length, 'Quizzes'),
                      HeaderStat(questions, 'Questions'),
                      HeaderStat(attempts, 'Attempts'),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const FadeSlideIn(index: 1, child: SectionTitle('My quizzes')),
                if (quizzes.isEmpty)
                  const FadeSlideIn(
                    index: 2,
                    child: EmptyState(
                      icon: Icons.edit_note_rounded,
                      title: 'No quizzes yet',
                      message:
                          'Tap "New quiz" to write your first one. Your '
                          'students will see it straight away.',
                    ),
                  ),
                for (int i = 0; i < quizzes.length; i++)
                  FadeSlideIn(
                    key: ValueKey<String>(quizzes[i].id),
                    index: i + 2,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TeacherQuizCard(
                        quiz: quizzes[i],
                        attempts: store.attemptsFor(quizzes[i].id),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Pops in with a spring once the screen has appeared.
class _NewQuizButton extends StatelessWidget {
  const _NewQuizButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: const Interval(0.3, 1, curve: Curves.elasticOut),
      builder: (BuildContext context, double scale, Widget? child) =>
          Transform.scale(scale: scale, child: child),
      child: FloatingActionButton.extended(
        key: const ValueKey<String>('new_quiz'),
        onPressed: onPressed,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New quiz'),
      ),
    );
  }
}

class _TeacherQuizCard extends StatelessWidget {
  const _TeacherQuizCard({required this.quiz, required this.attempts});

  final TeacherQuiz quiz;
  final List<QuizAttempt> attempts;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final double? average = attempts.isEmpty
        ? null
        : attempts.fold<double>(
                0,
                (double s, QuizAttempt a) => s + a.fraction,
              ) /
              attempts.length;

    return Card(
      color: scheme.surfaceContainerHigh,
      child: InkWell(
        onTap: () =>
            Navigator.of(context)
                .push(slideRoute<void>(QuizResultsScreen(quizId: quiz.id))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.assignment_rounded,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      quiz.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (quiz.description.isNotEmpty)
                      Text(
                        quiz.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        Pill(
                          label: plural(quiz.questions.length, 'question'),
                          background: scheme.secondaryContainer,
                          foreground: scheme.onSecondaryContainer,
                        ),
                        Pill(
                          label: plural(attempts.length, 'attempt'),
                          icon: Icons.people_alt_rounded,
                          background: scheme.tertiaryContainer,
                          foreground: scheme.onTertiaryContainer,
                        ),
                        if (average != null)
                          Pill(
                            label: 'Avg ${percentLabel(average)}',
                            background: scheme.primaryContainer,
                            foreground: scheme.onPrimaryContainer,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
