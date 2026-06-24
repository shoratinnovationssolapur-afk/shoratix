import 'package:flutter/material.dart';
import '../../models/course_model.dart';

class CourseDetailsScreen extends StatelessWidget {
  final CourseModel course;
  const CourseDetailsScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(course.title),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Colors.red,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.red,
            tabs: [
              Tab(icon: Icon(Icons.play_circle_outline), text: "Videos"),
              Tab(icon: Icon(Icons.description_outlined), text: "Notes"),
              Tab(icon: Icon(Icons.assignment_outlined), text: "Tasks"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildVideoList(),
            _buildNotesList(),
            _buildTasksList(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: course.videoUrls.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const Icon(Icons.play_arrow, color: Colors.red),
            title: Text("Lesson ${index + 1}: Module Title"),
            subtitle: const Text("Duration: 15:00"),
            trailing: const Icon(Icons.download, size: 20),
            onTap: () {
              // Open Video Player
            },
          ),
        );
      },
    );
  }

  Widget _buildNotesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: course.notesUrls.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.orange),
            title: Text("Study Material ${index + 1}"),
            subtitle: const Text("PDF Document"),
            trailing: const Icon(Icons.open_in_new),
            onTap: () {
              // Open PDF
            },
          ),
        );
      },
    );
  }

  Widget _buildTasksList() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text("No assignments yet", style: TextStyle(color: Colors.grey, fontSize: 18)),
        ],
      ),
    );
  }
}
