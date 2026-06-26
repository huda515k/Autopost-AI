import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/backend_config.dart';
import '../instagram_service.dart' show SocialPlatform;

/// Result of an auto-post attempt.
class SocialPostResult {
  final bool success;
  final String message;

  /// Live URLs of the published posts, keyed by platform (when available).
  final Map<String, String> postUrls;

  SocialPostResult({
    required this.success,
    required this.message,
    this.postUrls = const {},
  });
}

/// Talks to the AutoPost AI backend to publish posts via the unified API.
///
/// When [BackendConfig.isConfigured] is false this does nothing — callers
/// should fall back to the share-sheet flow ([InstagramService]).
class SocialPostService {
  static bool get isConfigured => BackendConfig.isConfigured;

  /// Maps the app's [SocialPlatform] enum to the unified API's platform keys.
  static String platformKey(SocialPlatform platform) {
    switch (platform) {
      case SocialPlatform.instagram:
        return 'instagram';
      case SocialPlatform.facebook:
        return 'facebook';
      case SocialPlatform.twitter:
        return 'twitter';
      case SocialPlatform.linkedin:
        return 'linkedin';
    }
  }

  /// Publishes [caption] (+ optional [imageFile]) to the given [platforms].
  static Future<SocialPostResult> autoPost({
    required List<SocialPlatform> platforms,
    required String caption,
    File? imageFile,
    String? profileKey,
  }) async {
    if (!isConfigured) {
      return SocialPostResult(
        success: false,
        message: 'Auto-posting backend is not configured.',
      );
    }

    try {
      final body = <String, dynamic>{
        'caption': caption,
        'platforms': platforms.map(platformKey).toList(),
        if (profileKey != null) 'profileKey': profileKey,
      };

      if (imageFile != null && await imageFile.exists()) {
        final bytes = await imageFile.readAsBytes();
        body['imageBase64'] = base64Encode(bytes);
      }

      final resp = await http
          .post(
            Uri.parse('${BackendConfig.baseUrl}/api/post'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));

      final data = _decode(resp.body);

      if (resp.statusCode >= 200 && resp.statusCode < 300 && data['ok'] == true) {
        return SocialPostResult(
          success: true,
          message: 'Posted successfully.',
          postUrls: _extractPostUrls(data['result']),
        );
      }

      return SocialPostResult(
        success: false,
        message: (data['error'] ?? 'Posting failed (${resp.statusCode}).').toString(),
      );
    } catch (e) {
      debugPrint('Auto-post error: $e');
      return SocialPostResult(success: false, message: 'Network error: $e');
    }
  }

  /// Returns a URL where the user links their social accounts.
  static Future<String?> connectUrl({String? profileKey}) async {
    if (!isConfigured) return null;
    try {
      final resp = await http
          .post(
            Uri.parse('${BackendConfig.baseUrl}/api/connect'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({if (profileKey != null) 'profileKey': profileKey}),
          )
          .timeout(const Duration(seconds: 30));
      final data = _decode(resp.body);
      return data['url'] as String?;
    } catch (e) {
      debugPrint('Connect URL error: $e');
      return null;
    }
  }

  static Map<String, dynamic> _decode(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  /// Pulls per-platform post URLs out of the unified API response, when present.
  static Map<String, String> _extractPostUrls(dynamic result) {
    final urls = <String, String>{};
    try {
      final posts = result?['postIds'];
      if (posts is List) {
        for (final p in posts) {
          if (p is Map && p['platform'] != null && p['postUrl'] != null) {
            urls[p['platform'].toString()] = p['postUrl'].toString();
          }
        }
      }
    } catch (_) {}
    return urls;
  }
}
