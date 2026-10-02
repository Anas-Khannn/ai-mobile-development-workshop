# Studyy Buddy

An offline Flutter quiz app for Flutter Basics, Dart and Git. Material 3 with an
orange seed colour and full light/dark support.

## Features

- Home screen with one card per topic (Flutter Basics, Dart, Git).
- One multiple-choice question at a time with a progress bar, a live score chip
  and a slide/fade transition between questions.
- Immediate right/wrong feedback: the chosen option is marked, the correct
  option is revealed, and the result is announced to screen readers.
- Question and option order are shuffled on every run, so the correct answer is
  never in a predictable place.
- Result screen with a score dial, percentage, a restart button and a back
  button.
- Works completely offline: every question lives in a plain Dart list in
  `lib/main.dart`. No packages, no assets, no network.

## Getting started

```bash
flutter pub get
flutter run
```

Run the checks:

```bash
flutter analyze
flutter test
```

## Adding questions

Edit the `const List<Topic> _topics` list in `lib/main.dart`. Each
`QuizQuestion` takes the question text, its options and the index of the correct
option:

```dart
QuizQuestion(
  question: 'Which widget lays out its children vertically?',
  options: <String>['Row', 'Column', 'Stack', 'ListView'],
  correctIndex: 1,
),
```

A topic with fewer than two valid questions is skipped, and the app shows an
empty state instead of crashing.