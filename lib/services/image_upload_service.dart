import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'backend_config.dart';

class ImageUploadService {
  static Future<String> uploadProductImage(File imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/upload-image'),
    );

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception('Image upload failed: $body');
    }

    final data = jsonDecode(body);
    final imageUrl = data['imageUrl']?.toString() ?? '';
    if (imageUrl.isEmpty) {
      throw Exception('Image upload failed: imageUrl missing');
    }
    return imageUrl;
  }
}

Future<String> uploadProductImage(File imageFile) {
  return ImageUploadService.uploadProductImage(imageFile);
}
