class TrainerModel {
  final String uid;
  final String name;
  final String email;
  final String branch;
  final String role;

  TrainerModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.branch,
    this.role = 'trainer',
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'branch': branch,
      'role': role,
    };
  }

  factory TrainerModel.fromMap(Map<String, dynamic> map) {
    return TrainerModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      branch: map['branch'] ?? '',
      role: map['role'] ?? 'trainer',
    );
  }
}

class TestQuestion {
  final String question;
  final String type; // 'mcq' or 'subjective'
  final List<String>? options;
  final int? correctOptionIndex;

  TestQuestion({
    required this.question, 
    this.type = 'subjective', 
    this.options, 
    this.correctOptionIndex
  });

  Map<String, dynamic> toMap() => {
    'question': question,
    'type': type,
    'options': options,
    'correctOptionIndex': correctOptionIndex,
  };

  factory TestQuestion.fromMap(Map<String, dynamic> map) => TestQuestion(
    question: map['question'] ?? '',
    type: map['type'] ?? 'subjective',
    options: map['options'] != null ? List<String>.from(map['options']) : null,
    correctOptionIndex: map['correctOptionIndex'],
  );
}

class HubEvent {
  final String id;
  final String title;
  final String description;
  final DateTime dateTime;
  final String type;
  final String branch;
  final String meetLink;
  final List<TestQuestion> questions;
  final bool isCompleted;

  HubEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.type,
    required this.branch,
    this.meetLink = '',
    this.questions = const [],
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'type': type,
      'branch': branch,
      'meetLink': meetLink,
      'questions': questions.map((q) => q.toMap()).toList(),
      'isCompleted': isCompleted,
    };
  }

  factory HubEvent.fromMap(Map<String, dynamic> map) {
    return HubEvent(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dateTime: DateTime.parse(map['dateTime']),
      type: map['type'] ?? 'meeting',
      branch: map['branch'] ?? '',
      meetLink: map['meetLink'] ?? '',
      questions: (map['questions'] as List? ?? [])
          .map((q) => TestQuestion.fromMap(q as Map<String, dynamic>))
          .toList(),
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}
