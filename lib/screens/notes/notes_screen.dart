import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<UserAuthProvider>(context);
    final student = auth.studentModel;
    final trainer = auth.trainerModel;
    
    List<String> userInterests = ['all'];
    if (student != null) {
      if (student.branch.isNotEmpty) userInterests.add(student.branch);
      userInterests.addAll(student.enrolledCourses);
    } else if (trainer != null) {
      if (trainer.branch.isNotEmpty) userInterests.add(trainer.branch);
    }
    final finalInterests = userInterests.toSet().toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Study Notes", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: "Search notes by title...",
                prefixIcon: const Icon(Icons.search, color: Color(0xFFFF5252)),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: DatabaseService().getLectures(finalInterests),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFFF5252)));
                }
                
                final allResources = snapshot.data ?? [];
                final notes = allResources.where((res) {
                  final title = (res['title'] ?? '').toLowerCase();
                  final type = res['type'] ?? '';
                  final matchesSearch = title.contains(_searchQuery.toLowerCase());
                  final isNoteType = type == 'file' || type == 'manual_note' || type == 'link';
                  return matchesSearch && isNoteType;
                }).toList();

                if (notes.isEmpty) {
                  return const Center(child: Text("No notes found for your branch."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    return _noteCard(context, notes[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _noteCard(BuildContext context, Map<String, dynamic> note) {
    final type = note['type'] ?? 'file';
    final title = note['title'] ?? 'Untitled';
    final branch = note['branch'] ?? 'General';

    IconData icon;
    Color iconColor;

    switch (type) {
      case 'manual_note':
        icon = Icons.edit_note_rounded;
        iconColor = Colors.blue;
        break;
      case 'link':
        icon = Icons.link_rounded;
        iconColor = Colors.orange;
        break;
      default:
        icon = Icons.description_rounded;
        iconColor = const Color(0xFFFF5252);
    }

    return GestureDetector(
      onTap: () => _handleNoteTap(context, note),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("Branch: $branch", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _handleNoteTap(BuildContext context, Map<String, dynamic> note) async {
    final type = note['type'];
    final url = note['url'];

    if (type == 'manual_note') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NoteViewScreen(
            title: note['title'] ?? 'Notes',
            content: note['content'] ?? '',
          ),
        ),
      );
    } else if (url != null && url.isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open link.")));
        }
      }
    }
  }
}

class NoteViewScreen extends StatelessWidget {
  final String title;
  final String content;

  const NoteViewScreen({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(
          content,
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
      ),
    );
  }
}

