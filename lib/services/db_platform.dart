// Chooses the right SQLite backend per platform.
// The correct implementation is picked at compile time via conditional import:
// - web  -> db_platform_web.dart   (IndexedDB via sqflite_common_ffi_web)
// - else -> db_platform_native.dart (native mobile / FFI desktop)
export 'db_platform_native.dart' if (dart.library.js_interop) 'db_platform_web.dart';
