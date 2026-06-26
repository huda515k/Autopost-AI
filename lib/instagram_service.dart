import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum SocialPlatform { instagram, facebook, twitter, linkedin }

extension SocialPlatformInfo on SocialPlatform {
  String get packageName {
    switch (this) {
      case SocialPlatform.instagram:
        return 'com.instagram.android';
      case SocialPlatform.facebook:
        return 'com.facebook.katana';
      case SocialPlatform.twitter:
        return 'com.twitter.android';
      case SocialPlatform.linkedin:
        return 'com.linkedin.android';
    }
  }

  String get displayName {
    switch (this) {
      case SocialPlatform.instagram:
        return 'Instagram';
      case SocialPlatform.facebook:
        return 'Facebook';
      case SocialPlatform.twitter:
        return 'X / Twitter';
      case SocialPlatform.linkedin:
        return 'LinkedIn';
    }
  }
}

class InstagramNotInstalledException implements Exception {
  final String message;

  InstagramNotInstalledException([
    this.message = 'Instagram is not installed.',
  ]);

  @override
  String toString() => message;
}

class InstagramShareException implements Exception {
  final String message;

  InstagramShareException(this.message);

  @override
  String toString() => message;
}

class InstagramService {
  static const MethodChannel _channel = MethodChannel('instagram_service');

  /// Returns true when the native Instagram app is installed on Android.
  static Future<bool> isInstagramInstalled() async {
    return isAppInstalled(SocialPlatform.instagram);
  }

  /// Checks whether the target app is installed.
  ///
  /// Only Android exposes a reliable install check (via the native channel).
  /// On every other platform the OS share sheet handles app selection, so we
  /// report `false` and let the share sheet take over.
  static Future<bool> isAppInstalled(SocialPlatform platform) async {
    if (kIsWeb || !Platform.isAndroid) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>('isAppInstalled', {
        'packageName': platform.packageName,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('${platform.displayName} install check failed: $e');
      return false;
    }
  }

  /// Shares an image to Instagram by opening the native Instagram share intent.
  /// The caption is copied to the clipboard first so the user can paste it into Instagram.
  static Future<void> shareImageToInstagram({
    required File imageFile,
    required String caption,
  }) async {
    await shareImageToPlatform(
      platform: SocialPlatform.instagram,
      imageFile: imageFile,
      caption: caption,
    );
  }

  /// Shares an image + caption to a social app on ANY platform.
  ///
  /// - On Android, when the target app is installed, it opens that app directly
  ///   via the native share intent (with a share-sheet fallback).
  /// - On iOS, macOS, Windows and Linux, it opens the OS share sheet
  ///   (via share_plus) so the user can pick the destination app.
  ///
  /// In every case the caption is copied to the clipboard first so it can be
  /// pasted into the post.
  static Future<void> shareImageToPlatform({
    required SocialPlatform platform,
    required File imageFile,
    required String caption,
  }) async {
    if (!await imageFile.exists()) {
      throw InstagramShareException('Image file not found.');
    }

    final preparedFile = await _prepareFileForSharing(imageFile);

    // Copy caption before sharing so the user can paste it immediately.
    await Clipboard.setData(ClipboardData(text: caption));

    // Android fast path: open the target app directly when it's installed.
    final canUseDirectIntent =
        !kIsWeb && Platform.isAndroid && await isAppInstalled(platform);

    if (canUseDirectIntent) {
      try {
        await _channel.invokeMethod<void>('shareToInstagram', {
          'packageName': platform.packageName,
          'imagePath': preparedFile.path,
          'caption': caption,
        });
        return;
      } on PlatformException catch (e) {
        // Fall through to the cross-platform share sheet.
        debugPrint('Direct ${platform.displayName} intent failed: $e');
      }
    }

    // Cross-platform path: the OS share sheet works on iOS, macOS, Windows,
    // Linux and Android. The user picks ${platform.displayName} from the sheet.
    await Share.shareXFiles(
      [XFile(preparedFile.path)],
      text: caption,
      subject: '${platform.displayName} Post',
    );
  }

  /// Copies the image into the app cache so Android FileProvider can safely expose it.
  static Future<File> _prepareFileForSharing(File originalFile) async {
    final cacheDir = await getTemporaryDirectory();
    final shareDir = Directory(p.join(cacheDir.path, 'instagram_shares'));

    if (!await shareDir.exists()) {
      await shareDir.create(recursive: true);
    }

    final extension = p.extension(originalFile.path).isNotEmpty
        ? p.extension(originalFile.path)
        : '.jpg';
    final targetFile = File(
      p.join(
        shareDir.path,
        'instagram_${DateTime.now().millisecondsSinceEpoch}$extension',
      ),
    );

    return originalFile.copy(targetFile.path);
  }
}
