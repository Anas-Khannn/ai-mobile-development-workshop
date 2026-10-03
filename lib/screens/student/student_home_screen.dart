import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/models.dart';
import '../../data/question_bank.dart';
import '../../data/quiz_store.dart';
import '../../ui/common.dart';
import '../home_widgets.dart';
import '../quiz_screen.dart';

/// Quizzes from teachers, the built-in practice topics and recent results.
class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

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
        final List<TeacherQuiz> quizzes = store.quizzes;
        final List<QuizAttempt> history = store.attemptsBy(user.id);
        final int completed = <String>{
          for (final QuizAttempt a in history) a.quizId,
        }.length;
        final int average = history.isEmpty
            ? 0
            : (history.fold<double>(
                        0,
                        (double s, QuizAttempt a) => s + a.fraction,
                      ) /
                      history.length *
                      100)
                  .round();

        int index = 0;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Studyy Buddy'),
            actions: <Widget>[AccountButton(user: user)],
          ),
          body: SafeArea(
            child: ListView(
              padding: pagePadding,
              children: <Widget>[
                FadeSlideIn(
                  index: index++,
                  child: GreetingCard(
                    user: user,
                    message: 'Pick a quiz and test yourself.',
                    stats: <HeaderStat>[
                      HeaderStat(quizzes.length, 'Quizzes'),
                      HeaderStat(completed, 'Completed'),
                      HeaderStat(average, 'Avg score', suffix: '%'),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                FadeSlideIn(
                  index: index++,
                  child: const SectionTitle('From your teachers'),
                ),
                if (quizzes.isEmpty)
                  FadeSlideIn(
                    index: index++,
                    child: const EmptyState(
                      icon: Icons.mark_email_unread_outlined,
                      title: 'No teacher quizzes yet',
                      message:
                          'When a teacher publishes a quiz it shows up here. '
                          'Try a practice topic below meanwhile.',
                    ),
                  ),
                for (int i = 0; i < quizzes.length; i++)
                  FadeSlideIn(
                    index: index++,
                    child: _StudentQuizCard(
                      key: ValueKey<String>('teacher_quiz_$i'),
                      quiz: quizzes[i],
                      best: store.bestAttempt(quizzes[i].id, user.id),
                      onTap: () => _startTeacherQuiz(context, quizzes[i], user),
                    ),
                  ),
                const SizedBox(height: 14),
                FadeSlideIn(
                  index: index++,
                  child: const SectionTitle('Practice topics'),
                ),
                for (int i = 0; i < practiceTopics.length; i++)
                  FadeSlideIn(
                    index: index++,
                    child: _TopicCard(topic: practiceTopics[i], index: i),
                  ),
                if (history.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 14),
                  FadeSlideIn(
                    index: index++,
                    child: const SectionTitle('My recent results'),
                  ),
                  for (final QuizAttempt attempt in history.take(5))
                    FadeSlideIn(
                      index: index++,
                      child: _ResultRow(
                        attempt: attempt,
                        title: store.quizById(attempt.quizId)?.title ?? 'Quiz',
                      ),
                    ),
                ],
                const SizedBox(height: 6),
                Text(
                  'Everything is stored on this device - no internet needed.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _startTeacherQuiz(BuildContext context, TeacherQuiz quiz, AppUser user) {
    final QuizStore store = AppScope.of(context).quizzes;
    Navigator.of(context).push(
      slideRoute<void>(
        QuizScreen(
          topic: quiz.toTopic(),
          backLabel: 'Back to quizzes',
          onCompleted: (int score, int total) => store.recordAttempt(
            quiz: quiz,
            student: user,
            score: score,
            total: total,
          ),
        ),
      ),
    );
  }
}

class _QuizCardShell extends StatelessWidget {
  const _QuizCardShell({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.pills,
    required this.onTap,
    required this.semanticLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> pills;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: true,
        label: semanticLabel,
        child: ExcludeSemantics(
          child: Card(
            color: scheme.surfaceContainerHigh,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        icon,
                        color: scheme.onPrimaryContainer,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(spacing: 6, runSpacing: 6, children: pills),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: scheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StudentQuizCard extends StatelessWidget {
  const _StudentQuizCard({
    super.key,
    required this.quiz,
    required this.best,
    required this.onTap,
  });

  final TeacherQuiz quiz;
  final QuizAttempt? best;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final QuizAttempt? best = this.best;
    return _QuizCardShell(
      icon: Icons.assignment_rounded,
      title: quiz.title,
      subtitle: quiz.description.isEmpty
          ? 'By ${quiz.teacherName}'
          : '${quiz.description}\nBy ${quiz.teacherName}',
      semanticLabel:
          '${quiz.title} by ${quiz.teacherName}. '
          '${quiz.questions.length} questions. '
          '${best == null ? 'Not attempted yet' : 'Best score ${best.score} of ${best.total}'}. '
          'Start quiz.',
      onTap: onTap,
      pills: <Widget>[
        Pill(
          label: plural(quiz.questions.length, 'question'),
          background: scheme.secondaryContainer,
          foreground: scheme.onSecondaryContainer,
        ),
        if (best == null)
          Pill(
            label: 'New',
            icon: Icons.fiber_new_rounded,
            background: scheme.primaryContainer,
            foreground: scheme.onPrimaryContainer,
          )
        else
          Pill(
            label: 'Best ${best.score}/${best.total}',
            icon: Icons.emoji_events_rounded,
            background: scheme.tertiaryContainer,
            foreground: scheme.onTertiaryContainer,
          ),
      ],
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({required this.topic, required this.index});

  final Topic topic;
  final int index;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return _QuizCardShell(
      key: ValueKey<String>('topic_$index'),
      icon: topic.icon,
      title: topic.title,
      subtitle: topic.subtitle,
      semanticLabel:
          '${topic.title}. ${topic.subtitle}. '
          '${topic.questions.length} questions. Start quiz.',
      onTap: () =>
          Navigator.of(context)
              .push(slideRoute<void>(QuizScreen(topic: topic))),
      pills: <Widget>[
        Pill(
          label: plural(topic.questions.length, 'question'),
          background: scheme.secondaryContainer,
          foreground: scheme.onSecondaryContainer,
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.attempt, required this.title});

  final QuizAttempt attempt;
  final String title;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool passed = attempt.fraction >= kPassFraction;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(
        passed ? Icons.emoji_events_rounded : Icons.replay_rounded,
        color: passed ? scheme.tertiary : scheme.error,
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(shortDate(attempt.completedAt)),
      trailing: Text(
        '${attempt.score}/${attempt.total}',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: passed ? scheme.tertiary : scheme.error,
        ),
      ),
    );
  }
}
