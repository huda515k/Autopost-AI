import 'package:flutter/material.dart';
import 'dart:io';
import '../models/post.dart';
import 'database_helper.dart';
import 'post_service.dart';

class PostMigrationService {
  /// Migrate all published scheduled posts to the posts table
  static Future<void> migratePublishedPosts() async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Get all published scheduled posts
      final publishedScheduled = await db.query(
        'scheduled_posts',
        where: 'is_published = ?',
        whereArgs: [1],
      );

      debugPrint('🔄 Found ${publishedScheduled.length} published scheduled posts to migrate');

      for (final row in publishedScheduled) {
        final postId = row['id'] as String;
        
        // Check if post already exists in posts table
        final existing = await db.query(
          'posts',
          where: 'id = ?',
          whereArgs: [postId],
          limit: 1,
        );

        if (existing.isEmpty) {
          // Get username from current user or use a default
          // For existing posts, we need to get the username somehow
          // Since scheduled_posts doesn't have username, we'll need to handle this
          // For now, let's get the current user from the session
          final currentUser = await db.query('current_user', limit: 1);
          final username = currentUser.isNotEmpty 
              ? currentUser.first['username'] as String
              : 'unknown';

          // Create post from scheduled post
          final post = Post(
            id: postId,
            username: username,
            imageFile: row['image_path'] != null && File(row['image_path'] as String).existsSync()
                ? File(row['image_path'] as String)
                : null,
            caption: row['caption'] as String,
            tags: (row['tags'] as String).split(',').where((t) => t.isNotEmpty).toList(),
            contentType: row['content_type'] as String,
            publishedDate: row['published_date'] != null
                ? DateTime.parse(row['published_date'] as String)
                : DateTime.parse(row['scheduled_date'] as String),
            createdAt: row['created_at'] != null
                ? DateTime.parse(row['created_at'] as String)
                : DateTime.now(),
          );

          await PostService.savePost(post);
          debugPrint('✅ Migrated post: $postId');
        }
      }

      debugPrint('✅ Migration complete');
    } catch (e) {
      debugPrint('❌ Error migrating posts: $e');
    }
  }
}

