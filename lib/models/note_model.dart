import 'package:cloud_firestore/cloud_firestore.dart';

enum NoteType { file, custom, link }

class NoteModel {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String? content;
  final String? fileUrl;
  final String? link;
  final NoteType type;
  final String uploadedBy;
  final DateTime uploadDate;

  NoteModel({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    this.content,
    this.fileUrl,
    this.link,
    required this.type,
    required this.uploadedBy,
    required this.uploadDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'subject': subject,
      'content': content,
      'fileUrl': fileUrl,
      'link': link,
      'type': type.index,
      'uploadedBy': uploadedBy,
      'uploadDate': Timestamp.fromDate(uploadDate),
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map, String id) {
    return NoteModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      subject: map['subject'] ?? '',
      content: map['content'],
      fileUrl: map['fileUrl'],
      link: map['link'],
      type: NoteType.values[map['type'] ?? 0],
      uploadedBy: map['uploadedBy'] ?? '',
      uploadDate: (map['uploadDate'] as Timestamp).toDate(),
    );
  }
}
