import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // Configured with your active Cloud Name and Preset
  static const String _cloudName = "dx8vqwqxq";
  static const String _uploadPreset = "video_upload";

  /// Uploads media (images, docs, or videos) to Cloudinary
  /// and returns the secure web URL string.
  static Future<String?> uploadMedia(File file, {bool isVideo = false}) async {
    // Cloudinary changes the endpoint folder based on resource type (image vs video)
    final String resourceType = isVideo ? "video" : "image";
    final url = Uri.parse("https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/upload");

    final request = http.MultipartRequest("POST", url)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonMap = jsonDecode(responseData);
        return jsonMap['secure_url'] as String; // Secure HTTPS link
      } else {
        print("Cloudinary Error Code: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Failed uploading to Cloudinary: $e");
      return null;
    }
  }
}