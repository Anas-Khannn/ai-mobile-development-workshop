import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/models.dart';
import '../../ui/common.dart';

const int _minOptions = 2;
const int _maxOptions = 6;

/// Lets a teacher write a multiple-choice quiz and publish it to students.
class CreateQuizScreen extends StatefulWidget {
  const CreateQuizScreen({super.key});

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

/// Editable state for one question while the quiz is being written.
class _QuestionDraft {
  _QuestionDraft(this.id)
    : options = List<TextEditingController>.generate(
        4,
        (_) => TextEditingController(),
      );

  final int id;
  final TextEditingController question = TextEditingController();
  final List<TextEditingController> options;
  int correct = 0;

  void dispose() {
    question.dispose();
    for (final TextEditingController c in options) {
      c.dispose();
    }
  }
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ScrollController _scroll = ScrollController();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final List<_QuestionDraft> _drafts = <_QuestionDraft>[];
  int _nextId = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _drafts.add(_QuestionDraft(_nextId++));
  }

  @override
  void dispose() {
    _scroll.dispose();
    _title.dispose();
    _description.dispose();
    for (final _QuestionDraft d in _drafts) {
      d.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    setState(() => _drafts.add(_QuestionDraft(_nextId++)));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _removeQuestion(_QuestionDraft draft) {
    setState(() => _drafts.remove(draft));
    draft.dispose();
  }

  Future<void> _publish() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      _toast('Fill in the highlighted fields first.');
      return;
    }

    final List<QuizQuestion> questions = <QuizQuestion>[];
    for (int i = 0; i < _drafts.length; i++) {
      final _QuestionDraft d = _drafts[i];
      if (d.options[d.correct].text.trim().isEmpty) {
        _toast('Question ${i + 1}: the correct answer can\'t be empty.');
        return;
      }
      // Drop blank optional options and remap the correct index to match.
      final List<String> options = <String>[];
      int correct = 0;
      for (int o = 0; o < d.options.length; o++) {
        final String text = d.options[o].text.trim();
        if (text.isEmpty) continue;
        if (o == d.correct) correct = options.length;
        options.add(text);
      }
      if (options.toSet().length != options.length) {
        _toast('Question ${i + 1} has two identical options.');
        return;
      }
      questions.add(
        QuizQuestion(
          question: d.question.text.trim(),
          options: options,
          correctIndex: correct,
        ),
      );
    }

    final AppScope scope = AppScope.of(context);
    final AppUser? teacher = scope.auth.currentUser;
    if (teacher == null) return;
    setState(() => _saving = true);
    await scope.quizzes.addQuiz(
      teacher: teacher,
      title: _title.text,
      description: _description.text,
      questions: questions,
    );
    if (!mounted) return;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('"${_title.text.trim()}" is live for your students.'),
      ),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New quiz')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              Expanded(
                child: ListView(
                  controller: _scroll,
                  padding: pagePadding,
                  children: <Widget>[
                    FadeSlideIn(
                      index: 0,
                      child: TextFormField(
                        key: const ValueKey<String>('quiz_title'),
                        controller: _title,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Quiz title',
                          prefixIcon: Icon(Icons.title_rounded),
                        ),
                        validator: (String? v) => (v ?? '').trim().isEmpty
                            ? 'Give the quiz a title'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FadeSlideIn(
                      index: 1,
                      child: TextFormField(
                        key: const ValueKey<String>('quiz_description'),
                        controller: _description,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 2,
                        minLines: 1,
                        decoration: const InputDecoration(
                          labelText: 'Description (optional)',
                          prefixIcon: Icon(Icons.notes_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    for (int i = 0; i < _drafts.length; i++)
                      FadeSlideIn(
                        key: ValueKey<int>(_drafts[i].id),
                        index: i == 0 ? 2 : 0,
                        child: _QuestionEditor(
                          number: i + 1,
                          draft: _drafts[i],
                          onChanged: () => setState(() {}),
                          onRemove: _drafts.length > 1
                              ? () => _removeQuestion(_drafts[i])
                              : null,
                        ),
                      ),
                    OutlinedButton.icon(
                      key: const ValueKey<String>('add_question'),
                      onPressed: _addQuestion,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add question'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: FilledButton.icon(
                  key: const ValueKey<String>('publish_quiz'),
                  onPressed: _saving ? null : _publish,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.publish_rounded),
                  label: Text(
                    'Publish quiz (${_drafts.length} '
                    '${_drafts.length == 1 ? 'question' : 'questions'})',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionEditor extends StatelessWidget {
  const _QuestionEditor({
    required this.number,
    required this.draft,
    required this.onChanged,
    required this.onRemove,
  });

  final int number;
  final _QuestionDraft draft;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Card(
      color: scheme.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    child: Text(
                      '$number',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Question $number',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (onRemove != null)
                    IconButton(
                      tooltip: 'Remove question',
                      onPressed: onRemove,
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: scheme.error,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextFormField(
                  key: ValueKey<String>('question_${number - 1}'),
                  controller: draft.question,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                  minLines: 1,
                  decoration: const InputDecoration(labelText: 'Question'),
                  validator: (String? v) =>
                      (v ?? '').trim().isEmpty ? 'Write the question' : null,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Options - tap the circle to mark the correct answer',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              for (int o = 0; o < draft.options.length; o++)
                _OptionRow(
                  key: ObjectKey(draft.options[o]),
                  fieldKey: ValueKey<String>('q${number - 1}_option_$o'),
                  controller: draft.options[o],
                  letter: String.fromCharCode(65 + o),
                  isCorrect: draft.correct == o,
                  required: o < _minOptions,
                  onMarkCorrect: () {
                    draft.correct = o;
                    onChanged();
                  },
                  onRemove: draft.options.length > _minOptions
                      ? () {
                          final TextEditingController removed = draft.options
                              .removeAt(o);
                          if (draft.correct == o) {
                            draft.correct = 0;
                          } else if (draft.correct > o) {
                            draft.correct--;
                          }
                          onChanged();
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => removed.dispose(),
                          );
                        }
                      : null,
                ),
              if (draft.options.length < _maxOptions)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      draft.options.add(TextEditingController());
                      onChanged();
                    },
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: const Text('Add option'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    super.key,
    required this.fieldKey,
    required this.controller,
    required this.letter,
    required this.isCorrect,
    required this.required,
    required this.onMarkCorrect,
    required this.onRemove,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String letter;
  final bool isCorrect;
  final bool required;
  final VoidCallback onMarkCorrect;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          IconButton(
            tooltip: isCorrect ? 'Correct answer' : 'Mark as correct',
            onPressed: onMarkCorrect,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (Widget child, Animation<double> a) =>
                  ScaleTransition(scale: a, child: child),
              child: Icon(
                isCorrect
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                key: ValueKey<bool>(isCorrect),
                color: isCorrect ? scheme.tertiary : scheme.outline,
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              key: fieldKey,
              controller: controller,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Option $letter${required ? '' : ' (optional)'}',
                isDense: true,
                filled: isCorrect,
                fillColor: isCorrect ? scheme.tertiaryContainer : null,
              ),
              validator: (String? v) =>
                  required && (v ?? '').trim().isEmpty ? 'Required' : null,
            ),
          ),
          SizedBox(
            width: 40,
            child: onRemove == null
                ? null
                : IconButton(
                    tooltip: 'Remove option',
                    onPressed: onRemove,
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
          ),
        ],
      ),
    );
  }
}
