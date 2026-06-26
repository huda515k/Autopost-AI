import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import 'database_helper.dart';

class NotificationService {
  /// Create a notification
  static Future<bool> createNotification({
    required String username,
    required String type,
    String? postId,
    String? fromUsername,
    String? message,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final notificationId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Don't create notification if user is liking/commenting on their own post
      if (fromUsername == username) {
        return false;
      }

      await db.insert(
        'notifications',
        {
          'id': notificationId,
          'username': username,
          'type': type,
          'post_id': postId,
          'from_username': fromUsername,
          'message': message,
          'is_read': 0,
          'created_at': DateTime.now().toIso8601String(),
          'metadata': metadata?.toString(),
        },
      );

      debugPrint('✅ Notification created: $type for $username');
      return true;
    } catch (e) {
      debugPrint('❌ Error creating notification: $e');
      return false;
    }
  }

  /// Get all notifications for a user
  static Future<List<NotificationModel>> getNotifications(String username) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query(
        'notifications',
        where: 'username = ?',
        whereArgs: [username],
        orderBy: 'created_at DESC',
        limit: 100,
      );

      return result.map((row) => NotificationModel.fromJson(row)).toList();
    } catch (e) {
      debugPrint('❌ Error getting notifications: $e');
      return [];
    }
  }

  /// Get unread notification count
  static Future<int> getUnreadCount(String username) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM notifications WHERE username = ? AND is_read = 0',
        [username],
      );
      return result.first['count'] as int? ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting unread count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  static Future<bool> markAsRead(String notificationId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'notifications',
        {'is_read': 1},
        where: 'id = ?',
        whereArgs: [notificationId],
      );
      return true;
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  static Future<bool> markAllAsRead(String username) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'notifications',
        {'is_read': 1},
        where: 'username = ?',
        whereArgs: [username],
      );
      return true;
    } catch (e) {
      debugPrint('❌ Error marking all as read: $e');
      return false;
    }
  }

  /// Delete a notification
  static Future<bool> deleteNotification(String notificationId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete(
        'notifications',
        where: 'id = ?',
        whereArgs: [notificationId],
      );
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting notification: $e');
      return false;
    }
  }

  /// Delete all notifications for a user
  static Future<bool> deleteAllNotifications(String username) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete(
        'notifications',
        where: 'username = ?',
        whereArgs: [username],
      );
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting all notifications: $e');
      return false;
    }
  }

  /// Create like notification
  static Future<bool> createLikeNotification({
    required String postOwnerUsername,
    required String postId,
    required String likerUsername,
  }) async {
    return await createNotification(
      username: postOwnerUsername,
      type: 'like',
      postId: postId,
      fromUsername: likerUsername,
      message: '$likerUsername liked your post',
    );
  }

  /// Create comment notification
  static Future<bool> createCommentNotification({
    required String postOwnerUsername,
    required String postId,
    required String commenterUsername,
    required String commentText,
  }) async {
    return await createNotification(
      username: postOwnerUsername,
      type: 'comment',
      postId: postId,
      fromUsername: commenterUsername,
      message: '$commenterUsername commented on your post',
      metadata: {'comment_text': commentText},
    );
  }

  /// Create scheduled post reminder
  static Future<bool> createScheduledReminder({
    required String username,
    required String postId,
    required DateTime scheduledDate,
  }) async {
    return await createNotification(
      username: username,
      type: 'scheduled_reminder',
      postId: postId,
      message: 'Your post is scheduled to publish soon',
      metadata: {'scheduled_date': scheduledDate.toIso8601String()},
    );
  }

  /// Create system notification
  static Future<bool> createSystemNotification({
    required String username,
    required String message,
  }) async {
    return await createNotification(
      username: username,
      type: 'system',
      message: message,
    );
  }
}

