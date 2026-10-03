import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/models.dart';
import '../../ui/common.dart';
import '../quiz_screen.dart';

/// Every student attempt at one of the teacher's quizzes.
class QuizResultsScreen extends StatelessWidget {
  const QuizResultsScreen({super.key, required this.quizId});

  final String quizId;

  Future<void> _confirmDelete(BuildContext context, TeacherQuiz quiz) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        icon: const Icon(Icons.delete_forever_rounded),
        title: const Text('Delete quiz?'),
        content: Text(
          '"${quiz.title}" and all of its student results will be removed.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey<String>('confirm_delete'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final AppScope scope = AppScope.of(context);
      Navigator.of(context).pop();
      await scope.quizzes.deleteQuiz(quiz.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppScope scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: scope.quizzes,
      builder: (BuildContext context, _) {
        final TeacherQuiz? quiz = scope.quizzes.quizById(quizId);
        if (quiz == null) {
          return const Scaffold(body: SizedBox.shrink());
        }
        final List<QuizAttempt> attempts = scope.quizzes.attemptsFor(quiz.id);
        final ThemeData theme = Theme.of(context);
        final ColorScheme scheme = theme.colorScheme;
        final double average = attempts.isEmpty
            ? 0
            : attempts.fold<double>(
                    0,
                    (double s, QuizAttempt a) => s + a.fraction,
                  ) /
                  attempts.length;
        final int students = attempts
            .map((QuizAttempt a) => a.studentId)
            .toSet()
            .length;

        return Scaffold(
          appBar: AppBar(
            title: Text(quiz.title),
            actions: <Widget>[
              IconButton(
                tooltip: 'Preview quiz',
                onPressed: () => Navigator.of(context).push(
                  slideRoute<void>(
                    QuizScreen(topic: quiz.toTopic(), backLabel: 'Back'),
                  ),
                ),
                icon: const Icon(Icons.play_circle_outline_rounded),
              ),
              IconButton(
                key: const ValueKey<String>('delete_quiz'),
                tooltip: 'Delete quiz',
                onPressed: () => _confirmDelete(context, quiz),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: pagePadding,
              children: <Widget>[
                FadeSlideIn(
                  index: 0,
                  child: HeaderCard(
                    child: Row(
                      children: <Widget>[
                        _Stat(value: '${attempts.length}', label: 'Attempts'),
                        _Stat(value: '$students', label: 'Students'),
                        _Stat(
                          value: attempts.isEmpty ? '-' : percentLabel(average),
                          label: 'Average',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const FadeSlideIn(
                  index: 1,
                  child: SectionTitle('Student results'),
                ),
                if (attempts.isEmpty)
                  const FadeSlideIn(
                    index: 2,
                    child: EmptyState(
                      icon: Icons.hourglass_empty_rounded,
                      title: 'No attempts yet',
                      message:
                          'Results show up here as soon as a student '
                          'finishes this quiz.',
                    ),
                  ),
                for (int i = 0; i < attempts.length; i++)
                  FadeSlideIn(
                    index: i + 2,
                    child: _AttemptTile(attempt: attempts[i]),
                  ),
                const SizedBox(height: 22),
                FadeSlideIn(
                  index: attempts.length + 3,
                  child: SectionTitle('Questions (${quiz.questions.length})'),
                ),
                for (int i = 0; i < quiz.questions.length; i++)
                  FadeSlideIn(
                    index: attempts.length + 4 + i,
                    child: Card(
                      color: scheme.surfaceContainerLow,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '${i + 1}. ${quiz.questions[i].question}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: <Widget>[
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 18,
                                  color: scheme.tertiary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    quiz.questions[i].options[quiz
                                        .questions[i]
                                        .correctIndex],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _AttemptTile extends StatelessWidget {
  const _AttemptTile({required this.attempt});

  final QuizAttempt attempt;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool passed = attempt.fraction >= kPassFraction;
    final Color accent = passed ? scheme.tertiary : scheme.error;

    return Card(
      color: scheme.surfaceContainerHigh,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              backgroundColor: scheme.secondaryContainer,
              foregroundColor: scheme.onSecondaryContainer,
              child: Text(
                attempt.studentName.isEmpty
                    ? '?'
                    : attempt.studentName[0].toUpperCase(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    attempt.studentName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    shortDate(attempt.completedAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: attempt.fraction),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (BuildContext context, double v, _) =>
                          LinearProgressIndicator(
                            value: v,
                            minHeight: 6,
                            color: accent,
                            backgroundColor: scheme.surfaceContainerHighest,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${attempt.score}/${attempt.total}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
