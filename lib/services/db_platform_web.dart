import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Configures the SQLite backend on the web (IndexedDB-backed).
/// Uses the no-web-worker factory so only `web/sqlite3.wasm` is required
/// (no generated worker JS).
void configureDatabaseFactory() {
  databaseFactory = databaseFactoryFfiWebNoWebWorker;
}
