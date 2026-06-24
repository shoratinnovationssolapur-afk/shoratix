class NoteModel {
  final String id;
  final String title;
  final String description;
  final String fileUrl;
  final String fileType;
  final String branch;
  final String uploadedBy;
  final String uploadedByName;
  final DateTime createdAt;

  NoteModel({
    required this.id,
    required this.title,
    required this.description,
    required this.fileUrl,
    required this.fileType,
    required this.branch,
    required this.uploadedBy,
    required this.uploadedByName,
    required this.createdAt,
  });

  factory NoteModel.fromMap(Map<String, dynamic> map) => NoteModel(
        id: map['id'] ?? '',
        title: map['title'] ?? '',
        description: map['description'] ?? '',
        fileUrl: map['fileUrl'] ?? '',
        fileType: map['fileType'] ?? '',
        branch: map['branch'] ?? 'all',
        uploadedBy: map['uploadedBy'] ?? '',
        uploadedByName: map['uploadedByName'] ?? '',
        createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'fileUrl': fileUrl,
        'fileType': fileType,
        'branch': branch,
        'uploadedBy': uploadedBy,
        'uploadedByName': uploadedByName,
        'createdAt': createdAt.toIso8601String(),
      };
}

class VideoModel {
  final String id;
  final String title;
  final String description;
  final String videoUrl;
  final String thumbnailUrl;
  final String branch;
  final String uploadedBy;
  final String uploadedByName;
  final DateTime createdAt;

  VideoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.branch,
    required this.uploadedBy,
    required this.uploadedByName,
    required this.createdAt,
  });

  factory VideoModel.fromMap(Map<String, dynamic> map) => VideoModel(
        id: map['id'] ?? '',
        title: map['title'] ?? '',
        description: map['description'] ?? '',
        videoUrl: map['videoUrl'] ?? '',
        thumbnailUrl: map['thumbnailUrl'] ?? '',
        branch: map['branch'] ?? 'all',
        uploadedBy: map['uploadedBy'] ?? '',
        uploadedByName: map['uploadedByName'] ?? '',
        createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'videoUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl,
        'branch': branch,
        'uploadedBy': uploadedBy,
        'uploadedByName': uploadedByName,
        'createdAt': createdAt.toIso8601String(),
      };
}

class LinkModel {
  final String id;
  final String title;
  final String description;
  final String link;
  final String branch;
  final String uploadedBy;
  final String uploadedByName;
  final DateTime createdAt;

  LinkModel({
    required this.id,
    required this.title,
    required this.description,
    required this.link,
    required this.branch,
    required this.uploadedBy,
    required this.uploadedByName,
    required this.createdAt,
  });

  factory LinkModel.fromMap(Map<String, dynamic> map) => LinkModel(
        id: map['id'] ?? '',
        title: map['title'] ?? '',
        description: map['description'] ?? '',
        link: map['link'] ?? '',
        branch: map['branch'] ?? 'all',
        uploadedBy: map['uploadedBy'] ?? '',
        uploadedByName: map['uploadedByName'] ?? '',
        createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'link': link,
        'branch': branch,
        'uploadedBy': uploadedBy,
        'uploadedByName': uploadedByName,
        'createdAt': createdAt.toIso8601String(),
      };
}

class TestModel {
  final String id;
  final String title;
  final String description;
  final String branch;
  final int duration;
  final int totalMarks;
  final String createdBy;
  final DateTime createdAt;

  TestModel({
    required this.id,
    required this.title,
    required this.description,
    required this.branch,
    required this.duration,
    required this.totalMarks,
    required this.createdBy,
    required this.createdAt,
  });

  factory TestModel.fromMap(Map<String, dynamic> map) => TestModel(
        id: map['id'] ?? '',
        title: map['title'] ?? '',
        description: map['description'] ?? '',
        branch: map['branch'] ?? 'all',
        duration: map['duration'] ?? 0,
        totalMarks: map['totalMarks'] ?? 0,
        createdBy: map['createdBy'] ?? '',
        createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'branch': branch,
        'duration': duration,
        'totalMarks': totalMarks,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
      };
}
