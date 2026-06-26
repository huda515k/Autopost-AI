import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'models/image_result.dart';
import 'simple_image_service.dart';

/// Free Image Generation Service with multiple high-quality models
/// All models are free and don't require API keys
class FreeImageService {
  /// Generate image using the best available free service
  /// Tries multiple models in order of quality
  static Future<ImageResult> generateImage({
    required String prompt,
    String? apiKey, // Optional, for Hugging Face if available
  }) async {
    String enhancedPrompt = _enhancePromptForAccuracy(prompt);
    debugPrint('✨ Enhanced prompt: $enhancedPrompt');

    List<String> errors = [];

    // 1. Try Pollinations first because it is lower-friction and usually avoids model queue spikes.
    debugPrint('🎨 Trying Pollinations Flux model...');
    final poll1 = await _tryPollinationsFlux(enhancedPrompt);
    if (poll1.success) return poll1;
    errors.add('PollinationsFlux: ${poll1.error ?? 'unknown'}');

    // 2. Try Hugging Face Flux only as a fallback when a key is available.
    if (apiKey != null && apiKey.isNotEmpty) {
      debugPrint('🎨 Trying Hugging Face Flux model...');
      final result = await _tryHuggingFaceFlux(enhancedPrompt, apiKey);
      if (result.success) return result;
      errors.add('HuggingFaceFlux: ${result.error ?? 'unknown'}');
    }

    // 3. Try Hugging Face SDXL (if API key available)
    if (apiKey != null && apiKey.isNotEmpty) {
      debugPrint('🎨 Trying Hugging Face SDXL...');
      final result2 = await _tryHuggingFaceSDXL(enhancedPrompt, apiKey);
      if (result2.success) return result2;
      errors.add('HuggingFaceSDXL: ${result2.error ?? 'unknown'}');
    }

    // 4. Try a plain Pollinations variant with a simpler prompt path.
    debugPrint('🎨 Trying Pollinations SDXL...');
    final poll2 = await _tryPollinationsSDXL(enhancedPrompt);
    if (poll2.success) return poll2;
    errors.add('PollinationsSDXL: ${poll2.error ?? 'unknown'}');

    // 5. Final fallback: the simple Pollinations wrapper already used elsewhere in the app.
    debugPrint('🎨 Trying SimpleImageService fallback...');
    final simplePath = await SimpleImageService.generateImage(
      prompt: enhancedPrompt,
      apiKey: apiKey,
    );
    if (simplePath != null) {
      return ImageResult(path: simplePath);
    }
    errors.add('SimpleImageService: failed');

    debugPrint(
      '❌ All free image generation services failed: ${errors.join(' | ')}',
    );
    return ImageResult(error: errors.join(' | '));
  }

