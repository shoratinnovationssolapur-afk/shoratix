import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../models/announcement_model.dart';
import '../../providers/auth_provider.dart';

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
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
      appBar: AppBar(
        title: const Text("Announcements"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<List<AnnouncementModel>>(
        stream: db.getAnnouncements(interests),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final items = snapshot.data!;
          if (items.isEmpty) return const Center(child: Text("No new announcements."));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 15.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getColorForType(item.type).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              item.type.toUpperCase(),
                              style: TextStyle(color: _getColorForType(item.type), fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            DateFormat('MMM d, yyyy').format(item.date),
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(item.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(item.message, style: const TextStyle(color: Colors.black87)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'holiday': return Colors.orange;
      case 'batch': return Colors.blue;
      case 'workshop': return Colors.purple;
      case 'placement': return Colors.green;
      default: return Colors.red;
    }
  }
}
