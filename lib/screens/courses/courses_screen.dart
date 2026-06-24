import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../models/course_model.dart';
import 'course_details_screen.dart';

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<UserAuthProvider>(context);
    final db = DatabaseService();
    final student = auth.studentModel;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text("Learning Resources", style: TextStyle(fontWeight: FontWeight.w900)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Color(0xFFFF5252),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFFFF5252),
            indicatorWeight: 3,
            tabs: [
              Tab(text: "Recorded Lectures"),
              Tab(text: "Global Courses"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildBranchLectures(db, student),
            _buildGlobalCourses(db),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchLectures(DatabaseService db, dynamic user) {
    List<String> interests = ['all'];
    if (user != null) {
      if (user.branch.isNotEmpty) interests.add(user.branch);
      if (user.enrolledCourses != null) interests.addAll(List<String>.from(user.enrolledCourses));
    }
    interests = interests.toSet().toList();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: db.getLectures(interests),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFF5252)));
        }

        final lectures = snapshot.data ?? [];

        if (lectures.isEmpty) {
          return const Center(child: Text("No branch lectures posted yet.", style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: lectures.length,
          itemBuilder: (context, index) {
            final lecture = lectures[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5252).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.play_circle_fill, color: Color(0xFFFF5252)),
                ),
                title: Text(lecture['title'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Branch Lecture • Recorded"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {}, // Open Lecture URL
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGlobalCourses(DatabaseService db) {
    return StreamBuilder<List<CourseModel>>(
      stream: db.courses,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFF5252)));
        }

        final courses = snapshot.data ?? [];
        
        if (courses.isEmpty) {
          return const Center(child: Text("No global courses available."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(10),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    course.thumbnailUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.red[50],
                      width: 60,
                      height: 60,
                      child: const Icon(Icons.book, color: Color(0xFFFF5252)),
                    ),
                  ),
                ),
                title: Text(
                  course.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("${course.instructor} • ${course.videoUrls.length} Lessons"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CourseDetailsScreen(course: course),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
