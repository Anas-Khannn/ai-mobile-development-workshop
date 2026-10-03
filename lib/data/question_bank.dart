import 'package:flutter/material.dart';

import 'models.dart';

// Built-in practice topics (plain Dart lists - no internet needed). Students
// can play these alongside the quizzes their teachers write.

const List<Topic> practiceTopics = <Topic>[
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