  /// Try Hugging Face Flux model (best quality)
  static Future<ImageResult> _tryHuggingFaceFlux(
    String prompt,
    String apiKey,
  ) async {
    const maxRetries = 3;
    int attempt = 0;
    while (attempt < maxRetries) {
      attempt++;
      try {
        final response = await http
            .post(
              Uri.parse(
                'https://api-inference.huggingface.co/models/black-forest-labs/FLUX.1-dev',
              ),
              headers: {
                'Authorization': 'Bearer $apiKey',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'inputs': prompt,
                'parameters': {
                  'num_inference_steps': 28,
                  'guidance_scale': 3.5,
                },
              }),
            )
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final imageData = response.bodyBytes;
          if (imageData.isNotEmpty && !_isJsonError(imageData)) {
            final path = await _saveImage(imageData);
            return ImageResult(path: path);
          }
          return ImageResult(error: 'Empty image data from HuggingFace Flux');
        } else if (response.statusCode == 503) {
          if (attempt >= maxRetries) {
            return ImageResult(
              error:
                  'HuggingFace Flux model loading (503) after $attempt attempts',
            );
          }
          await Future.delayed(Duration(seconds: 5 * attempt));
          continue;
        } else {
          return ImageResult(
            error: 'HuggingFace Flux API error: ${response.statusCode}',
          );
        }
      } on TimeoutException catch (e) {
        debugPrint('❌ Hugging Face Flux timeout: $e');
        if (attempt >= maxRetries)
          return ImageResult(error: 'HuggingFace Flux request timed out');
        await Future.delayed(Duration(seconds: 2 * attempt));
      } catch (e) {
        debugPrint('❌ Hugging Face Flux error: $e');
        if (attempt >= maxRetries)
          return ImageResult(error: 'HuggingFace Flux error: $e');
        await Future.delayed(Duration(seconds: 2 * attempt));
      }
    }
    return ImageResult(
      error: 'HuggingFace Flux failed after $maxRetries attempts',
    );
  }

  /// Try Pollinations Flux (no API key needed)
  static Future<ImageResult> _tryPollinationsFlux(String prompt) async {
    try {
      // Encode and guard against extremely long URLs by truncating the prompt if necessary
      String truncated = prompt;
      final encoded = Uri.encodeComponent(truncated);
      if (encoded.length > 1500) {
        truncated = prompt.substring(0, 800);
      }
      final encodedPrompt = Uri.encodeComponent(truncated);
      final url =
          'https://image.pollinations.ai/prompt/$encodedPrompt?width=1024&height=1024&model=flux.1-schnell&enhance=true&nologo=true&seed=-1';

      final response = await http
          .get(Uri.parse(url), headers: {'User-Agent': 'Mozilla/5.0'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final path = await _saveImage(response.bodyBytes);
        return ImageResult(path: path);
      }
      return ImageResult(error: 'Pollinations returned ${response.statusCode}');
    } on TimeoutException catch (e) {
      debugPrint('❌ Pollinations timeout: $e');
      return ImageResult(error: 'Pollinations request timed out');
    } catch (e) {
      debugPrint('❌ Pollinations Flux error: $e');
      return ImageResult(error: 'Pollinations error: $e');
    }
  }

  /// Try Hugging Face SDXL
  static Future<ImageResult> _tryHuggingFaceSDXL(
    String prompt,
    String apiKey,
  ) async {
    const maxRetries = 3;
    int attempt = 0;
    while (attempt < maxRetries) {
      attempt++;
      try {
        final response = await http
            .post(
              Uri.parse(
                'https://api-inference.huggingface.co/models/stabilityai/stable-diffusion-xl-base-1.0',
              ),
              headers: {
                'Authorization': 'Bearer $apiKey',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'inputs': prompt,
                'parameters': {
                  'num_inference_steps': 30,
                  'guidance_scale': 7.5,
                },
              }),
            )
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final imageData = response.bodyBytes;
          if (imageData.isNotEmpty && !_isJsonError(imageData)) {
            final path = await _saveImage(imageData);
            return ImageResult(path: path);
          }
          return ImageResult(error: 'Empty image data from HuggingFace SDXL');
        } else if (response.statusCode == 503) {
          if (attempt >= maxRetries) {
            return ImageResult(
              error:
                  'HuggingFace SDXL model loading (503) after $attempt attempts',
            );
          }
          await Future.delayed(Duration(seconds: 5 * attempt));
          continue;
        } else {
          return ImageResult(
            error: 'HuggingFace SDXL API error: ${response.statusCode}',
          );
        }
      } on TimeoutException catch (e) {
        debugPrint('❌ Hugging Face SDXL timeout: $e');
        if (attempt >= maxRetries)
          return ImageResult(error: 'HuggingFace SDXL request timed out');
        await Future.delayed(Duration(seconds: 2 * attempt));
      } catch (e) {
        debugPrint('❌ Hugging Face SDXL error: $e');
        if (attempt >= maxRetries)
          return ImageResult(error: 'HuggingFace SDXL error: $e');
        await Future.delayed(Duration(seconds: 2 * attempt));
      }
    }
    return ImageResult(
      error: 'HuggingFace SDXL failed after $maxRetries attempts',
    );
  }

  /// Try Pollinations SDXL
  static Future<ImageResult> _tryPollinationsSDXL(String prompt) async {
    try {
      String truncated = prompt;
      final encoded = Uri.encodeComponent(truncated);
      if (encoded.length > 1500) {
        truncated = prompt.substring(0, 800);
      }
      final encodedPrompt = Uri.encodeComponent(truncated);
      final url =
          'https://image.pollinations.ai/prompt/$encodedPrompt?width=1024&height=1024&model=flux&enhance=true&nologo=true&seed=-1';

      final response = await http
          .get(Uri.parse(url), headers: {'User-Agent': 'Mozilla/5.0'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final path = await _saveImage(response.bodyBytes);
        return ImageResult(path: path);
      }
      return ImageResult(error: 'Pollinations returned ${response.statusCode}');
    } on TimeoutException catch (e) {
      debugPrint('❌ Pollinations SDXL timeout: $e');
      return ImageResult(error: 'Pollinations SDXL request timed out');
    } catch (e) {
      debugPrint('❌ Pollinations SDXL error: $e');
      return ImageResult(error: 'Pollinations SDXL error: $e');
    }
  }

  /// Enhanced prompt engineering for maximum accuracy
  static String _enhancePromptForAccuracy(String originalPrompt) {
    String prompt = originalPrompt.trim();

    // Remove common prefixes that confuse models
    prompt = prompt.replaceAll(
      RegExp(r'^(generate|create|make|draw|show)\s+', caseSensitive: false),
      '',
    );
    prompt = prompt.replaceAll(
      RegExp(r'\s+(image|picture|photo|illustration)$', caseSensitive: false),
      '',
    );

    List<String> qualityEnhancements = [];
    String lowerPrompt = prompt.toLowerCase();

    // Logo/Design detection - CRITICAL for accuracy
    if (lowerPrompt.contains('logo') ||
        lowerPrompt.contains('tagline') ||
        lowerPrompt.contains('brand') ||
        lowerPrompt.contains('clothing line') ||
        lowerPrompt.contains('design') ||
        lowerPrompt.contains('graphic')) {
      qualityEnhancements.addAll([
        'graphic design',
        'logo design',
        'vector art',
        'clean design',
        'professional branding',
        'high contrast',
        'bold typography',
        'modern design',
        'minimalist',
        'precise',
        'accurate',
        'detailed',
      ]);

      // Emphasize logo if mentioned
      if (lowerPrompt.contains('logo')) {
        prompt = prompt.replaceAll(
          RegExp(r'logo', caseSensitive: false),
          'prominent logo design',
        );
      }

      // Emphasize tagline if mentioned
      if (lowerPrompt.contains('tagline')) {
        prompt = prompt.replaceAll(
          RegExp(r'tagline', caseSensitive: false),
          'visible tagline text',
        );
      }
    }

    // Instagram post detection
    if (lowerPrompt.contains('instagram') ||
        lowerPrompt.contains('instagram post')) {
      qualityEnhancements.addAll([
        'square format',
        'social media design',
        'instagram ready',
        'high quality',
        'professional',
      ]);
    }

    // Color scheme detection
    if (lowerPrompt.contains('vibrant') ||
        lowerPrompt.contains('color') ||
        lowerPrompt.contains('colour')) {
      qualityEnhancements.addAll([
        'vibrant colors',
        'saturated colors',
        'colorful palette',
        'high saturation',
        'bold colors',
      ]);
    }

    // Clothing/Fashion detection
    if (lowerPrompt.contains('clothing') ||
        lowerPrompt.contains('fashion') ||
        lowerPrompt.contains('brand') ||
        lowerPrompt.contains('wear')) {
      if (!lowerPrompt.contains('logo') && !lowerPrompt.contains('design')) {
        qualityEnhancements.addAll([
          'professional product photography',
          'studio lighting',
          'e-commerce style',
          'clean background',
          'high quality',
          'detailed',
        ]);
      }
    }

    // Blog/Article detection
    if (lowerPrompt.contains('blog') ||
        lowerPrompt.contains('article') ||
        lowerPrompt.contains('news')) {
      qualityEnhancements.addAll([
        'editorial illustration',
        'professional journalism',
        'newspaper style',
        'realistic',
        'high quality',
        'documentary style',
      ]);
    }

    // Always add universal quality keywords
    qualityEnhancements.addAll([
      'high quality',
      'detailed',
      'professional',
      'sharp focus',
      'accurate',
      'precise',
      'well-composed',
      'masterpiece',
      'best quality',
    ]);

    // Combine prompt with enhancements
    String enhanced = '$prompt, ${qualityEnhancements.join(', ')}';

    // Remove duplicate words
    List<String> words = enhanced.split(' ');
    List<String> uniqueWords = [];
    Set<String> seen = {};
    for (String word in words) {
      String cleanWord = word.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
      if (cleanWord.isNotEmpty && !seen.contains(cleanWord)) {
        seen.add(cleanWord);
        uniqueWords.add(word);
      }
    }

    return uniqueWords.join(' ');
  }

  /// Save image to temp file
  static Future<String?> _saveImage(List<int> imageData) async {
    try {
      final tempFile = File(
        '${Directory.systemTemp.path}/generated_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await tempFile.writeAsBytes(imageData);
      debugPrint('✅ Image saved: ${tempFile.path} (${imageData.length} bytes)');
      return tempFile.path;
    } catch (e) {
      debugPrint('❌ Error saving image: $e');
      return null;
    }
  }

  /// Check if response is a JSON error
  static bool _isJsonError(List<int> data) {
    try {
      final decoded = utf8.decode(data);
      if (decoded.trim().startsWith('{') || decoded.trim().startsWith('[')) {
        return true;
      }
    } catch (_) {}
    return false;
  }
}
