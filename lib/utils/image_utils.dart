import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class ImageUtils {
  /// Download image from URL and save as File
  static Future<File?> downloadImageFromUrl(String imageUrl) async {
    try {
      debugPrint('📥 Downloading image from URL: $imageUrl');
      
      final response = await http.get(Uri.parse(imageUrl));
      
      if (response.statusCode == 200) {
        final imageBytes = response.bodyBytes;
        final tempFile = File('${Directory.systemTemp.path}/downloaded_${DateTime.now().millisecondsSinceEpoch}.png');
        await tempFile.writeAsBytes(imageBytes);
        debugPrint('✅ Image downloaded successfully: ${tempFile.path}');
        return tempFile;
      } else {
        debugPrint('❌ Failed to download image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error downloading image: $e');
      return null;
    }
  }
}



