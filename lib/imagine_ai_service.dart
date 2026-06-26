import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'models/image_result.dart';

/// Imagine AI Image Generation Service
/// Get your API key from: https://www.imagineapi.ai/
/// Free tier available
class ImagineAIService {
  static const String _baseUrl =
      'https://api.imagineapi.ai/v1/images/generations';

  /// Generate image using Imagine AI
  ///
  /// [prompt] - The text description for image generation
  /// [apiKey] - Your Imagine AI API key
  /// [style] - Optional style preset (e.g., 'photographic', 'digital-art', '3d-render')
  ///
  /// Returns the path to the generated image file, or null if generation failed
  static Future<ImageResult> generateImage({
    required String prompt,
    required String apiKey,
    String? style,
  }) async {
    if (apiKey.isEmpty) {
      final msg = 'Imagine AI API key not provided';
      debugPrint('❌ $msg');
      return ImageResult(error: msg);
    }

    try {
      debugPrint('🎨 Generating image with Imagine AI...');
      debugPrint('📝 Prompt: $prompt');

      String enhancedPrompt = _enhancePrompt(prompt, style);
      debugPrint('✨ Enhanced prompt: $enhancedPrompt');

      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'prompt': enhancedPrompt,
              'model': 'imagine-v1',
              'width': 1024,
              'height': 1024,
              'num_images': 1,
              if (style != null) 'style': style,
            }),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📡 Imagine AI Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        String? imageUrl;
        String? base64Image;

        if (jsonResponse['data'] != null && jsonResponse['data'].isNotEmpty) {
          final imageData = jsonResponse['data'][0];
          imageUrl = imageData['url'];
          base64Image = imageData['b64_json'];
        }

        if (imageUrl != null) {
          debugPrint('📥 Downloading image from URL...');
          final imageResponse = await http
              .get(Uri.parse(imageUrl))
              .timeout(const Duration(seconds: 30));

          if (imageResponse.statusCode == 200) {
            final imageBytes = imageResponse.bodyBytes;
            final tempFile = File(
              '${Directory.systemTemp.path}/generated_${DateTime.now().millisecondsSinceEpoch}.png',
            );
            await tempFile.writeAsBytes(imageBytes);
            debugPrint(
              '✅ Image saved: ${tempFile.path} (${imageBytes.length} bytes)',
            );
            return ImageResult(path: tempFile.path);
          }
          return ImageResult(
            error:
                'Failed to download image from Imagine AI URL (${imageResponse.statusCode})',
          );
        } else if (base64Image != null) {
          debugPrint('📥 Decoding base64 image...');
          final imageBytes = base64Decode(base64Image);
          final tempFile = File(
            '${Directory.systemTemp.path}/generated_${DateTime.now().millisecondsSinceEpoch}.png',
          );
          await tempFile.writeAsBytes(imageBytes);
          debugPrint(
            '✅ Image saved: ${tempFile.path} (${imageBytes.length} bytes)',
          );
          return ImageResult(path: tempFile.path);
        } else {
          return ImageResult(error: 'No image data in Imagine AI response');
        }
      } else {
        final errorBody = response.body.length > 500
            ? response.body.substring(0, 500)
            : response.body;
        debugPrint('❌ Imagine AI API Error: ${response.statusCode}');
        debugPrint('Error body: $errorBody');
        return ImageResult(
          error: 'Imagine AI API error: ${response.statusCode}',
        );
      }
    } on TimeoutException catch (e) {
      debugPrint('❌ Imagine AI request timed out: $e');
      return ImageResult(error: 'Imagine AI request timed out');
    } catch (e) {
      debugPrint('❌ Exception generating image with Imagine AI: $e');
      return ImageResult(error: 'Exception: $e');
    }
  }

  /// Enhance prompt for better image generation results
  static String _enhancePrompt(String originalPrompt, String? style) {
    String prompt = originalPrompt.trim();

    // Remove common prefixes that might confuse the model
    prompt = prompt.replaceAll(
      RegExp(r'^(generate|create|make|draw|show)\s+', caseSensitive: false),
      '',
    );
    prompt = prompt.replaceAll(
      RegExp(r'\s+(image|picture|photo|illustration)$', caseSensitive: false),
      '',
    );

    // Add style-specific enhancements
    List<String> enhancements = [];

    // Detect content type and add appropriate enhancements
    String lowerPrompt = prompt.toLowerCase();

    // Logo/Design/Branding requests - HIGH PRIORITY
    if (lowerPrompt.contains('logo') ||
        lowerPrompt.contains('tagline') ||
        lowerPrompt.contains('brand') ||
        lowerPrompt.contains('clothing line') ||
        lowerPrompt.contains('design') ||
        lowerPrompt.contains('graphic design')) {
      enhancements.addAll([
        'graphic design',
        'logo design',
        'brand identity',
        'vibrant colors',
        'bold typography',
        'modern design',
        'professional branding',
        'high contrast',
        'eye-catching',
        'commercial design',
      ]);

      // If logo is mentioned, emphasize it
      if (lowerPrompt.contains('logo')) {
        prompt = prompt.replaceAll(
          RegExp(r'logo', caseSensitive: false),
          'prominent logo design',
        );
      }

      // If tagline is mentioned, ensure it's visible
      if (lowerPrompt.contains('tagline')) {
        prompt = prompt.replaceAll(
          RegExp(r'tagline', caseSensitive: false),
          'visible tagline text',
        );
      }

      // If vibrant colors mentioned, emphasize them
      if (lowerPrompt.contains('vibrant') || lowerPrompt.contains('color')) {
        enhancements.add('saturated colors');
        enhancements.add('colorful palette');
      }
    }

    // Instagram post requests
    if (lowerPrompt.contains('instagram') ||
        lowerPrompt.contains('instagram post')) {
      enhancements.addAll([
        'square format',
        'social media design',
        'instagram ready',
        'high quality',
        'professional',
      ]);
    }

    // Blog/article content
    if (lowerPrompt.contains('blog') ||
        lowerPrompt.contains('article') ||
        lowerPrompt.contains('news') ||
        lowerPrompt.contains('newspaper')) {
      enhancements.addAll([
        'editorial style',
        'professional journalism',
        'newspaper article illustration',
        'high quality',
        'realistic',
        'documentary style',
      ]);
    }

    // News/serious topics
    if (lowerPrompt.contains('trafficking') ||
        lowerPrompt.contains('news') ||
        lowerPrompt.contains('serious') ||
        lowerPrompt.contains('social issue')) {
      enhancements.addAll([
        'serious tone',
        'professional photography',
        'journalistic style',
        'realistic',
        'high quality',
        'editorial',
      ]);
    }

    // Product/commercial content
    if (lowerPrompt.contains('clothing') ||
        lowerPrompt.contains('fashion') ||
        lowerPrompt.contains('product') ||
        lowerPrompt.contains('sale')) {
      // Only add these if it's NOT a logo/design request
      if (!lowerPrompt.contains('logo') && !lowerPrompt.contains('design')) {
        enhancements.addAll([
          'professional product photography',
          'studio lighting',
          'e-commerce style',
          'clean background',
          'high quality',
          'commercial photography',
        ]);
      }
    }

    // Always add quality keywords
    if (!enhancements.contains('high quality')) {
      enhancements.addAll([
        'high quality',
        'detailed',
        'professional',
        'sharp focus',
      ]);
    }

    // Combine with original prompt - put enhancements at the end
    String enhanced = '$prompt, ${enhancements.join(', ')}';

    return enhanced.trim();
  }
}
