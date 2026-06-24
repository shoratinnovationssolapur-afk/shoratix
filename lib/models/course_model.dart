class CourseModel {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String instructor;
  final List<String> videoUrls;
  final List<String> notesUrls;

  CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.instructor,
    this.videoUrls = const [],
    this.notesUrls = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'instructor': instructor,
      'videoUrls': videoUrls,
      'notesUrls': notesUrls,
    };
  }

  factory CourseModel.fromMap(Map<String, dynamic> map) {
    return CourseModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      instructor: map['instructor'] ?? '',
      videoUrls: List<String>.from(map['videoUrls'] ?? []),
      notesUrls: List<String>.from(map['notesUrls'] ?? []),
    );
  }
}
