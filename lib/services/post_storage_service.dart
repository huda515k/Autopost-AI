import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/scheduled_post.dart';
import '../models/post.dart';
import 'app_events.dart';
import 'database_helper.dart';
import 'post_service.dart';
import 'user_storage_service.dart';

class PostStorageService {
  static Future<List<ScheduledPost>> getScheduledPosts() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query(
        'scheduled_posts',
        orderBy: 'scheduled_date DESC',
      );

      return result.map((row) => ScheduledPost(
        id: row['id'] as String,
        imageFile: row['image_path'] != null 
            ? _getFileFromPath(row['image_path'] as String)
            : null,
        caption: row['caption'] as String,
        tags: _parseTags(row['tags'] as String),
        scheduledDate: DateTime.parse(row['scheduled_date'] as String),
        isPublished: (row['is_published'] as int) == 1,
        publishedDate: row['published_date'] != null
            ? DateTime.parse(row['published_date'] as String)
            : null,
        contentType: row['content_type'] as String,
      )).toList();
    } catch (e) {
      debugPrint('Error getting scheduled posts: $e');
      return [];
    }
  }

  static Future<void> saveScheduledPost(ScheduledPost post) async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      await db.insert(
        'scheduled_posts',
        {
          'id': post.id,
          'image_path': post.imageFile?.path,
          'caption': post.caption,
          'tags': _encodeTags(post.tags),
          'scheduled_date': post.scheduledDate.toIso8601String(),
          'is_published': post.isPublished ? 1 : 0,
          'published_date': post.publishedDate?.toIso8601String(),
          'content_type': post.contentType,
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error saving scheduled post: $e');
    }
  }

  static Future<void> deleteScheduledPost(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete(
        'scheduled_posts',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Error deleting scheduled post: $e');
    }
  }

  static Future<void> markAsPublished(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now();
      
      // Update scheduled post
      await db.update(
        'scheduled_posts',
        {
          'is_published': 1,
          'published_date': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      // Get the scheduled post to create a published post
      final scheduledPostData = await db.query(
        'scheduled_posts',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (scheduledPostData.isNotEmpty) {
        final row = scheduledPostData.first;
        
        // Get current user
        final currentUser = await UserStorageService.getCurrentUser();
        if (currentUser != null) {
          // Check if post already exists in posts table
          final existing = await db.query(
            'posts',
            where: 'id = ?',
            whereArgs: [id],
            limit: 1,
          );

          if (existing.isEmpty) {
            // Create and save published post
            final publishedPost = Post(
              id: id,
              username: currentUser.username,
              imageFile: row['image_path'] != null && File(row['image_path'] as String).existsSync()
                  ? File(row['image_path'] as String)
                  : null,
              caption: row['caption'] as String,
              tags: (row['tags'] as String).split(',').where((t) => t.isNotEmpty).toList(),
              contentType: row['content_type'] as String,
              publishedDate: now,
              createdAt: row['created_at'] != null
                  ? DateTime.parse(row['created_at'] as String)
                  : now,
            );

            await PostService.savePost(publishedPost);
            debugPrint('✅ Published post moved to posts table: $id');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error marking post as published: $e');
    }
  }

  /// Publishes any scheduled posts whose time has arrived to the AutoPost AI
  /// feed. Call on app start (and periodically) so due posts go live.
  static Future<void> publishDueScheduledPosts() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final nowIso = DateTime.now().toIso8601String();
      final due = await db.query(
        'scheduled_posts',
        where: 'is_published = 0 AND scheduled_date <= ?',
        whereArgs: [nowIso],
      );

      if (due.isEmpty) return;

      for (final row in due) {
        await markAsPublished(row['id'] as String);
      }
      debugPrint('✅ Published ${due.length} due scheduled post(s) to feed');
      AppEvents.instance.notifyDataChanged();
    } catch (e) {
      debugPrint('❌ Error publishing due scheduled posts: $e');
    }
  }

  /// Get posts by status
  static Future<List<ScheduledPost>> getPostsByStatus(bool isPublished) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query(
        'scheduled_posts',
        where: 'is_published = ?',
        whereArgs: [isPublished ? 1 : 0],
        orderBy: 'scheduled_date DESC',
      );

      return result.map((row) => ScheduledPost(
        id: row['id'] as String,
        imageFile: row['image_path'] != null 
            ? _getFileFromPath(row['image_path'] as String)
            : null,
        caption: row['caption'] as String,
        tags: _parseTags(row['tags'] as String),
        scheduledDate: DateTime.parse(row['scheduled_date'] as String),
        isPublished: (row['is_published'] as int) == 1,
        publishedDate: row['published_date'] != null
            ? DateTime.parse(row['published_date'] as String)
            : null,
        contentType: row['content_type'] as String,
      )).toList();
    } catch (e) {
      debugPrint('Error getting posts by status: $e');
      return [];
    }
  }

  /// Get posts scheduled for a specific date range
  static Future<List<ScheduledPost>> getPostsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query(
        'scheduled_posts',
        where: 'scheduled_date >= ? AND scheduled_date <= ?',
        whereArgs: [
          startDate.toIso8601String(),
          endDate.toIso8601String(),
        ],
        orderBy: 'scheduled_date ASC',
      );

      return result.map((row) => ScheduledPost(
        id: row['id'] as String,
        imageFile: row['image_path'] != null 
            ? _getFileFromPath(row['image_path'] as String)
            : null,
        caption: row['caption'] as String,
        tags: _parseTags(row['tags'] as String),
        scheduledDate: DateTime.parse(row['scheduled_date'] as String),
        isPublished: (row['is_published'] as int) == 1,
        publishedDate: row['published_date'] != null
            ? DateTime.parse(row['published_date'] as String)
            : null,
        contentType: row['content_type'] as String,
      )).toList();
    } catch (e) {
      debugPrint('Error getting posts by date range: $e');
      return [];
    }
  }

  // Helper methods
  static String _encodeTags(List<String> tags) {
    return jsonEncode(tags);
  }

  static List<String> _parseTags(String tagsJson) {
    try {
      final decoded = jsonDecode(tagsJson);
      if (decoded is List) {
        return List<String>.from(decoded);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static File? _getFileFromPath(String path) {
    try {
      final file = File(path);
      return file.existsSync() ? file : null;
    } catch (e) {
      return null;
    }
  }
}
