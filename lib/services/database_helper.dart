import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('autopost_ai.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5, // Updated to 5 for notifications table
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        username TEXT PRIMARY KEY,
        password TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        bio TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Scheduled posts table
    await db.execute('''
      CREATE TABLE scheduled_posts (
        id TEXT PRIMARY KEY,
        image_path TEXT,
        caption TEXT NOT NULL,
        tags TEXT NOT NULL,
        scheduled_date TEXT NOT NULL,
        is_published INTEGER NOT NULL DEFAULT 0,
        published_date TEXT,
        content_type TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Current user session table
    await db.execute('''
      CREATE TABLE current_user (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        FOREIGN KEY (username) REFERENCES users(username) ON DELETE CASCADE
      )
    ''');

    // Published posts table
    await db.execute('''
      CREATE TABLE posts (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL,
        image_path TEXT,
        caption TEXT NOT NULL,
        tags TEXT NOT NULL,
        content_type TEXT NOT NULL,
        published_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (username) REFERENCES users(username) ON DELETE CASCADE
      )
    ''');

    // Likes table
    await db.execute('''
      CREATE TABLE likes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        post_id TEXT NOT NULL,
        username TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
        FOREIGN KEY (username) REFERENCES users(username) ON DELETE CASCADE,
        UNIQUE(post_id, username)
      )
    ''');

    // Comments table
    await db.execute('''
      CREATE TABLE comments (
        id TEXT PRIMARY KEY,
        post_id TEXT NOT NULL,
        username TEXT NOT NULL,
        comment_text TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
        FOREIGN KEY (username) REFERENCES users(username) ON DELETE CASCADE
      )
    ''');

    // Social media links table
    await db.execute('''
      CREATE TABLE social_media_links (
        username TEXT PRIMARY KEY,
        instagram TEXT,
        linkedin TEXT,
        facebook TEXT,
        instagram_public INTEGER NOT NULL DEFAULT 1,
        linkedin_public INTEGER NOT NULL DEFAULT 1,
        facebook_public INTEGER NOT NULL DEFAULT 1,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (username) REFERENCES users(username) ON DELETE CASCADE
      )
    ''');

    // Theme preference table (global setting, not per-user)
    await db.execute('''
      CREATE TABLE theme_preference (
        id INTEGER PRIMARY KEY DEFAULT 1,
        is_dark_mode INTEGER NOT NULL DEFAULT 0,
        CHECK (id = 1)
      )
    ''');
    
    // Insert default row
    await db.insert('theme_preference', {'id': 1, 'is_dark_mode': 0});

    // Notifications table
    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL,
        type TEXT NOT NULL,
        post_id TEXT,
        from_username TEXT,
        message TEXT,
        is_read INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        metadata TEXT,
        FOREIGN KEY (username) REFERENCES users(username) ON DELETE CASCADE,
        FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE
      )
    ''');

    // Index for faster queries
    await db.execute('''
      CREATE INDEX idx_notifications_username ON notifications(username, is_read, created_at)
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_posts_username ON posts(username)');
    await db.execute('CREATE INDEX idx_posts_published_date ON posts(published_date)');
    await db.execute('CREATE INDEX idx_likes_post_id ON likes(post_id)');
    await db.execute('CREATE INDEX idx_comments_post_id ON comments(post_id)');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 5) {
      // Create notifications table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notifications (
          id TEXT PRIMARY KEY,
          username TEXT NOT NULL,
          type TEXT NOT NULL,
          post_id TEXT,
          from_username TEXT,
          message TEXT,
          is_read INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          metadata TEXT,
          FOREIGN KEY (username) REFERENCES users(username) ON DELETE CASCADE,
          FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE
        )
      ''');
      // Create index
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_notifications_username 
        ON notifications(username, is_read, created_at)
      ''');
      debugPrint('✅ Created notifications table (upgrade from version $oldVersion to $newVersion)');
    }
            if (oldVersion < 4) {
      // Update theme_preference table structure (remove username dependency)
      try {
        await db.execute('DROP TABLE IF EXISTS theme_preference');
      } catch (e) {
        debugPrint('Error dropping old theme_preference table: $e');
      }
      
      // Create new theme preference table (global setting)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS theme_preference (
          id INTEGER PRIMARY KEY DEFAULT 1,
          is_dark_mode INTEGER NOT NULL DEFAULT 0,
          CHECK (id = 1)
        )
      ''');
      
      // Insert default row
      try {
        await db.insert('theme_preference', {'id': 1, 'is_dark_mode': 0}, conflictAlgorithm: ConflictAlgorithm.ignore);
      } catch (e) {
        debugPrint('Error inserting default theme preference: $e');
      }
    }
    if (oldVersion < 3) {
      // Add privacy columns to social_media_links if they don't exist
      try {
        await db.execute('ALTER TABLE social_media_links ADD COLUMN instagram_public INTEGER NOT NULL DEFAULT 1');
      } catch (e) {
        // Column might already exist
      }
      try {
        await db.execute('ALTER TABLE social_media_links ADD COLUMN linkedin_public INTEGER NOT NULL DEFAULT 1');
      } catch (e) {
        // Column might already exist
      }
      try {
        await db.execute('ALTER TABLE social_media_links ADD COLUMN facebook_public INTEGER NOT NULL DEFAULT 1');
      } catch (e) {
        // Column might already exist
      }

      // Create theme preference table (global setting)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS theme_preference (
          id INTEGER PRIMARY KEY DEFAULT 1,
          is_dark_mode INTEGER NOT NULL DEFAULT 0,
          CHECK (id = 1)
        )
      ''');
      
      // Insert default row if it doesn't exist
      try {
        await db.insert('theme_preference', {'id': 1, 'is_dark_mode': 0}, conflictAlgorithm: ConflictAlgorithm.ignore);
      } catch (e) {
        // Row might already exist
      }
    }
    if (oldVersion < 2) {
      // Add new tables for version 2
      await db.execute('''
        CREATE TABLE IF NOT EXISTS posts (
          id TEXT PRIMARY KEY,
          username TEXT NOT NULL,
          image_path TEXT,
          caption TEXT NOT NULL,
          tags TEXT NOT NULL,
          content_type TEXT NOT NULL,
          published_date TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (username) REFERENCES users(username) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS likes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          post_id TEXT NOT NULL,
          username TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
          FOREIGN KEY (username) REFERENCES users(username) ON DELETE CASCADE,
          UNIQUE(post_id, username)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS comments (
          id TEXT PRIMARY KEY,
          post_id TEXT NOT NULL,
          username TEXT NOT NULL,
          comment_text TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
          FOREIGN KEY (username) REFERENCES users(username) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS social_media_links (
          username TEXT PRIMARY KEY,
          instagram TEXT,
          linkedin TEXT,
          facebook TEXT,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (username) REFERENCES users(username) ON DELETE CASCADE
        )
      ''');

      // Create indexes
      await db.execute('CREATE INDEX IF NOT EXISTS idx_posts_username ON posts(username)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_posts_published_date ON posts(published_date)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_likes_post_id ON likes(post_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_comments_post_id ON comments(post_id)');
    }
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

