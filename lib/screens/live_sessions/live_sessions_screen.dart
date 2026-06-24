import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shorat_student_hub/providers/auth_provider.dart';
import 'package:shorat_student_hub/services/database_service.dart';
import 'package:shorat_student_hub/models/trainer_model.dart';

class LiveSessionsScreen extends StatelessWidget {
  const LiveSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<UserAuthProvider>(context);
    final student = auth.studentModel;
    
    List<String> interests = ['all'];
    if (student != null) {
      if (student.branch.isNotEmpty) interests.add(student.branch);
      interests.addAll(student.enrolledCourses);
    }
    interests = interests.toSet().toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Live Classes", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<List<HubEvent>>(
        stream: DatabaseService().getEvents(interests),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFF5252)));
          }

          final events = snapshot.data ?? [];
          final liveClasses = events.where((e) => e.type == 'meeting' && !e.isCompleted).toList();

          if (liveClasses.isEmpty) {
            return const Center(child: Text("No live sessions scheduled for your branch."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: liveClasses.length,
            itemBuilder: (context, index) {
              return _liveSessionCard(context, liveClasses[index]);
            },
          );
        },
      ),
    );
  }

  Widget _liveSessionCard(BuildContext context, HubEvent event) {
    final bool isNow = event.dateTime.difference(DateTime.now()).inMinutes.abs() < 60;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: (isNow ? const Color(0xFFFF5252) : Colors.blue).withValues(alpha: 0.3),
            blurRadius: 15, 
            offset: const Offset(0, 8)
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isNow ? "LIVE NOW" : "UPCOMING SESSION",
                style: TextStyle(
                  color: isNow ? const Color(0xFFFF5252) : Colors.blue, 
                  fontWeight: FontWeight.w900, 
                  fontSize: 10, 
                  letterSpacing: 2
                ),
              ),
              Icon(
                Icons.live_tv_rounded, 
                color: isNow ? const Color(0xFFFF5252) : Colors.blue, 
                size: 20
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            event.title,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "${DateFormat('MMM d, hh:mm a').format(event.dateTime)} • Live Session",
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              if (event.meetLink.isNotEmpty) {
                final uri = Uri.parse(event.meetLink);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isNow ? const Color(0xFFFF5252) : Colors.grey[800],
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: Text(
              isNow ? "JOIN CLASS NOW" : "NOT STARTED YET", 
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
            ),
          ),
        ],
      ),
    );
  }
}

