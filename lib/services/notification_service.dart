import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createBranchNotification({required String branch, required String title, required String message}) async {
    await _db.collection('notifications').add({
      'title': title,
      'message': message,
      'branch': branch,
      'time': DateTime.now().toIso8601String(),
    });
  }
}
