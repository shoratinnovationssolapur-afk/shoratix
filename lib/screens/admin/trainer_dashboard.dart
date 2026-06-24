import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../models/trainer_model.dart';
import '../../routes/app_routes.dart';

import 'create_test_screen.dart';

class TrainerDashboard extends StatefulWidget {
  const TrainerDashboard({super.key});

  @override
  State<TrainerDashboard> createState() => _TrainerDashboardState();
}

class _TrainerDashboardState extends State<TrainerDashboard> {
  final DatabaseService _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<UserAuthProvider>(context);
    final trainer = auth.trainerModel;

    if (trainer == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFFFF5252)),
              const SizedBox(height: 20),
              const Text("Loading Trainer Profile...", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              TextButton(
                onPressed: () {
                  auth.signOut();
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                },
                child: const Text("Logout & Try Again"),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Trainer Admin Hub", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.black),
            onPressed: () {
              auth.signOut();
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTrainerInfo(trainer),
            const SizedBox(height: 30),
            
            const Text("QUICK ACTIONS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.black54)),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _actionCard("Schedule Event", Icons.event_available_rounded, Colors.blue, () => _showScheduleDialog(context, trainer.branch))),
                const SizedBox(width: 15),
                Expanded(child: _actionCard("Post Materials", Icons.library_books_rounded, Colors.green, () => _showPostLectureDialog(context, trainer.branch))),
              ],
            ),
            
            const SizedBox(height: 30),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("UPCOMING EVENTS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.black54)),
                Text(trainer.branch, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFFF5252))),
              ],
            ),
            const SizedBox(height: 15),
            
            StreamBuilder<List<HubEvent>>(
              stream: _db.getEvents([trainer.branch]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFFF5252)));
                }
                
                final events = snapshot.data ?? [];
                if (events.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(30),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        Icon(Icons.event_busy_rounded, size: 40, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        const Text("No events scheduled", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: events.length,
                  itemBuilder: (context, index) => _eventTile(events[index]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainerInfo(TrainerModel trainer) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(color: Color(0xFFFF5252), shape: BoxShape.circle),
            child: const CircleAvatar(radius: 30, backgroundColor: Colors.white, child: Icon(Icons.person, size: 40, color: Colors.black)),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(trainer.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFFF5252).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Text(trainer.branch.toUpperCase(), style: const TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 25),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(25), 
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.black)),
          ],
        ),
      ),
    );
  }

  Widget _eventTile(HubEvent event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (event.type == 'test' ? Colors.orange : Colors.blue).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            event.type == 'test' ? Icons.assignment_rounded : Icons.videocam_rounded, 
            color: event.type == 'test' ? Colors.orange : Colors.blue,
            size: 24,
          ),
        ),
        title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
        subtitle: Text(
          "${DateFormat('MMM d, hh:mm a').format(event.dateTime)} • ${event.type.toUpperCase()}",
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
      ),
    );
  }

  void _showScheduleDialog(BuildContext context, String branch) {
    final titleController = TextEditingController();
    final linkController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        String internalSelectedType = 'meeting';
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            title: const Text("Schedule Event", style: TextStyle(fontWeight: FontWeight.w900)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: "Event Title", labelStyle: TextStyle(fontSize: 13))),
                const SizedBox(height: 15),
                DropdownButton<String>(
                  value: internalSelectedType,
                  isExpanded: true,
                  items: ['meeting', 'test', 'interview'].map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))).toList(),
                  onChanged: (v) => setDialogState(() => internalSelectedType = v!),
                ),
                TextField(controller: linkController, decoration: const InputDecoration(labelText: "Meet Link (optional)", labelStyle: TextStyle(fontSize: 13))),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () async {
                  if (titleController.text.isEmpty) return;
                  final event = HubEvent(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text,
                    description: "Branch: $branch",
                    dateTime: DateTime.now().add(const Duration(hours: 2)),
                    type: internalSelectedType,
                    branch: branch,
                    meetLink: linkController.text,
                    isCompleted: internalSelectedType != 'test',
                  );

                  if (internalSelectedType == 'test') {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => CreateTestScreen(event: event)));
                  } else {
                    await _db.scheduleEvent(event);
                    Navigator.pop(context);
                  }
                },
                child: Text(internalSelectedType == 'test' ? "NEXT: ADD QUESTIONS" : "SCHEDULE", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPostLectureDialog(BuildContext context, String branch) {
    final titleController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text("Post Resources", style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Material Title", labelStyle: TextStyle(fontSize: 13))),
            TextField(controller: urlController, decoration: const InputDecoration(labelText: "URL (Video/PDF Link)", labelStyle: TextStyle(fontSize: 13))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              if (titleController.text.isEmpty || urlController.text.isEmpty) return;
              await _db.postLecture({
                'title': titleController.text,
                'url': urlController.text,
                'branch': branch,
                'timestamp': DateTime.now().toIso8601String(),
                'type': 'resource'
              });
              Navigator.pop(context);
            },
            child: const Text("POST", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
