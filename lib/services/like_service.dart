import 'package:flutter/material.dart';
import 'app_events.dart';
import 'database_helper.dart';
import 'notification_service.dart';
import 'post_service.dart';

class LikeService {
  /// Toggle like on a post
  static Future<bool> toggleLike(String postId, String username) async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Check if already liked
      final existing = await db.query(
        'likes',
        where: 'post_id = ? AND username = ?',
        whereArgs: [postId, username],
      );

      if (existing.isNotEmpty) {
        // Unlike
        await db.delete(
          'likes',
          where: 'post_id = ? AND username = ?',
          whereArgs: [postId, username],
        );
        AppEvents.instance.notifyDataChanged();
        return false;
      } else {
        // Like
        await db.insert(
          'likes',
          {
            'post_id': postId,
            'username': username,
            'created_at': DateTime.now().toIso8601String(),
          },
        );
        
        // Create notification for post owner
        try {
          final posts = await PostService.getAllPosts();
          final post = posts.firstWhere(
            (p) => p.id == postId,
            orElse: () => throw Exception('Post not found'),
          );
          if (post.username != username) {
            await NotificationService.createLikeNotification(
              postOwnerUsername: post.username,
              postId: postId,
              likerUsername: username,
            );
          }
        } catch (e) {
          debugPrint('Error creating like notification: $e');
        }

        AppEvents.instance.notifyDataChanged();
        return true;
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
      return false;
    }
  }

  /// Get like count for a post
  static Future<int> getLikeCount(String postId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM likes WHERE post_id = ?',
        [postId],
      );
      return result.first['count'] as int? ?? 0;
    } catch (e) {
      debugPrint('Error getting like count: $e');
      return 0;
    }
  }

  /// Recent likes received on posts owned by [ownerUsername]
  /// (excludes the owner liking their own posts). Most recent first.
  static Future<List<Map<String, dynamic>>> getRecentLikesForOwner(
    String ownerUsername, {
    int limit = 20,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await db.rawQuery(
        '''
        SELECT l.username AS actor, l.created_at AS created_at,
               p.caption AS caption, p.id AS post_id
        FROM likes l
        JOIN posts p ON l.post_id = p.id
        WHERE p.username = ? AND l.username != ?
        ORDER BY l.created_at DESC
        LIMIT ?
        ''',
        [ownerUsername, ownerUsername, limit],
      );
    } catch (e) {
      debugPrint('Error getting recent likes: $e');
      return [];
    }
  }

  /// Check if user liked a post
  static Future<bool> isLikedByUser(String postId, String username) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query(
        'likes',
        where: 'post_id = ? AND username = ?',
        whereArgs: [postId, username],
      );
      return result.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking like: $e');
      return false;
    }
  }
}

