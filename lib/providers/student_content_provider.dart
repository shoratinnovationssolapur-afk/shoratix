import 'package:flutter/material.dart';
import 'package:shorat_student_hub/models/content_models.dart';
import 'package:shorat_student_hub/services/branch_content_service.dart';

class StudentContentProvider extends ChangeNotifier {
  final BranchContentService _service = BranchContentService();

  Stream<List<NoteModel>> notesStream(String branch) => _service.notesForBranch(branch);
  Stream<List<VideoModel>> videosStream(String branch) => _service.videosForBranch(branch);
  Stream<List<LinkModel>> linksStream(String branch) => _service.linksForBranch(branch);
  Stream<List<TestModel>> testsStream(String branch) => _service.testsForBranch(branch);
}
