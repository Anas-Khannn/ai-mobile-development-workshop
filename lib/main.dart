import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Fraction of correct answers needed for the "Great job!" message.
const double kPassFraction = 0.66;

const EdgeInsets _pagePadding = EdgeInsets.fromLTRB(20, 8, 20, 24);

void main() {
  runApp(const StudyyBuddyApp());
}

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class QuizQuestion {
  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  }) : assert(correctIndex >= 0, 'correctIndex must not be negative.');

  final String question;
  final List<String> options;
  final int correctIndex;

  /// Runtime validation, because asserts are stripped in release builds.
  bool get isValid =>
      options.length >= 2 && correctIndex >= 0 && correctIndex < options.length;
}

class Topic {
  const Topic({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.questions,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<QuizQuestion> questions;
}

/// A question as it is asked during one quiz run: the options are shuffled and
/// [correctIndex] points at the shuffled position of the right answer.
class _QuizItem {
  const _QuizItem({
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  final String question;
  final List<String> options;
  final int correctIndex;
}

// ---------------------------------------------------------------------------
// Question bank (plain Dart lists - no packages, no internet)
// ---------------------------------------------------------------------------

const List<Topic> _topics = <Topic>[
  Topic(
    title: 'Flutter Basics',
    subtitle: 'Widgets, state and the widget tree',
    icon: Icons.flutter_dash,
    questions: <QuizQuestion>[
      QuizQuestion(
        question: 'What is a widget in Flutter?',
        options: <String>[
          'A description of part of the user interface',
          'A compiled C++ class',
          'A database table',
          'A type of HTTP request',
        ],
        correctIndex: 0,
      ),
      QuizQuestion(
        question: 'Which method is used to rebuild a StatefulWidget after its data changes?',
        options: <String>['refresh()', 'update()', 'setState()', 'rebuild()'],
        correctIndex: 2,
      ),
      QuizQuestion(
        question: 'What does build() return?',
        options: <String>['A String', 'A Widget', 'A Future', 'An int'],
        correctIndex: 1,
      ),
    ],
  ),
  Topic(
    title: 'Dart',
    subtitle: 'Types, null safety and functions',
    icon: Icons.code,
    questions: <QuizQuestion>[
      QuizQuestion(
        question: 'How do you write a nullable variable in Dart?',
        options: <String>[
          'int? count = null;',
          'int~ count = none;',
          'nullable int count;',
          'int count! = null;',
        ],
        correctIndex: 0,
      ),
      QuizQuestion(
        question: 'Which keyword declares a constant value that is known at compile time?',
        options: <String>['var', 'final', 'const', 'static'],
        correctIndex: 2,
      ),
      QuizQuestion(
        question: 'What does the ! operator do in Dart?',
        options: <String>[
          'Declares a function',
          'Asserts the value is not null',
          'Repeats a loop',
          'Imports a package',
        ],
        correctIndex: 1,
      ),
    ],
  ),
  Topic(
    title: 'Git',
    subtitle: 'Commits, branches and remotes',
    icon: Icons.commit,
    questions: <QuizQuestion>[
      QuizQuestion(
        question: 'Which command shows the current changes staged for commit?',
        options: <String>[
          'git diff --staged',
          'git push',
          'git clone',
          'git branch -D',
        ],
        correctIndex: 0,
      ),
      QuizQuestion(
        question: 'What is a commit?',
        options: <String>[
          'A saved snapshot of the repository',
          'A remote server',
          'A branch pointer only',
          'A merge conflict',
        ],
        correctIndex: 0,
      ),
      QuizQuestion(
        question: 'Which command creates a new branch and switches to it?',
        options: <String>[
          'git branch -m',
          'git switch -c feature',
          'git add -A',
          'git log --oneline',
        ],
        correctIndex: 1,
      ),
    ],
  ),
];

// ---------------------------------------------------------------------------
// Quiz session helpers
// ---------------------------------------------------------------------------

/// 'A', 'B', 'C' ... falling back to the number for very long option lists.
String _optionLetter(int index) {
  return index < 26 ? String.fromCharCode(65 + index) : '${index + 1}';
}

/// Builds the questions for a single quiz run: question order and option order
/// are both shuffled so the correct answer is never in a predictable place.
List<_QuizItem> _buildSession(List<QuizQuestion> questions, Random random) {
  final List<int> order = List<int>.generate(questions.length, (int i) => i)
    ..shuffle(random);

  final List<_QuizItem> items = <_QuizItem>[];
  for (final int index in order) {
    final QuizQuestion source = questions[index];
    if (!source.isValid) {
      continue;
    }
    final List<int> optionOrder = List<int>.generate(
      source.options.length,
      (int i) => i,
    )..shuffle(random);
    items.add(
      _QuizItem(
        question: source.question,
        options: <String>[for (final int i in optionOrder) source.options[i]],
        correctIndex: optionOrder.indexOf(source.correctIndex),
      ),
    );
  }
  return items;
}

// ---------------------------------------------------------------------------
// App + theme (Material 3, orange, light and dark)
// ---------------------------------------------------------------------------

class StudyyBuddyApp extends StatelessWidget {
  const StudyyBuddyApp({super.key});

  static const Color _seed = Color(0xFFFF6D00);

  static ThemeData _theme(Brightness brightness) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Studyy Buddy',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: const HomeScreen(),
    );
  }
}

// ---------------------------------------------------------------------------
// Home screen: topic cards
// ---------------------------------------------------------------------------

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final int totalQuestions = _topics.fold<int>(
      0,
      (int sum, Topic topic) => sum + topic.questions.length,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Studyy Buddy')),
      body: SafeArea(
        child: ListView(
          padding: _pagePadding,
          children: <Widget>[
            _HeaderCard(
              onColor: _onGradientColor(scheme),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Pick a topic and test yourself',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$totalQuestions questions across ${_topics.length} topics, '
                    'one at a time.',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            for (int i = 0; i < _topics.length; i++) ...<Widget>[
              _TopicCard(topic: _topics[i], index: i),
              const SizedBox(height: 14),
            ],
            const SizedBox(height: 6),
            Text(
              'Every question is stored on your device - no internet needed.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Picks black or white for text sitting on the header gradient, so the copy
/// stays readable in both light and dark mode.
Color _onGradientColor(ColorScheme scheme) {
  final Color end = Color.lerp(scheme.primary, scheme.tertiary, 0.9)!;
  return ThemeData.estimateBrightnessForColor(end) == Brightness.dark
      ? Colors.white
      : Colors.black87;
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.child, required this.onColor});

  final Widget child;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color end = Color.lerp(scheme.primary, scheme.tertiary, 0.9)!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: <Color>[scheme.primary, end],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: onColor),
        child: child,
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({required this.topic, required this.index});

  final Topic topic;
  final int index;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    final String semanticLabel =
        '${topic.title}. ${topic.subtitle}. '
        '${topic.questions.length} questions. Start quiz.';

    return Semantics(
      button: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Card(
          key: ValueKey<String>('topic_$index'),
          color: scheme.surfaceContainerHigh,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => QuizScreen(topic: topic),
                ),
              );
            },
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
                      topic.icon,
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
                          topic.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          topic.subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _Pill(
                          label: '${topic.questions.length} questions',
                          background: scheme.secondaryContainer,
                          foreground: scheme.onSecondaryContainer,
                        ),
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
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quiz screen
// ---------------------------------------------------------------------------

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.topic});

  final Topic topic;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final Random _random = Random();

  late List<_QuizItem> _items;
  int _index = 0;
  int _score = 0;
  int? _selected;
  bool _answered = false;
  bool _finished = false;

  _QuizItem? get _current => _items.isEmpty ? null : _items[_index];

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  @override
  void didUpdateWidget(covariant QuizScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.topic, widget.topic)) {
      setState(_startSession);
    }
  }

