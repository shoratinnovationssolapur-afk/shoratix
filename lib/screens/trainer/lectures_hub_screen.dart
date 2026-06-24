import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';

class LecturesHubScreen extends StatelessWidget {
  const LecturesHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<UserAuthProvider>(context);
    final trainer = auth.trainerModel;
    final List<String> interests = [trainer?.branch ?? 'all', 'all'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Lectures Management", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showUploadDialog(context),
                  icon: const Icon(Icons.link, color: Colors.white),
                  label: const Text("POST LECTURE URL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _pickAndUploadVideo(context),
                  icon: const Icon(Icons.video_file, color: Colors.white),
                  label: const Text("UPLOAD VIDEO FILE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5252),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("POSTED LECTURES", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5)),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: DatabaseService().getLectures(interests),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFFF5252)));
                }
                final items = snapshot.data?.where((l) => l['type'] == 'recorded').toList() ?? [];
                if (items.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.video_library_rounded, size: 60, color: Colors.grey),
                        Text("No lectures posted.", style: TextStyle(color: Colors.grey)),
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
                          backgroundColor: Color(0xFFFF5252),
                          child: Icon(Icons.play_arrow, color: Colors.white, size: 20),
                        ),
                        title: Text(item['title'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Branch: ${item['branch'] ?? 'All'}"),
                        trailing: const Icon(Icons.chevron_right),
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

  void _pickAndUploadVideo(BuildContext context) async {
    final auth = Provider.of<UserAuthProvider>(context, listen: false);
    if (auth.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sign in with a real trainer account to upload videos."),
        ),
      );
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      withData: kIsWeb, // Required for web
    );

    if (result != null) {
      if (kIsWeb) {
        if (result.files.single.bytes != null) {
          _showVideoUploadDialog(context, result.files.single.bytes, result.files.single.name);
        }
      } else {
        if (result.files.single.path != null) {
          _showVideoUploadDialog(context, File(result.files.single.path!), result.files.single.name);
        }
      }
    }
  }

  void _showVideoUploadDialog(BuildContext context, dynamic fileData, String fileName) {
    final titleController = TextEditingController(text: fileName);
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
              title: const Text("Upload Video Lecture"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isUploading) ...[
                    TextField(controller: titleController, decoration: const InputDecoration(labelText: "Lecture Title")),
                    TextField(controller: branchController, decoration: const InputDecoration(labelText: "Branch")),
                  ] else ...[
                    const CircularProgressIndicator(color: Color(0xFFFF5252)),
                    const SizedBox(height: 10),
                    const Text("Uploading video... This may take a while."),
                  ]
                ],
              ),
              actions: isUploading ? [] : [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a title")));
                      return;
                    }
                    
                    setDialogState(() => isUploading = true);
                    try {
                      final downloadUrl = await DatabaseService().uploadFile(
                        fileData, 
                        'lectures',
                        fileName: "${DateTime.now().millisecondsSinceEpoch}_$fileName"
                      );

                      final lectureData = {
                        'title': titleController.text.trim(),
                        'type': 'recorded',
                        'url': downloadUrl,
                        'branch': branchController.text.trim(),
                        'date': DateTime.now().toIso8601String(),
                        'trainerId': auth.trainerModel?.uid ?? '',
                      };
                      await DatabaseService().postLecture(lectureData);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Video uploaded successfully!")));
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
        );
      }
    );
  }

  void _showUploadDialog(BuildContext context) {
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
            title: const Text("Upload Lecture"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isUploading) ...[
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: "Lecture Title")),
                  TextField(controller: linkController, decoration: const InputDecoration(labelText: "Video URL (YouTube/Drive)")),
                  TextField(controller: branchController, decoration: const InputDecoration(labelText: "Branch")),
                ] else ...[
                  const CircularProgressIndicator(color: Color(0xFFFF5252)),
                  const SizedBox(height: 10),
                  const Text("Posting lecture..."),
                ]
              ],
            ),
            actions: isUploading ? [] : [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a title")));
                    return;
                  }
                  if (linkController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter the URL")));
                    return;
                  }

                  setDialogState(() => isUploading = true);
                  try {
                    final lectureData = {
                      'title': titleController.text.trim(),
                      'url': linkController.text.trim(),
                      'branch': branchController.text.trim(),
                      'type': 'recorded',
                      'date': DateTime.now().toIso8601String(),
                      'trainerId': trainer?.uid ?? '',
                    };

                    await DatabaseService().postLecture(lectureData);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Lecture uploaded successfully!")),
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
}
