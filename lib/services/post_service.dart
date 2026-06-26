import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../models/post.dart';
import 'database_helper.dart';

class PostService {
  /// Save a published post
  static Future<bool> savePost(Post post) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.insert(
        'posts',
        {
          'id': post.id,
          'username': post.username,
          'image_path': post.imageFile?.path,
          'caption': post.caption,
          'tags': post.tags.join(','),
          'content_type': post.contentType,
          'published_date': post.publishedDate.toIso8601String(),
          'created_at': post.createdAt.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('✅ Post saved successfully with ID: ${post.id}, result: $result');
      return true;
    } catch (e) {
      debugPrint('❌ Error saving post: $e');
      debugPrint('Post details: id=${post.id}, username=${post.username}, caption=${post.caption}');
      return false;
    }
  }

  /// Get all posts from all users, ordered by published date
  static Future<List<Post>> getAllPosts({
    String? currentUsername,
    String? contentTypeFilter,
    String? searchQuery,
    String? usernameFilter,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      // First, check if posts table exists and get count
      final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM posts');
      final postCount = countResult.first['count'] as int? ?? 0;
      debugPrint('📊 Total posts in database: $postCount');
      
      // Build WHERE clause based on filters
      final List<String> whereConditions = [];
      final List<dynamic> whereArgs = [];

      if (contentTypeFilter != null && contentTypeFilter.isNotEmpty && contentTypeFilter != 'All') {
        if (contentTypeFilter == 'Social Media Posts') {
          // Include all social media related posts (but exclude Blog Articles)
          whereConditions.add('(p.content_type LIKE ? OR p.content_type LIKE ? OR p.content_type LIKE ? OR p.content_type LIKE ? OR p.content_type LIKE ?) AND p.content_type NOT LIKE ?');
          whereArgs.addAll(['%Social Media%', '%Instagram%', '%Twitter%', '%LinkedIn%', '%Facebook%', '%Blog%']);
        } else if (contentTypeFilter == 'Blog Articles') {
          whereConditions.add('p.content_type LIKE ?');
          whereArgs.add('%Blog%');
        } else {
          whereConditions.add('p.content_type = ?');
          whereArgs.add(contentTypeFilter);
        }
      }

      if (usernameFilter != null && usernameFilter.isNotEmpty) {
        whereConditions.add('p.username LIKE ?');
        whereArgs.add('%$usernameFilter%');
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        whereConditions.add('(p.caption LIKE ? OR p.tags LIKE ? OR p.username LIKE ?)');
        final searchPattern = '%$searchQuery%';
        whereArgs.addAll([searchPattern, searchPattern, searchPattern]);
      }

      final whereClause = whereConditions.isNotEmpty
          ? 'WHERE ${whereConditions.join(' AND ')}'
          : '';

      // Get posts with like and comment counts
      final result = await db.rawQuery('''
        SELECT 
          p.*,
          COALESCE(l.like_count, 0) as like_count,
          COALESCE(c.comment_count, 0) as comment_count,
          CASE WHEN ul.username IS NOT NULL THEN 1 ELSE 0 END as is_liked
        FROM posts p
        LEFT JOIN (
          SELECT post_id, COUNT(*) as like_count
          FROM likes
          GROUP BY post_id
        ) l ON p.id = l.post_id
        LEFT JOIN (
          SELECT post_id, COUNT(*) as comment_count
          FROM comments
          GROUP BY post_id
        ) c ON p.id = c.post_id
        LEFT JOIN (
          SELECT post_id, username
          FROM likes
          WHERE username = ?
        ) ul ON p.id = ul.post_id
        $whereClause
        ORDER BY p.published_date DESC
      ''', [currentUsername ?? '', ...whereArgs]);

      debugPrint('📝 Retrieved ${result.length} posts from database');
      if (result.isNotEmpty) {
        debugPrint('First post: id=${result.first['id']}, username=${result.first['username']}, caption=${result.first['caption']}');
      }

      return result.map((row) {
        final tags = (row['tags'] as String).split(',').where((t) => t.isNotEmpty).toList();
        return Post(
          id: row['id'] as String,
          username: row['username'] as String,
          imageFile: row['image_path'] != null && File(row['image_path'] as String).existsSync()
              ? File(row['image_path'] as String)
              : null,
          caption: row['caption'] as String,
          tags: tags,
          contentType: row['content_type'] as String,
          publishedDate: DateTime.parse(row['published_date'] as String),
          createdAt: DateTime.parse(row['created_at'] as String),
          likeCount: row['like_count'] as int? ?? 0,
          commentCount: row['comment_count'] as int? ?? 0,
          isLikedByCurrentUser: (row['is_liked'] as int? ?? 0) == 1,
        );
      }).toList();
    } catch (e, stackTrace) {
      debugPrint('❌ Error getting all posts: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get posts by a specific user
  static Future<List<Post>> getPostsByUser(String username) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query(
        'posts',
        where: 'username = ?',
        whereArgs: [username],
        orderBy: 'published_date DESC',
      );

      return result.map((row) {
        final tags = (row['tags'] as String).split(',').where((t) => t.isNotEmpty).toList();
        return Post(
          id: row['id'] as String,
          username: row['username'] as String,
          imageFile: row['image_path'] != null && File(row['image_path'] as String).existsSync()
              ? File(row['image_path'] as String)
              : null,
          caption: row['caption'] as String,
          tags: tags,
          contentType: row['content_type'] as String,
          publishedDate: DateTime.parse(row['published_date'] as String),
          createdAt: DateTime.parse(row['created_at'] as String),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting posts by user: $e');
      return [];
    }
  }

  /// Delete a post
  static Future<void> deletePost(String postId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('posts', where: 'id = ?', whereArgs: [postId]);
    } catch (e) {
      debugPrint('Error deleting post: $e');
    }
  }
}

