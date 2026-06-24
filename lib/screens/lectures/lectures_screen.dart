import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';

class LecturesScreen extends StatelessWidget {
  const LecturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<UserAuthProvider>(context);
    final student = auth.studentModel;
    final trainer = auth.trainerModel;

    List<String> interests = ['all'];
    if (student != null) {
      if (student.branch.isNotEmpty) interests.add(student.branch);
      interests.addAll(student.enrolledCourses);
    } else if (trainer != null) {
      if (trainer.branch.isNotEmpty) interests.add(trainer.branch);
    }
    interests = interests.toSet().toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Recorded Lectures", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: DatabaseService().getLectures(interests),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFF5252)));
          }

          final allResources = snapshot.data ?? [];
          final lectures = allResources.where((res) => res['type'] == 'recorded').toList();

          if (lectures.isEmpty) {
            return const Center(child: Text("No recorded lectures found for your branch."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lectures.length,
            itemBuilder: (context, index) {
              return _lectureCard(context, lectures[index]);
            },
          );
        },
      ),
    );
  }

  Widget _lectureCard(BuildContext context, Map<String, dynamic> lecture) {
    final url = lecture['url'] ?? '';
    String thumbnailUrl = "https://img.youtube.com/vi/placeholder/0.jpg";
    
    // Try to extract YouTube ID for thumbnail
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      final regExp = RegExp(r"(?:v=|\/)([0-9A-Za-z_-]{11})");
      final match = regExp.firstMatch(url);
      if (match != null) {
        thumbnailUrl = "https://img.youtube.com/vi/${match.group(1)}/0.jpg";
      }
    }

    return GestureDetector(
      onTap: () async {
        if (url.isNotEmpty) {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                image: DecorationImage(
                  image: NetworkImage(thumbnailUrl),
                  fit: BoxFit.cover,
                  opacity: 0.7,
                ),
              ),
              child: const Center(
                child: Icon(Icons.play_circle_fill, color: Colors.white, size: 60),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lecture['title'] ?? 'Untitled Lecture', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.account_tree_rounded, size: 14, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text("Branch: ${lecture['branch'] ?? 'All'}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const Spacer(),
                      const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(
                        lecture['date'] != null 
                          ? (lecture['date'] as String).split('T')[0]
                          : "Unknown", 
                        style: const TextStyle(color: Colors.grey, fontSize: 12)
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

