import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

/// Simple image generation using a working free API
class SimpleImageService {
  /// Generate image using a free alternative service
  /// For now, we'll use a placeholder approach until Hugging Face router is fixed
  static Future<String?> generateImage({
    required String prompt,
    String? apiKey,
  }) async {
    // Try using a free image generation API that works
    // Using Pollinations AI (free, no API key needed)
    try {
      debugPrint('🎨 Generating image with Pollinations AI...');
      
      // Enhance prompt for better results - add quality keywords
      String enhancedPrompt = _enhancePrompt(prompt);
      
      // Pollinations is a free service, no API key needed
      final encodedPrompt = Uri.encodeComponent(enhancedPrompt);
      final url = 'https://image.pollinations.ai/prompt/$encodedPrompt?width=1024&height=1024&model=flux&enhance=true&nologo=true';
      
      debugPrint('📡 Enhanced prompt: $enhancedPrompt');
      debugPrint('📡 Requesting: $url');
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final imageData = response.bodyBytes;
        
        if (imageData.isEmpty) {
          debugPrint('❌ Empty response');
          return null;
        }
        
        // Save to temp file
        final tempFile = File('${Directory.systemTemp.path}/generated_${DateTime.now().millisecondsSinceEpoch}.png');
        await tempFile.writeAsBytes(imageData);
        debugPrint('✅ Image saved: ${tempFile.path} (${imageData.length} bytes)');
        return tempFile.path;
      } else {
        debugPrint('❌ Pollinations API Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error with Pollinations: $e');
      return null;
    }
  }

  /// Enhance prompt for better image generation results
  static String _enhancePrompt(String originalPrompt) {
    String prompt = originalPrompt.toLowerCase();
    
    // Add quality and style keywords based on content
    List<String> enhancements = [];
    
    // Check for clothing/fashion keywords
    if (prompt.contains('clothing') || 
        prompt.contains('brand') || 
        prompt.contains('fashion') ||
        prompt.contains('sale') ||
        prompt.contains('winter') ||
        prompt.contains('ethnic')) {
      enhancements.addAll([
        'professional product photography',
        'studio lighting',
        'high quality',
        'detailed',
        'commercial photography style',
        'clean background',
        'e-commerce style'
      ]);
    }
    
    // Check for sale/promotional content
    if (prompt.contains('sale') || prompt.contains('discount') || prompt.contains('%')) {
      enhancements.add('promotional style');
    }
    
    // Always add quality keywords
    enhancements.addAll([
      'sharp focus',
      'high resolution',
      'professional',
      'detailed'
    ]);
    
    // Combine original prompt with enhancements
    String enhanced = '$originalPrompt, ${enhancements.join(', ')}';
    
    return enhanced;
  }
}

