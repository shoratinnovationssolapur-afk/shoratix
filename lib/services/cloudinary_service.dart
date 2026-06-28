import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // Updated configuration fields
  static const String _cloudName = "dx8vqwqxq";
  static const String _uploadPreset = "shoratix_unstructured_data";

  /// Dynamically detects extensions to upload images, videos, or documents
  /// to your single 'document_upload' preset configuration.
  static Future<String?> uploadMedia(File file) async {
    final String path = file.path.toLowerCase();
    String resourceType = "image"; // Default fallback for jpg, png, etc.

    // 1. Dynamic endpoint path routing logic
    if (path.endsWith('.mp4') || path.endsWith('.mkv') || path.endsWith('.mov')) {
      resourceType = "video";
    } else if (path.endsWith('.pdf') || path.endsWith('.doc') || path.endsWith('.docx') || path.endsWith('.ppt') || path.endsWith('.pptx')) {
      resourceType = "raw"; // Documents must stream through the raw folder path
    }

    final url = Uri.parse("https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/upload");

    final request = http.MultipartRequest("POST", url)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonMap = jsonDecode(responseData);
        return jsonMap['secure_url'] as String; // Returns clean secure HTTPS URL
      } else {
        print("Cloudinary API Reject Status Code: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Failed parsing out upload stream: $e");
      return null;
    }
  }
}