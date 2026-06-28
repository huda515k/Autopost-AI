import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:autopost_ai/models/user_model.dart';
import 'package:autopost_ai/services/user_storage_service.dart';

// Exercises the real auth logic the login/signup/forgot-password screens call.
void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // Start from a clean database file.
    final path = join(await databaseFactory.getDatabasesPath(), 'autopost_ai.db');
    if (await File(path).exists()) await File(path).delete();
  });

  test('signup -> login -> wrong password -> reset password', () async {
    final user = UserModel(
      username: 'flowtest',
      password: 'secret123',
      email: 'flowtest@example.com',
      createdAt: DateTime.now(),
    );

    // SIGN UP: first registration succeeds.
    expect(await UserStorageService.registerUser(user), isTrue);

    // SIGN UP again with same username/email fails (no duplicates).
    expect(await UserStorageService.registerUser(user), isFalse);

    // LOGIN with wrong password is rejected.
    expect(await UserStorageService.loginUser('flowtest', 'wrongpass'), isNull);

    // LOGIN with correct password succeeds.
    final loggedIn = await UserStorageService.loginUser('flowtest', 'secret123');
    expect(loggedIn, isNotNull);
    expect(loggedIn!.username, 'flowtest');

    // FORGOT PASSWORD: username exists check + reset.
    expect(await UserStorageService.usernameExists('flowtest'), isTrue);
    expect(await UserStorageService.usernameExists('nobody'), isFalse);
    expect(await UserStorageService.updatePassword('flowtest', 'newpass456'), isTrue);

    // After reset, old password fails and the new one works.
    expect(await UserStorageService.loginUser('flowtest', 'secret123'), isNull);
    expect(await UserStorageService.loginUser('flowtest', 'newpass456'), isNotNull);
  });
}
