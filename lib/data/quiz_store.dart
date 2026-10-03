import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Teacher-written quizzes and the students' attempts, stored on the device.
class QuizStore extends ChangeNotifier {
  QuizStore(this._prefs) {
    _quizzes = _read(_quizzesKey, TeacherQuiz.fromJson);
    _attempts = _read(_attemptsKey, QuizAttempt.fromJson);
  }

  static const String _quizzesKey = 'quizzes.all';
  static const String _attemptsKey = 'quizzes.attempts';

  final SharedPreferences _prefs;

  late List<TeacherQuiz> _quizzes;
  late List<QuizAttempt> _attempts;

  /// Newest first.
  List<TeacherQuiz> get quizzes => List<TeacherQuiz>.unmodifiable(
    _quizzes.toList()..sort(
      (TeacherQuiz a, TeacherQuiz b) => b.createdAt.compareTo(a.createdAt),
    ),
  );

  List<TeacherQuiz> quizzesBy(String teacherId) => <TeacherQuiz>[
    for (final TeacherQuiz q in quizzes)
      if (q.teacherId == teacherId) q,
  ];

  TeacherQuiz? quizById(String id) =>
      _quizzes.where((TeacherQuiz q) => q.id == id).firstOrNull;

  /// Newest first.
  List<QuizAttempt> attemptsFor(String quizId) =>
      _sortedAttempts((QuizAttempt a) => a.quizId == quizId);

  /// Newest first.
  List<QuizAttempt> attemptsBy(String studentId) =>
      _sortedAttempts((QuizAttempt a) => a.studentId == studentId);

  QuizAttempt? bestAttempt(String quizId, String studentId) {
    QuizAttempt? best;
    for (final QuizAttempt a in _attempts) {
      if (a.quizId == quizId &&
          a.studentId == studentId &&
          (best == null || a.fraction > best.fraction)) {
        best = a;
      }
    }
    return best;
  }

  Future<TeacherQuiz> addQuiz({
    required AppUser teacher,
    required String title,
    required String description,
    required List<QuizQuestion> questions,
  }) async {
    final TeacherQuiz quiz = TeacherQuiz(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title.trim(),
      description: description.trim(),
      teacherId: teacher.id,
      teacherName: teacher.name,
      questions: questions,
      createdAt: DateTime.now(),
    );
    _quizzes = <TeacherQuiz>[..._quizzes, quiz];
    await _save();
    return quiz;
  }

  Future<void> deleteQuiz(String quizId) async {
    _quizzes = <TeacherQuiz>[
      for (final TeacherQuiz q in _quizzes)
        if (q.id != quizId) q,
    ];
    _attempts = <QuizAttempt>[
      for (final QuizAttempt a in _attempts)
        if (a.quizId != quizId) a,
    ];
    await _save();
  }

  Future<void> recordAttempt({
    required TeacherQuiz quiz,
    required AppUser student,
    required int score,
    required int total,
  }) async {
    _attempts = <QuizAttempt>[
      ..._attempts,
      QuizAttempt(
        quizId: quiz.id,
        studentId: student.id,
        studentName: student.name,
        score: score,
        total: total,
        completedAt: DateTime.now(),
      ),
    ];
    await _save();
  }

  List<QuizAttempt> _sortedAttempts(bool Function(QuizAttempt) test) =>
      _attempts.where(test).toList()..sort(
        (QuizAttempt a, QuizAttempt b) =>
            b.completedAt.compareTo(a.completedAt),
      );

  Future<void> _save() async {
    notifyListeners();
    await _prefs.setString(
      _quizzesKey,
      jsonEncode(<Map<String, dynamic>>[
        for (final TeacherQuiz q in _quizzes) q.toJson(),
      ]),
    );
    await _prefs.setString(
      _attemptsKey,
      jsonEncode(<Map<String, dynamic>>[
        for (final QuizAttempt a in _attempts) a.toJson(),
      ]),
    );
  }

  List<T> _read<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final String? raw = _prefs.getString(key);
    if (raw == null) {
      return <T>[];
    }
    try {
      return <T>[
        for (final dynamic item in jsonDecode(raw) as List<dynamic>)
          fromJson(item as Map<String, dynamic>),
      ];
    } on Object catch (error) {
      debugPrint('Ignoring unreadable $key: $error');
      return <T>[];
    }
  }
}
