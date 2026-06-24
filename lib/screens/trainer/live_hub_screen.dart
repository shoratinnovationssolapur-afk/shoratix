import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../models/trainer_model.dart';

class LiveHubScreen extends StatelessWidget {
  const LiveHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<UserAuthProvider>(context);
    final trainer = auth.trainerModel;
    final List<String> interests = [trainer?.branch ?? 'all', 'all'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Live Hub Management", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton.icon(
              onPressed: () => _showScheduleDialog(context),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("CREATE NEW LIVE SESSION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("SCHEDULED SESSIONS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5)),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<List<HubEvent>>(
              stream: DatabaseService().getEvents(interests),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFFF5252)));
                }
                final events = snapshot.data?.where((e) => e.type == 'meeting').toList() ?? [];
                if (events.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.video_call_rounded, size: 60, color: Colors.grey),
                        Text("No sessions scheduled.", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
                      ),
                      elevation: 0,
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFFF5252),
                          child: Icon(Icons.videocam, color: Colors.white, size: 20),
                        ),
                        title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${DateFormat('MMM d, hh:mm a').format(event.dateTime)} • ${event.branch}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteEvent(event.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _deleteEvent(String id) async {
    await DatabaseService().deleteEvent(id);
  }

  void _showScheduleDialog(BuildContext context) {
    final titleController = TextEditingController();
    final linkController = TextEditingController();
    final branchController = TextEditingController();
    final auth = Provider.of<UserAuthProvider>(context, listen: false);
    final trainer = auth.trainerModel;

    if (trainer != null && trainer.branch.isNotEmpty) {
      branchController.text = trainer.branch;
    }

    showDialog(
      context: context,
      builder: (context) {
        bool isScheduling = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Schedule Live Session"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: titleController, decoration: const InputDecoration(labelText: "Session Title")),
                    TextField(controller: linkController, decoration: const InputDecoration(labelText: "Meeting Link (Zoom/Meet)")),
                    TextField(controller: branchController, decoration: const InputDecoration(labelText: "Branch")),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: isScheduling ? null : () async {
                    if (titleController.text.isEmpty) return;

                    setState(() => isScheduling = true);
                    try {
                      final event = HubEvent(
                        id: "EVT-${DateTime.now().millisecondsSinceEpoch}",
                        title: titleController.text,
                        description: "Live Session for ${branchController.text}",
                        dateTime: DateTime.now().add(const Duration(hours: 1)), // Default to 1 hour from now
                        type: 'meeting',
                        branch: branchController.text.trim(),
                        meetLink: linkController.text,
                      );

                      await DatabaseService().scheduleEvent(event);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Live session scheduled!")),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                        );
                      }
                    } finally {
                      if (context.mounted) setState(() => isScheduling = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  child: isScheduling 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("Schedule"),
                ),
              ],
            );
          }
        );
      }
    );
  }
}
