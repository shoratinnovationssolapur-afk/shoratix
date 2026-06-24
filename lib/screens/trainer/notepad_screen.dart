import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';

class NotepadScreen extends StatefulWidget {
  const NotepadScreen({super.key});

  @override
  State<NotepadScreen> createState() => _NotepadScreenState();
}

class _NotepadScreenState extends State<NotepadScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _branchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<UserAuthProvider>(context, listen: false);
    if (auth.trainerModel != null) {
      _branchController.text = auth.trainerModel!.branch;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Notepad", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (_isSaving)
            const Center(child: Padding(padding: EdgeInsets.only(right: 20), child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF5252))))
          else
            TextButton(
              onPressed: _saveNote,
              child: const Text("SAVE", style: TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.bold)),
            ),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Title",
                hintText: "Enter note title",
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _branchController,
              decoration: const InputDecoration(
                labelText: "Branch",
                hintText: "e.g. Java, Flutter",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  labelText: "Notes Content",
                  hintText: "Start writing your notes here...",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSaving = false;

  void _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final branch = _branchController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in both title and content")),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final auth = Provider.of<UserAuthProvider>(context, listen: false);
      final lectureData = {
        'title': title,
        'content': content,
        'type': 'manual_note',
        'branch': branch.isEmpty ? 'all' : branch,
        'date': DateTime.now().toIso8601String(),
        'trainerId': auth.trainerModel?.uid ?? '',
      };

      await DatabaseService().postLecture(lectureData);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Note saved and shared with students!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

