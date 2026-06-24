import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<UserAuthProvider>(context);
    final db = DatabaseService();
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: interests.length <= 1 && student == null && trainer == null
          ? const Center(child: Text("Please login to see notifications"))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: db.getNotifications(interests),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFFF5252)));
                }
                
                final notifications = snapshot.data ?? [];

                if (notifications.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text("No notifications yet.", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    final DateTime time = DateTime.parse(n['time']);
                    
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5252).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_active, color: Color(0xFFFF5252), size: 20),
                        ),
                        title: Text(n['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(n['message'] ?? '', style: TextStyle(color: Colors.grey[800], fontSize: 13)),
                            const SizedBox(height: 6),
                            Text(
                              DateFormat('MMM d, h:mm a').format(time),
                              style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w600),
                            ),
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
}
