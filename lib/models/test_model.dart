import 'package:cloud_firestore/cloud_firestore.dart';

enum QuestionType { mcq, trueFalse, shortAnswer }

class QuestionModel {
  final String question;
  final List<String>? options;
  final String correctAnswer;
  final QuestionType type;

  QuestionModel({
    required this.question,
    this.options,
    required this.correctAnswer,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'type': type.index,
    };
  }

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      question: map['question'] ?? '',
      options: map['options'] != null ? List<String>.from(map['options']) : null,
      correctAnswer: map['correctAnswer'] ?? '',
      type: QuestionType.values[map['type'] ?? 0],
    );
  }
}

class TestModel {
  final String id;
  final String title;
  final String subject;
  final int duration; // in minutes
  final int totalMarks;
  final List<QuestionModel> questions;
  final String createdBy;
  final DateTime createdAt;

  TestModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.duration,
    required this.totalMarks,
    required this.questions,
    required this.createdBy,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'duration': duration,
      'totalMarks': totalMarks,
      'questions': questions.map((q) => q.toMap()).toList(),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory TestModel.fromMap(Map<String, dynamic> map, String id) {
    return TestModel(
      id: id,
      title: map['title'] ?? '',
      subject: map['subject'] ?? '',
      duration: map['duration'] ?? 0,
      totalMarks: map['totalMarks'] ?? 0,
      questions: (map['questions'] as List).map((q) => QuestionModel.fromMap(q)).toList(),
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
