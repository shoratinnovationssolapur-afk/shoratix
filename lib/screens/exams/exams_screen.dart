import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../models/trainer_model.dart';

import 'take_test_screen.dart';

class ExamsScreen extends StatelessWidget {
  const ExamsScreen({super.key});

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
          title: const Text("Tests & Exams", style: TextStyle(fontWeight: FontWeight.w900)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Color(0xFFFF5252),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFFFF5252),
            indicatorWeight: 3,
            tabs: [
              Tab(text: "Upcoming Tests"),
              Tab(text: "Past Tests"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTestsList(db, student, true),
            _buildTestsList(db, student, false),
          ],
        ),
      ),
    );
  }

  Widget _buildTestsList(DatabaseService db, dynamic user, bool isUpcoming) {
    final List<String> interests = ['all'];
    if (user != null) {
      if (user.branch != null && user.branch.isNotEmpty) interests.add(user.branch);
      if (user.enrolledCourses != null) interests.addAll(List<String>.from(user.enrolledCourses));
    }
    final List<String> finalInterests = interests.toSet().toList();

    return StreamBuilder<List<HubEvent>>(
      stream: db.getEvents(finalInterests),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFF5252)));
        }

        final now = DateTime.now();
        final List<HubEvent> tests = (snapshot.data ?? [])
            .where((e) => e.type == 'test')
            .where((e) => isUpcoming ? e.dateTime.isAfter(now) : e.dateTime.isBefore(now))
            .toList();

        if (tests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  isUpcoming ? "No upcoming tests scheduled." : "No past tests found.",
                  style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tests.length,
          itemBuilder: (context, index) {
            final test = tests[index];
            return _testCard(context, test, isUpcoming);
          },
        );
      },
    );
  }

  Widget _testCard(BuildContext context, HubEvent test, bool isUpcoming) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (isUpcoming ? Colors.orange : Colors.green).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isUpcoming ? "UPCOMING" : "COMPLETED",
                    style: TextStyle(
                      color: isUpcoming ? Colors.orange : Colors.green,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Text(
                  DateFormat('MMM d, yyyy').format(test.dateTime),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              test.title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 5),
            Text(
              test.description,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                const Icon(Icons.access_time_filled, size: 16, color: Color(0xFFFF5252)),
                const SizedBox(width: 8),
                Text(
                  DateFormat('hh:mm a').format(test.dateTime),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                if (isUpcoming)
                  ElevatedButton(
                    onPressed: () async {
                      if (test.meetLink.isNotEmpty) {
                        final uri = Uri.parse(test.meetLink);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => TakeTestScreen(test: test)),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(test.meetLink.isNotEmpty ? "OPEN LINK" : "START TEST", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
