import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../models/app_settings.dart';

/// Handles the admin activation lock.
/// Credentials are never stored in plain text - only salted SHA-256 hashes.
class AuthService {
  static const String _settingsBoxName = 'app_settings';
  static const String _defaultAdminId = 'FactoryFlowRP2026';
  static const String _defaultAdminPassword = 'AdxyRBP@7989Qwop';

  static Box<AppSettings> get _box => Hive.box<AppSettings>(_settingsBoxName);

  static String _generateSalt([int length = 16]) {
    final rand = Random.secure();
    final values = List<int>.generate(length, (_) => rand.nextInt(256));
    return base64UrlEncode(values);
  }

  static String _hash(String input, String salt) {
    final bytes = utf8.encode(input + salt);
    return sha256.convert(bytes).toString();
  }

  /// Called once on first app launch - seeds the default admin credentials.
  static Future<void> ensureInitialized() async {
    if (_box.isEmpty) {
      final salt = _generateSalt();
      final settings = AppSettings(
        adminIdHash: _hash(_defaultAdminId, salt),
        adminPasswordHash: _hash(_defaultAdminPassword, salt),
        salt: salt,
      );
      await _box.add(settings);
    }
  }

  static AppSettings get settings => _box.getAt(0)!;

  static bool verify(String id, String password) {
    final s = settings;
    return _hash(id, s.salt) == s.adminIdHash &&
        _hash(password, s.salt) == s.adminPasswordHash;
  }

  /// Allows changing admin credentials later from within the app if needed.
  static Future<void> updateCredentials(String newId, String newPassword) async {
    final s = settings;
    final salt = _generateSalt();
    s.adminIdHash = _hash(newId, salt);
    s.adminPasswordHash = _hash(newPassword, salt);
    s.salt = salt;
    await s.save();
  }
}
