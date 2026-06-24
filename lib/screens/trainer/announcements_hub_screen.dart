import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../models/announcement_model.dart';

class AnnouncementsHubScreen extends StatelessWidget {
  const AnnouncementsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<UserAuthProvider>(context);
    final trainer = auth.trainerModel;
    final List<String> interests = [trainer?.branch ?? 'all', 'all'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Announcements", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton.icon(
              onPressed: () => _showPostDialog(context),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("POST NEW ANNOUNCEMENT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              child: Text("RECENT ANNOUNCEMENTS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5)),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<List<AnnouncementModel>>(
              stream: DatabaseService().getAnnouncements(interests),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFFF5252)));
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.campaign_rounded, size: 60, color: Colors.grey),
                        Text("No announcements posted.", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
                      ),
                      elevation: 0,
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.black,
                          child: Icon(Icons.notifications_active, color: Colors.white, size: 20),
                        ),
                        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${item.message}\nBranch: ${item.branch}"),
                        isThreeLine: true,
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

  void _showPostDialog(BuildContext context) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    final branchController = TextEditingController();
    String selectedType = 'general';
    final auth = Provider.of<UserAuthProvider>(context, listen: false);
    final trainer = auth.trainerModel;

    if (trainer != null && trainer.branch.isNotEmpty) {
      branchController.text = trainer.branch;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool isPosting = false;
          return AlertDialog(
            title: const Text("Post Announcement"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
                  TextField(controller: messageController, decoration: const InputDecoration(labelText: "Message"), maxLines: 3),
                  TextField(controller: branchController, decoration: const InputDecoration(labelText: "Branch (or 'all')")),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: selectedType,
                    isExpanded: true,
                    items: ['general', 'holiday', 'batch', 'workshop', 'placement'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => selectedType = val!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: isPosting ? null : () async {
                  if (titleController.text.isEmpty) return;

                  setState(() => isPosting = true);
                  try {
                    final announcement = AnnouncementModel(
                      title: titleController.text,
                      message: messageController.text,
                      date: DateTime.now(),
                      type: selectedType,
                      branch: branchController.text.trim(),
                    );

                    await DatabaseService().postAnnouncement(announcement);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Announcement posted successfully!")),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                      );
                    }
                  } finally {
                    if (context.mounted) setState(() => isPosting = false);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                child: isPosting 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text("Post"),
              ),
            ],
          );
        }
      ),
    );
  }
}
