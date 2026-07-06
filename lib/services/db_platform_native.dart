import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Configures the SQLite backend on native platforms.
/// Desktop (macOS/Windows/Linux) uses the FFI backend; mobile uses the
/// default sqflite plugin (no configuration needed).
void configureDatabaseFactory() {
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
