import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/cloudinary_service.dart';

class UploadTestScreen extends StatefulWidget {
  const UploadTestScreen({super.key});

  @override
  State<UploadTestScreen> createState() => _UploadTestScreenState();
}

class _UploadTestScreenState extends State<UploadTestScreen> {
  File? _selectedFile;
  String? _uploadedUrl;
  bool _isUploading = false;

  // Pick a local file using file_picker
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf', 'doc'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _uploadedUrl = null; // Reset previous upload link
      });
    }
  }

  // Upload file to Cloudinary and update Firebase Firestore
  Future<void> _startUpload() async {
    if (_selectedFile == null) return;

    setState(() {
      _isUploading = true;
    });

    // 1. Upload to Cloudinary
    final url = await CloudinaryService.uploadMedia(_selectedFile!);

    if (url != null) {
      setState(() {
        _uploadedUrl = url;
      });

      // 2. Optional: Save to Firestore if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'uploadedDocument': url,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploaded successfully to Cloudinary! 🎉')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload failed. Check console logs.')),
      );
    }

    setState(() {
      _isUploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shoratix Media Upload')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_selectedFile != null) ...[
              Text(
                'Selected File:\n${_selectedFile!.path.split('/').last}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
            ],
            if (_isUploading)
              const Center(child: CircularProgressIndicator())
            else ...[
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.attach_file),
                label: const Text('Pick File / Document'),
              ),
              const SizedBox(height: 10),
              if (_selectedFile != null)
                ElevatedButton.icon(
                  onPressed: _startUpload,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Upload to Backend'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
            ],
            if (_uploadedUrl != null) ...[
              const SizedBox(height: 30),
              const Text(
                'Live Secure Cloudinary URL:',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
              SelectableText(
                _uploadedUrl!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ]
          ],
        ),
      ),
    );
  }
}