class AnnouncementModel {
  final String title;
  final String message;
  final DateTime date;
  final String type; // holiday, batch, workshop, placement
  final String branch;

  AnnouncementModel({
    required this.title,
    required this.message,
    required this.date,
    required this.type,
    this.branch = 'all',
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'date': date.toIso8601String(),
      'type': type,
      'branch': branch,
    };
  }

  factory AnnouncementModel.fromMap(Map<String, dynamic> map) {
    return AnnouncementModel(
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      date: DateTime.parse(map['date']),
      type: map['type'] ?? 'general',
      branch: map['branch'] ?? 'all',
    );
  }
}

