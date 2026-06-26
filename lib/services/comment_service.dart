import 'package:flutter/material.dart';
import '../models/comment.dart';
import 'app_events.dart';
import 'database_helper.dart';
import 'notification_service.dart';
import 'post_service.dart';

class CommentService {
  /// Add a comment to a post
  static Future<Comment?> addComment(String postId, String username, String commentText) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final commentId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final comment = Comment(
        id: commentId,
        postId: postId,
        username: username,
        commentText: commentText,
        createdAt: DateTime.now(),
      );

      await db.insert(
        'comments',
        {
          'id': comment.id,
          'post_id': comment.postId,
          'username': comment.username,
          'comment_text': comment.commentText,
          'created_at': comment.createdAt.toIso8601String(),
        },
      );

      // Create notification for post owner
      try {
        final posts = await PostService.getAllPosts();
        final post = posts.firstWhere(
          (p) => p.id == comment.postId,
          orElse: () => throw Exception('Post not found'),
        );
        if (post.username != comment.username) {
          await NotificationService.createCommentNotification(
            postOwnerUsername: post.username,
            postId: comment.postId,
            commenterUsername: comment.username,
            commentText: comment.commentText,
          );
        }
      } catch (e) {
        debugPrint('Error creating comment notification: $e');
      }

      AppEvents.instance.notifyDataChanged();
      return comment;
    } catch (e) {
      debugPrint('Error adding comment: $e');
      return null;
    }
  }

  /// Get all comments for a post
  static Future<List<Comment>> getComments(String postId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query(
        'comments',
        where: 'post_id = ?',
        whereArgs: [postId],
        orderBy: 'created_at ASC',
      );

      return result.map((row) => Comment.fromJson(row)).toList();
    } catch (e) {
      debugPrint('Error getting comments: $e');
      return [];
    }
  }

  /// Delete a comment
  static Future<void> deleteComment(String commentId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('comments', where: 'id = ?', whereArgs: [commentId]);
      AppEvents.instance.notifyDataChanged();
    } catch (e) {
      debugPrint('Error deleting comment: $e');
    }
  }

  /// Recent comments received on posts owned by [ownerUsername]
  /// (excludes the owner commenting on their own posts). Most recent first.
  static Future<List<Map<String, dynamic>>> getRecentCommentsForOwner(
    String ownerUsername, {
    int limit = 20,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await db.rawQuery(
        '''
        SELECT c.username AS actor, c.comment_text AS comment_text,
               c.created_at AS created_at, p.caption AS caption, p.id AS post_id
        FROM comments c
        JOIN posts p ON c.post_id = p.id
        WHERE p.username = ? AND c.username != ?
        ORDER BY c.created_at DESC
        LIMIT ?
        ''',
        [ownerUsername, ownerUsername, limit],
      );
    } catch (e) {
      debugPrint('Error getting recent comments: $e');
      return [];
    }
  }

  /// Get comment count for a post
  static Future<int> getCommentCount(String postId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM comments WHERE post_id = ?',
        [postId],
      );
      return result.first['count'] as int? ?? 0;
    } catch (e) {
      debugPrint('Error getting comment count: $e');
      return 0;
    }
  }
}

