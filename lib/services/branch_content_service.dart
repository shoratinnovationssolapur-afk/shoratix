import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shorat_student_hub/models/content_models.dart';

class BranchContentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<NoteModel>> notesForBranch(String branch) {
    return _db.collection('notes')
      .where('branch', isEqualTo: branch)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((d) => NoteModel.fromMap(d.data() as Map<String, dynamic>)).toList());
  }

  Stream<List<VideoModel>> videosForBranch(String branch) {
    return _db.collection('videos')
      .where('branch', isEqualTo: branch)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((d) => VideoModel.fromMap(d.data() as Map<String, dynamic>)).toList());
  }

  Stream<List<LinkModel>> linksForBranch(String branch) {
    return _db.collection('links')
      .where('branch', isEqualTo: branch)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((d) => LinkModel.fromMap(d.data() as Map<String, dynamic>)).toList());
  }

  Stream<List<TestModel>> testsForBranch(String branch) {
    return _db.collection('tests')
      .where('branch', isEqualTo: branch)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((d) => TestModel.fromMap(d.data() as Map<String, dynamic>)).toList());
  }
}
