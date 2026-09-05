import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Penyimpanan kredensial login terenkripsi di Keystore (Android) / Keychain
/// (iOS) — setara penawaran "Save password?" Google. Tidak pernah ditulis ke
/// [SharedPreferences], sehingga aman dari backup/snapshot biasa dan tetap
/// bertahan saat [Session.logout].
class CredentialStore {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true, resetOnError: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _kUser = 'saved_username';
  static const _kRole = 'saved_role';
  static const _kPass = 'saved_password';

  static Future<({String username, String role, String password})?> load() async {
    try {
      final u = await _storage.read(key: _kUser);
      final p = await _storage.read(key: _kPass);
      if (u == null || u.isEmpty || p == null || p.isEmpty) return null;
      final r = await _storage.read(key: _kRole) ?? 'siswa';
      return (username: u, role: r, password: p);
    } catch (_) {
      return null;
    }
  }

  static Future<void> save({
    required String username,
    required String role,
    required String password,
  }) async {
    try {
      await _storage.write(key: _kUser, value: username);
      await _storage.write(key: _kRole, value: role);
      await _storage.write(key: _kPass, value: password);
    } catch (_) {
      // Perangkat/Keystore tak mendukung -> fitur diam-diam nonaktif.
    }
  }

  static Future<void> clear() async {
    try {
      await _storage.delete(key: _kUser);
      await _storage.delete(key: _kRole);
      await _storage.delete(key: _kPass);
    } catch (_) {}
  }
}