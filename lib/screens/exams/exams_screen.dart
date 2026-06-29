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
    final student = auth.studentModel;
    final db = DatabaseService();

    if (student == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<String> interests = ['all', student.branch, ...student.enrolledCourses].toSet().toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("Tests & Exams", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          bottom: const TabBar(
            labelColor: Color(0xFFFF5252),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFFFF5252),
            tabs: [
              Tab(text: "Upcoming"),
              Tab(text: "Finished"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTestsList(db, interests, true),
            _buildTestsList(db, interests, false),
          ],
        ),
      ),
    );
  }

  Widget _buildTestsList(DatabaseService db, List<String> interests, bool isUpcoming) {
    return StreamBuilder<List<HubEvent>>(
      stream: db.getEvents(interests),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFF5252)));
        }

        final now = DateTime.now();
        // A test is "Upcoming" if it is completed (posted) and the time hasn't passed or it's within range
        final tests = (snapshot.data ?? [])
            .where((e) => e.type == 'test' && e.isCompleted)
            .where((e) => isUpcoming 
                ? e.dateTime.add(const Duration(hours: 4)).isAfter(now) 
                : e.dateTime.add(const Duration(hours: 4)).isBefore(now))
            .toList();

        if (tests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_turned_in_rounded, size: 64, color: Colors.grey[200]),
                const SizedBox(height: 16),
                Text(
                  isUpcoming ? "No upcoming exams found." : "No finished exams found.",
                  style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: tests.length,
          itemBuilder: (context, index) => _testCard(context, tests[index], isUpcoming),
        );
      },
    );
  }

  Widget _testCard(BuildContext context, HubEvent test, bool isUpcoming) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFFF5252).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
                  child: const Icon(Icons.quiz_rounded, color: Color(0xFFFF5252)),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(test.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(
                        "${DateFormat('MMM d, hh:mm a').format(test.dateTime)} • ${test.questions.length} Qs",
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isUpcoming)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TakeTestScreen(test: test)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                child: const Text("START TEST", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
        ],
      ),
    );
  }
}
