import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class ImageGenerationService {
  // Hugging Face API - Free tier available
  // Get your API key from: https://huggingface.co/settings/tokens
  // Using a text-to-image model that should work
  static const String _huggingFaceApiUrl = 
      'https://api-inference.huggingface.co/models/stabilityai/sdxl-turbo';
  
  // Alternative: Replicate API (also free tier)
  // Get your API key from: https://replicate.com/account/api-tokens
  static const String _replicateApiUrl = 'https://api.replicate.com/v1/predictions';
  
  // Alternative: Stability AI (free tier)
  // Get your API key from: https://platform.stability.ai/account/keys

  /// Generate image using Hugging Face (Free & Open Source)
  /// 
  /// Get your API key from: https://huggingface.co/settings/tokens
  /// Free tier: 1000 requests/month
  static Future<String?> generateImageHuggingFace({
    required String prompt,
    String? apiKey,
  }) async {
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('Hugging Face API key not provided');
      return null;
    }

    try {
      // First attempt
      var response = await http.post(
        Uri.parse(_huggingFaceApiUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': prompt,
        }),
      );

      debugPrint('Hugging Face Response Status: ${response.statusCode}');

      // Handle 503 - Model is loading, retry after delay
      if (response.statusCode == 503) {
        debugPrint('Model is loading, waiting 30 seconds and retrying...');
        await Future.delayed(const Duration(seconds: 30));
        
        // Retry
        response = await http.post(
          Uri.parse(_huggingFaceApiUrl),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'inputs': prompt,
          }),
        );
        debugPrint('Retry Response Status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final imageData = response.bodyBytes;
        
        // Check if response is actually an image (not JSON error)
        if (imageData.isEmpty) {
          debugPrint('Empty response from Hugging Face');
          return null;
        }
        
        // Check if it's JSON error (starts with '{')
        try {
          final decoded = utf8.decode(imageData);
          if (decoded.trim().startsWith('{')) {
            final errorJson = jsonDecode(decoded);
            debugPrint('Hugging Face Error Response: $errorJson');
            return null;
          }
        } catch (_) {
          // Not JSON, continue - it's likely an image
        }
        
        // Save to temp file and return path
        final tempFile = File('${Directory.systemTemp.path}/generated_${DateTime.now().millisecondsSinceEpoch}.png');
        await tempFile.writeAsBytes(imageData);
        debugPrint('✅ Image saved successfully: ${tempFile.path} (${imageData.length} bytes)');
        return tempFile.path;
      } else {
        final errorBody = response.body.length > 500 
            ? response.body.substring(0, 500) 
            : response.body;
        debugPrint('❌ Hugging Face API Error: ${response.statusCode}');
        debugPrint('Error body: $errorBody');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Exception generating image with Hugging Face: $e');
      return null;
    }
  }

  /// Generate image using Replicate API (Free tier available)
  /// 
  /// Get your API key from: https://replicate.com/account/api-tokens
  /// Free tier: Limited requests
  static Future<String?> generateImageReplicate({
    required String prompt,
    String? apiKey,
  }) async {
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('Replicate API key not provided');
      return null;
    }

    try {
      // Create prediction
      final createResponse = await http.post(
        Uri.parse(_replicateApiUrl),
        headers: {
          'Authorization': 'Token $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'version': 'stability-ai/stable-diffusion:db21e45d3f7023abc2a46ee38a23973f6dce16bb082a930b0c49861f96d1e5bf', // Stable Diffusion model
          'input': {
            'prompt': prompt,
            'num_outputs': 1,
            'guidance_scale': 7.5,
            'num_inference_steps': 20,
          },
        }),
      );

      if (createResponse.statusCode == 201) {
        final prediction = jsonDecode(createResponse.body);
        final predictionId = prediction['id'];
        
        // Poll for result
        String? imageUrl;
        for (int i = 0; i < 30; i++) {
          await Future.delayed(const Duration(seconds: 2));
          
          final statusResponse = await http.get(
            Uri.parse('$_replicateApiUrl/$predictionId'),
            headers: {
              'Authorization': 'Token $apiKey',
            },
          );
          
          final status = jsonDecode(statusResponse.body);
          if (status['status'] == 'succeeded') {
            imageUrl = status['output'][0];
            break;
          } else if (status['status'] == 'failed') {
            debugPrint('Replicate prediction failed');
            return null;
          }
        }
        
        if (imageUrl != null) {
          // Download image and save to temp file
          final imageResponse = await http.get(Uri.parse(imageUrl));
          final tempFile = File('${Directory.systemTemp.path}/generated_${DateTime.now().millisecondsSinceEpoch}.png');
          await tempFile.writeAsBytes(imageResponse.bodyBytes);
          return tempFile.path;
        }
      }
      
      debugPrint('Replicate API Error: ${createResponse.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Error generating image with Replicate: $e');
      return null;
    }
  }

  /// Generate image using Stability AI (Free tier available)
  /// 
  /// Get your API key from: https://platform.stability.ai/account/keys
  static Future<String?> generateImageStabilityAI({
    required String prompt,
    String? apiKey,
  }) async {
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('Stability AI API key not provided');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.stability.ai/v1/generation/stable-diffusion-xl-1024-v1-0/text-to-image'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'text_prompts': [
            {'text': prompt}
          ],
          'cfg_scale': 7,
          'height': 1024,
          'width': 1024,
          'samples': 1,
          'steps': 30,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final base64Image = result['artifacts'][0]['base64'];
        final imageBytes = base64Decode(base64Image);
        
        final tempFile = File('${Directory.systemTemp.path}/generated_${DateTime.now().millisecondsSinceEpoch}.png');
        await tempFile.writeAsBytes(imageBytes);
        return tempFile.path;
      } else {
        debugPrint('Stability AI API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error generating image with Stability AI: $e');
      return null;
    }
  }
}

