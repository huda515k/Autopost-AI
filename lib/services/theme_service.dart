import 'package:flutter/material.dart';
import 'database_helper.dart';

class ThemeService extends ChangeNotifier {
  static ThemeService? _instance;
  
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeService._internal();

  static ThemeService get instance {
    _instance ??= ThemeService._internal();
    return _instance!;
  }

  Future<void> initialize() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query(
        'theme_preference',
        where: 'id = ?',
        whereArgs: [1],
        limit: 1,
      );
      
      if (result.isNotEmpty) {
        _isDarkMode = (result.first['is_dark_mode'] as int? ?? 0) == 1;
      } else {
        // Insert default row if it doesn't exist
        await db.insert('theme_preference', {
          'id': 1,
          'is_dark_mode': 0,
        });
        _isDarkMode = false;
      }
      notifyListeners();
      debugPrint('✅ Theme initialized: ${_isDarkMode ? "Dark" : "Light"}');
    } catch (e) {
      debugPrint('❌ Error initializing theme: $e');
      _isDarkMode = false;
    }
  }

  Future<bool> getDarkModeAsync() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query(
        'theme_preference',
        where: 'id = ?',
        whereArgs: [1],
        limit: 1,
      );
      
      if (result.isNotEmpty) {
        return (result.first['is_dark_mode'] as int? ?? 0) == 1;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error getting theme: $e');
      return false;
    }
  }

  Future<void> setDarkMode(bool isDark) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rowsAffected = await db.update(
        'theme_preference',
        {'is_dark_mode': isDark ? 1 : 0},
        where: 'id = ?',
        whereArgs: [1],
      );
      
      if (rowsAffected == 0) {
        // Insert if doesn't exist
        await db.insert('theme_preference', {
          'id': 1,
          'is_dark_mode': isDark ? 1 : 0,
        });
      }
      
      _isDarkMode = isDark;
      notifyListeners();
      debugPrint('✅ Theme set to: ${isDark ? "Dark" : "Light"}');
    } catch (e) {
      debugPrint('❌ Error setting theme: $e');
    }
  }

  Future<void> toggleTheme() async {
    await setDarkMode(!_isDarkMode);
  }

  static ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF572D74),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      cardColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Color(0xFF1A1A1A),
        iconTheme: IconThemeData(color: Color(0xFF572D74)),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF1A1A1A)),
        bodyMedium: TextStyle(color: Color(0xFF1A1A1A)),
        titleLarge: TextStyle(color: Color(0xFF1A1A1A)),
        titleMedium: TextStyle(color: Color(0xFF1A1A1A)),
      ),
      dividerColor: Colors.grey[300],
    );
  }

  static ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF572D74),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardColor: const Color(0xFF1E1E1E),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        elevation: 0,
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Color(0xFF572D74)),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
        titleLarge: TextStyle(color: Colors.white),
        titleMedium: TextStyle(color: Colors.white),
      ),
      dividerColor: Colors.grey[700],
    );
  }
}

