import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import '../models/social_media_links.dart';
import 'database_helper.dart';

class SocialMediaService {
  /// Save or update social media links
  static Future<bool> saveSocialMediaLinks(SocialMediaLinks links) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert(
        'social_media_links',
        {
          'username': links.username,
          'instagram': links.instagram,
          'linkedin': links.linkedin,
          'facebook': links.facebook,
          'instagram_public': links.instagramPublic ? 1 : 0,
          'linkedin_public': links.linkedinPublic ? 1 : 0,
          'facebook_public': links.facebookPublic ? 1 : 0,
          'updated_at': links.updatedAt.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return true;
    } catch (e) {
      debugPrint('Error saving social media links: $e');
      return false;
    }
  }

  /// Get public social media links for a user (only public ones)
  static Future<SocialMediaLinks?> getPublicSocialMediaLinks(String username) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query(
        'social_media_links',
        where: 'username = ?',
        whereArgs: [username],
        limit: 1,
      );

      if (result.isEmpty) {
        return null;
      }

      final row = result.first;
      return SocialMediaLinks(
        username: row['username'] as String,
        instagram: (row['instagram_public'] as int? ?? 1) == 1 ? row['instagram'] as String? : null,
        linkedin: (row['linkedin_public'] as int? ?? 1) == 1 ? row['linkedin'] as String? : null,
        facebook: (row['facebook_public'] as int? ?? 1) == 1 ? row['facebook'] as String? : null,
        instagramPublic: (row['instagram_public'] as int? ?? 1) == 1,
        linkedinPublic: (row['linkedin_public'] as int? ?? 1) == 1,
        facebookPublic: (row['facebook_public'] as int? ?? 1) == 1,
        updatedAt: DateTime.parse(row['updated_at'] as String),
      );
    } catch (e) {
      debugPrint('Error getting public social media links: $e');
      return null;
    }
  }

  /// Get social media links for a user
  static Future<SocialMediaLinks?> getSocialMediaLinks(String username) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query(
        'social_media_links',
        where: 'username = ?',
        whereArgs: [username],
        limit: 1,
      );

      if (result.isEmpty) {
        return null;
      }

      return SocialMediaLinks.fromJson(result.first);
    } catch (e) {
      debugPrint('Error getting social media links: $e');
      return null;
    }
  }

  /// Delete social media links
  static Future<void> deleteSocialMediaLinks(String username) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('social_media_links', where: 'username = ?', whereArgs: [username]);
    } catch (e) {
      debugPrint('Error deleting social media links: $e');
    }
  }
}

