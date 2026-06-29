import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../services/cloudinary_service.dart'; // Import your new service

class NotepadScreen extends StatefulWidget {
  const NotepadScreen({super.key});

  @override
  State<NotepadScreen> createState() => _NotepadScreenState();
}

class _NotepadScreenState extends State<NotepadScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _branchController = TextEditingController();

  File? _attachedFile;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<UserAuthProvider>(context, listen: false);
    if (auth.trainerModel != null) {
      _branchController.text = auth.trainerModel!.branch;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  // Pick an attachment
  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf', 'doc', 'mp4'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _attachedFile = File(result.files.single.path!);
      });
    }
  }

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
      String? attachmentUrl;

      // 1. If a file is attached, process upload through Cloudinary first
      if (_attachedFile != null) {
        bool isVideo = _attachedFile!.path.endsWith('.mp4');
        attachmentUrl = await CloudinaryService.uploadMedia(_attachedFile!);
      }

      // 2. Build map payload matching your architecture parameters
      final lectureData = {
        'title': title,
        'content': content,
        'type': 'manual_note',
        'branch': branch.isEmpty ? 'all' : branch,
        'date': DateTime.now().toIso8601String(),
        'trainerId': auth.trainerModel?.uid ?? '',
        'attachmentUrl': attachmentUrl ?? '', // Stores the public secure Cloudinary link
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
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 20),
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF5252)),
              ),
            )
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

            // Attachment HUD Trigger Block
            InkWell(
              onTap: _pickAttachment,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.attach_file, color: _attachedFile != null ? Colors.green : Colors.grey),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _attachedFile != null
                            ? "Attached: ${_attachedFile!.path.split('/').last}"
                            : "Add Media Attachment (Optional)",
                        style: TextStyle(color: _attachedFile != null ? Colors.green : Colors.grey.shade700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_attachedFile != null)
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red, size: 20),
                        onPressed: () => setState(() => _attachedFile = null),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      )
                  ],
                ),
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
}