  void _startSession() {
    _items = _buildSession(widget.topic.questions, _random);
    _index = 0;
    _score = 0;
    _selected = null;
    _answered = false;
    _finished = false;
  }

  void _selectOption(int option) {
    final _QuizItem? item = _current;
    if (_answered || _finished || item == null) {
      return;
    }
    setState(() {
      _selected = option;
      _answered = true;
      if (option == item.correctIndex) {
        _score++;
      }
    });
    unawaited(HapticFeedback.selectionClick());
  }

  void _next() {
    if (!_answered || _finished) {
      return;
    }
    if (_index >= _items.length - 1) {
      setState(() => _finished = true);
      unawaited(HapticFeedback.mediumImpact());
    } else {
      setState(() {
        _index++;
        _selected = null;
        _answered = false;
      });
      unawaited(HapticFeedback.selectionClick());
    }
  }

  _OptionState _optionState(int option) {
    final _QuizItem? item = _current;
    if (item == null || !_answered) {
      return _OptionState.idle;
    }
    if (option == item.correctIndex) {
      return _OptionState.correct;
    }
    if (option == _selected) {
      return _OptionState.wrong;
    }
    return _OptionState.idle;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.topic.title)),
      body: SafeArea(
        child: _items.isEmpty
            ? _EmptyView(onBack: _goBack)
            : _finished
            ? _ResultView(
                score: _score,
                total: _items.length,
                topicTitle: widget.topic.title,
                onRestart: _restart,
                onBack: _goBack,
              )
            : _buildQuestion(context),
      ),
    );
  }

  void _goBack() {
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _restart() {
    setState(_startSession);
  }

  Widget _buildQuestion(BuildContext context) {
    final _QuizItem item = _current!;
    final int total = _items.length;
    final bool isLast = _index == total - 1;

    return Padding(
      padding: _pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _ProgressHeader(position: _index + 1, total: total, score: _score),
          const SizedBox(height: 20),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (Widget child, Animation<double> animation) =>
                  FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.15, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
              child: SingleChildScrollView(
                key: ValueKey<int>(_index),
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      item.question,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 16),
                    for (int i = 0; i < item.options.length; i++) ...<Widget>[
                      _OptionTile(
                        key: ValueKey<String>('option_$i'),
                        label: item.options[i],
                        letter: _optionLetter(i),
                        state: _optionState(i),
                        isSelected: _selected == i,
                        onTap: _answered ? null : () => _selectOption(i),
                      ),
                      const SizedBox(height: 12),
                    ],
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      alignment: Alignment.topCenter,
                      child: _FeedbackBox(
                        answered: _answered,
                        isCorrect: _selected == item.correctIndex,
                        correctText: item.options[item.correctIndex],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: const ValueKey<String>('next_button'),
            onPressed: _answered ? _next : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(isLast ? 'See results' : 'Next question'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Progress header (pinned to the top of the quiz)
// ---------------------------------------------------------------------------

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.position,
    required this.total,
    required this.score,
  });

  final int position;
  final int total;
  final int score;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final double value = total <= 0 ? 0 : (position / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Semantics(
                label: 'Quiz progress',
                value: '$position of $total',
                child: ExcludeSemantics(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(end: value),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      builder:
                          (
                            BuildContext context,
                            double animated,
                            Widget? child,
                          ) => LinearProgressIndicator(
                            value: animated,
                            minHeight: 10,
                            backgroundColor: scheme.primaryContainer,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              scheme.primary,
                            ),
                          ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (Widget child, Animation<double> animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Text(
                '$position/$total',
                key: ValueKey<int>(position),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Question $position of $total',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (
                  Widget child,
                  Animation<double> animation,
                ) => ScaleTransition(scale: animation, child: child),
                child: _Pill(
                  key: ValueKey<int>(score),
                  label: 'Score $score',
                  background: scheme.secondaryContainer,
                  foreground: scheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Feedback + result + empty views
// ---------------------------------------------------------------------------

class _FeedbackBox extends StatelessWidget {
  const _FeedbackBox({
    required this.answered,
    required this.isCorrect,
    required this.correctText,
  });

  final bool answered;
  final bool isCorrect;
  final String correctText;

  @override
  Widget build(BuildContext context) {
    if (!answered) {
      return const SizedBox.shrink();
    }

    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color background = isCorrect
        ? scheme.tertiaryContainer
        : scheme.errorContainer;
    final Color onBackground = isCorrect
        ? scheme.onTertiaryContainer
        : scheme.onErrorContainer;
    final Color accent = isCorrect ? scheme.tertiary : scheme.error;

    return Semantics(
      liveRegion: true,
      label: isCorrect
          ? 'Correct answer'
          : 'Wrong answer. The correct answer is $correctText',
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: accent,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      isCorrect ? 'Correct!' : 'Wrong',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!isCorrect) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        'Correct answer: $correctText',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: onBackground,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.score,
    required this.total,
    required this.topicTitle,
    required this.onRestart,
    required this.onBack,
  });

  final int score;
  final int total;
  final String topicTitle;
  final VoidCallback onRestart;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final double fraction = total <= 0 ? 0 : score / total;
    final bool passed = fraction >= kPassFraction;
    final Color accent = passed ? scheme.primary : scheme.error;

    return _ScrollableCenteredPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            label: 'Score $score out of $total',
            child: ExcludeSemantics(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.8, end: 1),
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutBack,
                builder: (BuildContext context, double scale, Widget? child) =>
                    Transform.scale(scale: scale, child: child),
                child: Container(
                  width: 140,
                  height: 140,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.12),
                    border: Border.all(color: accent, width: 5),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        '$score/$total',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: accent,
                        ),
                      ),
                      Text(
                        '${(fraction * 100).round()}%',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            passed ? 'Great job!' : 'Keep practising!',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            passed
                ? 'You scored $score out of $total in $topicTitle.'
                : 'You scored $score out of $total in $topicTitle. '
                      'Review the topic and try again.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            key: const ValueKey<String>('restart_button'),
            onPressed: onRestart,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Restart quiz'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            key: const ValueKey<String>('back_button'),
            onPressed: onBack,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Back to topics'),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return _ScrollableCenteredPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Icon(Icons.quiz_outlined, size: 72, color: scheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'No questions yet',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This topic has no playable questions right now.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const ValueKey<String>('back_button'),
            onPressed: onBack,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Back to topics'),
          ),
        ],
      ),
    );
  }
}

/// Scrolls when the content is taller than the viewport and centres it when it
/// is shorter, so short screens can never overflow.
class _ScrollableCenteredPage extends StatelessWidget {
  const _ScrollableCenteredPage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          padding: _pagePadding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: max(0, constraints.maxHeight - _pagePadding.vertical),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[child],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Option tile
// ---------------------------------------------------------------------------

enum _OptionState { idle, correct, wrong }

/// Colours come from the active [ColorScheme], so the tile follows dark mode.
class _OptionStyle {
  const _OptionStyle({
    required this.background,
    required this.foreground,
    required this.border,
    required this.icon,
  });

  final Color background;
  final Color foreground;
  final Color border;
  final IconData? icon;

  static _OptionStyle of(ColorScheme scheme, _OptionState state) {
    return switch (state) {
      _OptionState.idle => _OptionStyle(
        background: scheme.surfaceContainerHighest,
        foreground: scheme.onSurface,
        border: scheme.outlineVariant,
        icon: null,
      ),
      _OptionState.correct => _OptionStyle(
        background: scheme.tertiaryContainer,
        foreground: scheme.onTertiaryContainer,
        border: scheme.tertiary,
        icon: Icons.check_circle,
      ),
      _OptionState.wrong => _OptionStyle(
        background: scheme.errorContainer,
        foreground: scheme.onErrorContainer,
        border: scheme.error,
        icon: Icons.cancel,
      ),
    };
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    super.key,
    required this.label,
    required this.letter,
    required this.state,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String letter;
  final _OptionState state;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final _OptionStyle style = _OptionStyle.of(scheme, state);

    return Semantics(
      container: true,
      selected: isSelected,
      child: AnimatedScale(
        scale: isSelected ? 1.03 : 1,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: style.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: style.border,
              width: isSelected ? 2 : 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: style.foreground.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          letter,
                          style: TextStyle(
                            color: style.foreground,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: style.foreground,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (style.icon != null) ...<Widget>[
                        const SizedBox(width: 8),
                        TweenAnimationBuilder<double>(
                          key: ValueKey<_OptionState>(state),
                          tween: Tween<double>(begin: 0.2, end: 1),
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.elasticOut,
                          builder: (
                            BuildContext context,
                            double scale,
                            Widget? child,
                          ) => Transform.scale(scale: scale, child: child),
                          child: Icon(
                            style.icon,
                            color: style.foreground,
                            size: 22,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
