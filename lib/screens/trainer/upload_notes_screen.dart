import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../services/cloudinary_service.dart'; // Import your newly minted service
import 'notepad_screen.dart';

class UploadNotesScreen extends StatelessWidget {
  const UploadNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Upload Notes", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOptionCard(
              context,
              "Choose File",
              "Upload PDF, PPT, DOC, Videos, or Images",
              Icons.file_present_rounded,
              const Color(0xFFFF5252),
                  () => _pickAndUploadFile(context),
            ),
            const SizedBox(height: 20),
            _buildOptionCard(
              context,
              "Create Custom Notes",
              "Write notes using rich text editor",
              Icons.edit_note_rounded,
              Colors.black,
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotepadScreen())),
            ),
            const SizedBox(height: 20),
            _buildOptionCard(
              context,
              "Share Resource Link",
              "Share YouTube or Drive links",
              Icons.link_rounded,
              const Color(0xFFFF5252),
                  () => _showUploadDialog(context, "Link"),
            ),
          ],
        ),
      ),
    );
  }

  void _pickAndUploadFile(BuildContext context) async {
    final auth = Provider.of<UserAuthProvider>(context, listen: false);
    if (auth.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sign in with a real trainer account to upload files."),
        ),
      );
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'jpg', 'png', 'mp4', 'mkv'],
      withData: kIsWeb,
    );

    if (result != null && result.files.single.path != null) {
      // Direct pass to Cloudinary processing pipeline
      _showUploadProgressDialog(context, File(result.files.single.path!), result.files.single.name);
    }
  }

  void _showUploadProgressDialog(BuildContext context, File localFile, String fileName) {
    final titleController = TextEditingController(text: fileName.split('.').first);
    final branchController = TextEditingController();
    final auth = Provider.of<UserAuthProvider>(context, listen: false);
    if (auth.trainerModel != null) branchController.text = auth.trainerModel!.branch;

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          bool isUploading = false;
          return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  title: const Text("Upload to Cloudinary"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isUploading) ...[
                        TextField(controller: titleController, decoration: const InputDecoration(labelText: "Resource Title")),
                        TextField(controller: branchController, decoration: const InputDecoration(labelText: "Branch or Course Name")),
                      ] else ...[
                        const CircularProgressIndicator(color: Color(0xFFFF5252)),
                        const SizedBox(height: 15),
                        const Text("Streaming media directly to secure servers..."),
                      ]
                    ],
                  ),
                  actions: isUploading ? [] : [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                    ElevatedButton(
                      onPressed: () async {
                        if (titleController.text.trim().isEmpty) return;

                        setDialogState(() => isUploading = true);
                        try {
                          // 1. Detect extension structure to split image/video/raw resource rules
                          bool isVideo = fileName.endsWith('.mp4') || fileName.endsWith('.mkv');

                          // 2. Dispatch the actual payload to your working Cloudinary client configuration
                          final String? secureDownloadUrl = await CloudinaryService.uploadMedia(localFile);

                          if (secureDownloadUrl == null) {
                            throw Exception("Cloudinary server upload rejected file properties.");
                          }

                          // 3. Save the resulting public asset URL string inside your matching Firestore lectures track record
                          final lectureData = {
                            'title': titleController.text.trim(),
                            'type': isVideo ? 'recorded' : 'file',
                            'url': secureDownloadUrl,
                            'branch': branchController.text.trim().isEmpty ? 'all' : branchController.text.trim(),
                            'date': DateTime.now().toIso8601String(),
                            'trainerId': auth.trainerModel?.uid ?? '',
                          };

                          await DatabaseService().postLecture(lectureData);

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Resource uploaded successfully to Cloudinary! 🎉")),
                            );
                          }
                        } catch (e) {
                          setDialogState(() => isUploading = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Upload Failed: ${e.toString()}"), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                      child: const Text("Upload"),
                    ),
                  ],
                );
              }
          );
        }
    );
  }

  void _showUploadDialog(BuildContext context, String type) {
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
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            bool isUploading = false;
            return AlertDialog(
              title: Text("Add $type"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isUploading) ...[
                    TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
                    TextField(
                      controller: linkController,
                      decoration: InputDecoration(labelText: type == "Link" ? "URL" : "File URL"),
                    ),
                    TextField(controller: branchController, decoration: const InputDecoration(labelText: "Branch")),
                  ] else ...[
                    const CircularProgressIndicator(color: Color(0xFFFF5252)),
                    const SizedBox(height: 10),
                    const Text("Sharing resource..."),
                  ]
                ],
              ),
              actions: isUploading ? [] : [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty || linkController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill in required fields")));
                      return;
                    }

                    setDialogState(() => isUploading = true);
                    try {
                      final lectureData = {
                        'title': titleController.text.trim(),
                        'type': type.toLowerCase(),
                        'url': linkController.text.trim(),
                        'branch': branchController.text.trim().isEmpty ? 'all' : branchController.text.trim(),
                        'date': DateTime.now().toIso8601String(),
                        'trainerId': trainer?.uid ?? '',
                      };

                      await DatabaseService().postLecture(lectureData);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Resource linked successfully!")),
                        );
                      }
                    } catch (e) {
                      setDialogState(() => isUploading = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  child: const Text("Upload"),
                ),
              ],
            );
          }
      ),
    );
  }

  Widget _buildOptionCard(BuildContext context, String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[100]!),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}