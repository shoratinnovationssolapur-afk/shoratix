import 'package:cloud_firestore/cloud_firestore.dart';

class LiveSessionModel {
  final String id;
  final String title;
  final DateTime dateTime;
  final String meetingLink;
  final String trainerName;
  final String subject;

  LiveSessionModel({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.meetingLink,
    required this.trainerName,
    required this.subject,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'dateTime': Timestamp.fromDate(dateTime),
      'meetingLink': meetingLink,
      'trainerName': trainerName,
      'subject': subject,
    };
  }

  factory LiveSessionModel.fromMap(Map<String, dynamic> map, String id) {
    return LiveSessionModel(
      id: id,
      title: map['title'] ?? '',
      dateTime: (map['dateTime'] as Timestamp).toDate(),
      meetingLink: map['meetingLink'] ?? '',
      trainerName: map['trainerName'] ?? '',
      subject: map['subject'] ?? '',
    );
  }
}
