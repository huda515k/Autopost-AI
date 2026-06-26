import 'package:sqflite/sqflite.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/user_model.dart';
import 'database_helper.dart';

class UserStorageService {
  /// Hash password using SHA-256 (in production, use bcrypt)
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Register a new user
  static Future<bool> registerUser(UserModel user) async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Check if username already exists
      final existingUser = await db.query(
        'users',
        where: 'LOWER(username) = ?',
        whereArgs: [user.username.toLowerCase()],
      );

      if (existingUser.isNotEmpty) {
        return false; // Username already exists
      }

      // Check if email already exists
      final existingEmail = await db.query(
        'users',
        where: 'LOWER(email) = ?',
        whereArgs: [user.email.toLowerCase()],
      );

      if (existingEmail.isNotEmpty) {
        return false; // Email already exists
      }

      // Insert new user with hashed password
      await db.insert('users', {
        'username': user.username,
        'password': _hashPassword(user.password), // Hash password
        'email': user.email,
        'bio': user.bio,
        'created_at': user.createdAt.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.fail);

      return true;
    } catch (e) {
      debugPrint('Error registering user: $e');
      return false;
    }
  }

  /// Login user
  static Future<UserModel?> loginUser(String username, String password) async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Find user by username (case-insensitive)
      final result = await db.query(
        'users',
        where: 'LOWER(username) = ?',
        whereArgs: [username.toLowerCase()],
        limit: 1,
      );

      if (result.isEmpty) {
        return null; // User not found
      }

      final userData = result.first;
      final storedPasswordHash = userData['password'] as String;
      final inputPasswordHash = _hashPassword(password);

      // Verify password
      if (storedPasswordHash != inputPasswordHash) {
        return null; // Invalid password
      }

      // Create user model
      final user = UserModel(
        username: userData['username'] as String,
        password: password, // Return original password for session (not stored)
        email: userData['email'] as String,
        bio: userData['bio'] as String?,
        createdAt: DateTime.parse(userData['created_at'] as String),
      );

      // Save current user session with replace to avoid duplicate-row conflicts
      await db.insert('current_user', {
        'username': user.username,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      return user;
    } catch (e) {
      debugPrint('Error logging in user: $e');
      return null;
    }
  }

  /// Authenticate an existing account using either username or email.
  /// This is useful when a signup attempt hits an account that already exists.
  static Future<UserModel?> authenticateExistingAccount(
    String username,
    String email,
    String password,
  ) async {
    try {
      final db = await DatabaseHelper.instance.database;

      final result = await db.query(
        'users',
        where: 'LOWER(username) = ? OR LOWER(email) = ?',
        whereArgs: [username.toLowerCase(), email.toLowerCase()],
        limit: 1,
      );

      if (result.isEmpty) {
        return null;
      }

      final userData = result.first;
      final storedPasswordHash = userData['password'] as String;
      final inputPasswordHash = _hashPassword(password);

      if (storedPasswordHash != inputPasswordHash) {
        return null;
      }

      final user = UserModel(
        username: userData['username'] as String,
        password: password,
        email: userData['email'] as String,
        bio: userData['bio'] as String?,
        createdAt: DateTime.parse(userData['created_at'] as String),
      );

      await db.insert('current_user', {
        'username': user.username,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      return user;
    } catch (e) {
      debugPrint('Error authenticating existing account: $e');
      return null;
    }
  }

  /// Get current logged in user
  static Future<UserModel?> getCurrentUser() async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Get current user session
      final session = await db.query('current_user', limit: 1);

      if (session.isEmpty) {
        return null; // No active session
      }

      final username = session.first['username'] as String;

      // Get user data
      final result = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
        limit: 1,
      );

      if (result.isEmpty) {
        return null;
      }

      final userData = result.first;
      return UserModel(
        username: userData['username'] as String,
        password: '', // Don't return password
        email: userData['email'] as String,
        bio: userData['bio'] as String?,
        createdAt: DateTime.parse(userData['created_at'] as String),
      );
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  /// Logout user
  static Future<void> logout() async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('current_user');
    } catch (e) {
      debugPrint('Error logging out: $e');
    }
  }

  /// Update user password
  static Future<bool> updatePassword(
    String username,
    String newPassword,
  ) async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Check if user exists
      final result = await db.query(
        'users',
        where: 'LOWER(username) = ?',
        whereArgs: [username.toLowerCase()],
        limit: 1,
      );

      if (result.isEmpty) {
        return false; // User not found
      }

      // Update password
      await db.update(
        'users',
        {'password': _hashPassword(newPassword)},
        where: 'LOWER(username) = ?',
        whereArgs: [username.toLowerCase()],
      );

      return true;
    } catch (e) {
      debugPrint('Error updating password: $e');
      return false;
    }
  }

  /// Check if username exists
  static Future<bool> usernameExists(String username) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query(
        'users',
        where: 'LOWER(username) = ?',
        whereArgs: [username.toLowerCase()],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking username: $e');
      return false;
    }
  }

  /// Update user profile
  static Future<bool> updateUser(UserModel updatedUser) async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Check if user exists
      final result = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: [updatedUser.username],
        limit: 1,
      );

      if (result.isEmpty) {
        return false;
      }

      // Update user (don't update password unless explicitly changed)
      await db.update(
        'users',
        {'email': updatedUser.email, 'bio': updatedUser.bio},
        where: 'username = ?',
        whereArgs: [updatedUser.username],
      );

      // Update current user session if it's the same user
      final currentUser = await getCurrentUser();
      if (currentUser != null && currentUser.username == updatedUser.username) {
        // Session is already linked by username, no need to update
      }

      return true;
    } catch (e) {
      debugPrint('Error updating user: $e');
      return false;
    }
  }

  /// Get all users (for admin purposes, if needed)
  static Future<List<UserModel>> getAllUsers() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query('users');

      return result
          .map(
            (row) => UserModel(
              username: row['username'] as String,
              password: '', // Don't return passwords
              email: row['email'] as String,
              bio: row['bio'] as String?,
              createdAt: DateTime.parse(row['created_at'] as String),
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting all users: $e');
      return [];
    }
  }
}
