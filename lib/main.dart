import 'package:flutter/material.dart';
import 'package:autopost_ai/services/db_platform.dart';
import 'package:autopost_ai/auth_screen.dart';
import 'package:autopost_ai/autopost_screen.dart';
import 'package:autopost_ai/config/api_config.dart';
import 'package:autopost_ai/models/user_model.dart';
import 'package:autopost_ai/services/post_migration_service.dart';
import 'package:autopost_ai/services/post_storage_service.dart';
import 'package:autopost_ai/services/user_storage_service.dart';
import 'package:autopost_ai/services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pick the right SQLite backend for this platform (web: IndexedDB,
  // desktop: FFI, mobile: default plugin).
  configureDatabaseFactory();

  // Initialize theme service
  await ThemeService.instance.initialize();

  // Migrate published scheduled posts to posts table on app start
  await PostMigrationService.migratePublishedPosts();

  // Publish any scheduled posts whose time has arrived to the AutoPost AI feed.
  await PostStorageService.publishDueScheduledPosts();

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
