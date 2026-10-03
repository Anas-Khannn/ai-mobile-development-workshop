import 'package:flutter/material.dart';

enum UserRole {
  teacher,
  student;

  String get label => switch (this) {
    UserRole.teacher => 'Teacher',
    UserRole.student => 'Student',
  };

  IconData get icon => switch (this) {
    UserRole.teacher => Icons.school_rounded,
    UserRole.student => Icons.backpack_rounded,
  };

  static UserRole parse(String? value) =>
      value == UserRole.teacher.name ? UserRole.teacher : UserRole.student;
}

enum AuthProvider { email, google }

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.provider,
    this.passwordHash,
    this.salt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    role: UserRole.parse(json['role'] as String?),
    provider: json['provider'] == AuthProvider.google.name
        ? AuthProvider.google
        : AuthProvider.email,
    passwordHash: json['passwordHash'] as String?,
    salt: json['salt'] as String?,
  );

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final AuthProvider provider;

  /// Only set for email accounts; Google accounts never store a password.
  final String? passwordHash;
  final String? salt;

  bool get hasPassword => passwordHash != null && salt != null;

  String get firstName {
    final String trimmed = name.trim();
    return trimmed.isEmpty ? 'there' : trimmed.split(RegExp(r'\s+')).first;
  }

  AppUser copyWith({String? passwordHash, String? salt}) => AppUser(
    id: id,
    name: name,
    email: email,
    role: role,
    provider: provider,
    passwordHash: passwordHash ?? this.passwordHash,
    salt: salt ?? this.salt,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'email': email,
    'role': role.name,
    'provider': provider.name,
    'passwordHash': passwordHash,
    'salt': salt,
  };
}

class QuizQuestion {
  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  }) : assert(correctIndex >= 0, 'correctIndex must not be negative.');

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
    question: json['question'] as String,
    options: List<String>.from(json['options'] as List<dynamic>),
    correctIndex: json['correctIndex'] as int,
  );

  final String question;
  final List<String> options;
  final int correctIndex;

  /// Runtime validation, because asserts are stripped in release builds.
  bool get isValid =>
      options.length >= 2 && correctIndex >= 0 && correctIndex < options.length;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'question': question,
    'options': options,
    'correctIndex': correctIndex,
  };
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

/// A quiz written by a teacher and shared with every student on the device.
class TeacherQuiz {
  const TeacherQuiz({
    required this.id,
    required this.title,
    required this.description,
    required this.teacherId,
    required this.teacherName,
    required this.questions,
    required this.createdAt,
  });

  factory TeacherQuiz.fromJson(Map<String, dynamic> json) => TeacherQuiz(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    teacherId: json['teacherId'] as String,
    teacherName: json['teacherName'] as String,
    questions: <QuizQuestion>[
      for (final dynamic q in json['questions'] as List<dynamic>)
        QuizQuestion.fromJson(q as Map<String, dynamic>),
    ],
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  final String id;
  final String title;
  final String description;
  final String teacherId;
  final String teacherName;
  final List<QuizQuestion> questions;
  final DateTime createdAt;

  Topic toTopic() => Topic(
    title: title,
    subtitle: description.isEmpty ? 'By $teacherName' : description,
    icon: Icons.assignment_rounded,
    questions: questions,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'title': title,
    'description': description,
    'teacherId': teacherId,
    'teacherName': teacherName,
    'questions': <Map<String, dynamic>>[
      for (final QuizQuestion q in questions) q.toJson(),
    ],
    'createdAt': createdAt.toIso8601String(),
  };
}

/// One finished run of a [TeacherQuiz] by a student.
class QuizAttempt {
  const QuizAttempt({
    required this.quizId,
    required this.studentId,
    required this.studentName,
    required this.score,
    required this.total,
    required this.completedAt,
  });

  factory QuizAttempt.fromJson(Map<String, dynamic> json) => QuizAttempt(
    quizId: json['quizId'] as String,
    studentId: json['studentId'] as String,
    studentName: json['studentName'] as String,
    score: json['score'] as int,
    total: json['total'] as int,
    completedAt: DateTime.parse(json['completedAt'] as String),
  );

  final String quizId;
  final String studentId;
  final String studentName;
  final int score;
  final int total;
  final DateTime completedAt;

  double get fraction => total <= 0 ? 0 : score / total;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'quizId': quizId,
    'studentId': studentId,
    'studentName': studentName,
    'score': score,
    'total': total,
    'completedAt': completedAt.toIso8601String(),
  };
}
