import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/database_service.dart';
import '../../models/trainer_model.dart';
import '../admin/create_test_screen.dart';

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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Image.asset('assets/images/logo.png', height: 35),
        actions: [
          IconButton(
            onPressed: () async {
              await auth.signOut();

              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                      (route) => false,
                );
              }
            },
            icon: const Icon(
              Icons.logout_rounded,
              color: Colors.black,
              size: 22,
            ),
          )
        ],
      ),
      body: trainer == null 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5252)))
        : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Hero
                _buildHero(trainer),
                
                const SizedBox(height: 35),
                
                const Text("ADMINISTRATIVE TOOLS", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 11)),
                const SizedBox(height: 20),
                
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.4,
                  children: [
                    _actionCard(context, "Live Classes", Icons.video_call_rounded, const Color(0xFFFF5252), () => _showScheduleDialog(context, trainer.branch, 'meeting')),
                    _actionCard(context, "Exams/Tests", Icons.quiz_rounded, Colors.black, () => _showScheduleDialog(context, trainer.branch, 'test')), 
                    _actionCard(context, "Notes & PDF", Icons.description_rounded, const Color(0xFFFF5252), () => _showPostResourceDialog(context, trainer.branch, 'notes')),
                    _actionCard(context, "Recorded Lectures", Icons.video_library_rounded, Colors.black, () => _showPostResourceDialog(context, trainer.branch, 'recorded')),
                    _actionCard(context, "Announcements", Icons.campaign_rounded, const Color(0xFFFF5252), () => _showAnnouncementDialog(context, trainer.branch)),
                    _actionCard(context, "Placements", Icons.work_rounded, Colors.black, () {}),
                  ],
                ),

                const SizedBox(height: 40),
                
                const Text("RECENTLY SCHEDULED", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 11)),
                const SizedBox(height: 15),
                
                StreamBuilder<List<HubEvent>>(
                  stream: _db.getEvents([trainer.branch]),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("No upcoming events", style: TextStyle(color: Colors.grey))));
                    }
                    final events = snapshot.data!.take(5).toList();
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: events.length,
                      itemBuilder: (context, index) => _eventTile(events[index]),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  Widget _buildHero(TrainerModel trainer) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: const Color(0xFFFF5252),
                child: Text(trainer.name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trainer.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(trainer.branch.toUpperCase(), style: const TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            "Hub Controller",
            style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const Text(
            "Manage your branch's digital workspace effortlessly.",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _actionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _eventTile(HubEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Icon(event.type == 'test' ? Icons.assignment_rounded : Icons.videocam_rounded, color: Colors.black, size: 20),
        ),
        title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(DateFormat('MMM d, hh:mm a').format(event.dateTime), style: const TextStyle(fontSize: 11)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
          onPressed: () => _db.deleteEvent(event.id),
        ),
      ),
    );
  }

  void _showScheduleDialog(BuildContext context, String branch, String type) {
    final titleController = TextEditingController();
    final linkController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text("Schedule ${type.toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
            if (type == 'meeting')
              TextField(controller: linkController, decoration: const InputDecoration(labelText: "Meeting Link")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            onPressed: () async {
              if (titleController.text.isEmpty) return;
              final event = HubEvent(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: titleController.text,
                description: "$type session for $branch",
                dateTime: DateTime.now().add(const Duration(hours: 1)),
                type: type,
                branch: branch,
                meetLink: linkController.text,
                isCompleted: type != 'test',
              );

              if (type == 'test') {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => CreateTestScreen(event: event)));
              } else {
                await _db.scheduleEvent(event);
                Navigator.pop(context);
              }
            }, 
            child: Text(type == 'test' ? "ADD QUESTIONS" : "SCHEDULE"),
          ),
        ],
      ),
    );
  }

  void _showPostResourceDialog(BuildContext context, String branch, String type) {
    final titleController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text("Post ${type.toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
            TextField(controller: urlController, decoration: const InputDecoration(labelText: "URL / Link")),
            const SizedBox(height: 20),
            const Text("Or choose a file from your device (Coming Soon)", style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            onPressed: () async {
              if (titleController.text.isEmpty || urlController.text.isEmpty) return;
              await _db.postLecture({
                'title': titleController.text,
                'url': urlController.text,
                'branch': branch,
                'type': type,
                'date': DateTime.now().toIso8601String(),
              });
              Navigator.pop(context);
            }, 
            child: const Text("POST"),
          ),
        ],
      ),
    );
  }

  void _showAnnouncementDialog(BuildContext context, String branch) {
     // Implement Announcement logic
  }
}
