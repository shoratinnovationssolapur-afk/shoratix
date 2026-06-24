import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shorat_student_hub/models/content_models.dart';
import 'package:shorat_student_hub/services/notification_service.dart';

class TrainerUploadService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final NotificationService _notifier = NotificationService();

  Future<String> _uploadFile(File file, String folder, String fileName) async {
    final ref = _storage.ref().child(folder).child(fileName);
    final task = ref.putFile(file);
    final snap = await task;
    return await snap.ref.getDownloadURL();
  }

  Future<void> uploadNote({required NoteModel note}) async {
    final col = _db.collection('notes');
    await col.doc(note.id).set(note.toMap());
    await _notifier.createBranchNotification(branch: note.branch, title: 'New ${note.branch} Notes Uploaded', message: note.title);
  }

  Future<void> uploadVideo({required VideoModel video}) async {
    final col = _db.collection('videos');
    await col.doc(video.id).set(video.toMap());
    await _notifier.createBranchNotification(branch: video.branch, title: 'New ${video.branch} Video Uploaded', message: video.title);
  }

  Future<void> uploadLink({required LinkModel link}) async {
    final col = _db.collection('links');
    await col.doc(link.id).set(link.toMap());
    await _notifier.createBranchNotification(branch: link.branch, title: 'New Link Shared', message: link.title);
  }

  Future<void> uploadTest({required TestModel test}) async {
    final col = _db.collection('tests');
    await col.doc(test.id).set(test.toMap());
    await _notifier.createBranchNotification(branch: test.branch, title: 'New ${test.branch} Test Published', message: test.title);
  }
}
