import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:autopost_ai/auth_screen.dart';
import 'package:autopost_ai/autopost_screen.dart';
import 'package:autopost_ai/config/api_config.dart';
import 'package:autopost_ai/models/user_model.dart';
import 'package:autopost_ai/services/post_migration_service.dart';
import 'package:autopost_ai/services/user_storage_service.dart';
import 'package:autopost_ai/services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use the FFI SQLite backend on desktop platforms (sqflite has no native
  // plugin for macOS/Windows/Linux).
  if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize theme service
  await ThemeService.instance.initialize();

  // Migrate published scheduled posts to posts table on app start
  await PostMigrationService.migratePublishedPosts();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Listen to theme changes
    ThemeService.instance.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeService.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, child) {
        return MaterialApp(
          title: 'AutoPost AI',
          theme: ThemeService.getLightTheme(),
          darkTheme: ThemeService.getDarkTheme(),
          themeMode: ThemeService.instance.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          home: const AppGate(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class AppGate extends StatelessWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: UserStorageService.getCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user != null) {
          return AutoPostScreen(
            apiKey: ApiConfig.geminiApiKey,
            imageApiKey: ApiConfig.imageApiKey,
            currentUser: user,
          );
        }

        return const AuthScreen();
      },
    );
  }
}
