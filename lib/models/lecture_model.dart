import 'package:cloud_firestore/cloud_firestore.dart';

class LectureModel {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String videoUrl;
  final String trainerName;
  final String duration;
  final DateTime uploadDate;

  LectureModel({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.videoUrl,
    required this.trainerName,
    required this.duration,
    required this.uploadDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'subject': subject,
      'videoUrl': videoUrl,
      'trainerName': trainerName,
      'duration': duration,
      'uploadDate': Timestamp.fromDate(uploadDate),
    };
  }

  factory LectureModel.fromMap(Map<String, dynamic> map, String id) {
    return LectureModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      subject: map['subject'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      trainerName: map['trainerName'] ?? '',
      duration: map['duration'] ?? '',
      uploadDate: (map['uploadDate'] as Timestamp).toDate(),
    );
  }
}
