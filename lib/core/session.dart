import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Session {
  static late SharedPreferences _prefs;
  static bool _ready = false;

  /// Incremented whenever the session state changes so the app can rebuild.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static bool get ready => _ready;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _ready = true;
    revision.value++;
  }

  static void _bump() => revision.value++;

  static bool _has(String key, {bool d = false}) =>
      _ready ? (_prefs.getBool(key) ?? d) : d;
  static String _str(String key) => _ready ? (_prefs.getString(key) ?? '') : '';
  static int _num(String key) => _ready ? (_prefs.getInt(key) ?? 0) : 0;

  static bool isLoggedIn() => _has('logged_in');

  /// Preferensi mode tema: '' (ikuti sistem), 'l' terang, 'd' gelap.
  static String get themeModePref => _str('theme_mode');
  static Future<void> setThemeModePref(String value) async {
    await _prefs.setString('theme_mode', value);
    _bump();
  }

  static String get role => _str('role');
  static int get userId => _num('user_id');
  static String get token => _str('token');
  static String get username => _str('username');
  static String get name => _str('name');
  static String get nis => _str('nis');
  static String get nisn => _str('nisn');
  static String get waliNama => _str('wali_nama');
  static String get status => _str('status');
  static String get kelas => _str('kelas');
  static String get tempatLahir => _str('tempat_lahir');
  static String get tanggalLahir => _str('tanggal_lahir');
  static String get alamat => _str('alamat');

  static void save({
    required String role,
    required int userId,
    required String token,
    required String username,
    required String name,
    required String nis,
    required String nisn,
    required String waliNama,
    String status = '',
    String kelas = '',
    String tempatLahir = '',
    String tanggalLahir = '',
    String alamat = '',
  }) {
    _prefs.setBool('logged_in', true);
    _prefs.setString('role', role);
    _prefs.setInt('user_id', userId);
    _prefs.setString('token', token);
    _prefs.setString('username', username);
    _prefs.setString('name', name);
    _prefs.setString('nis', nis);
    _prefs.setString('nisn', nisn);
    _prefs.setString('wali_nama', waliNama);
    _prefs.setString('status', status);
    _prefs.setString('kelas', kelas);
    _prefs.setString('tempat_lahir', tempatLahir);
    _prefs.setString('tanggal_lahir', tanggalLahir);
    _prefs.setString('alamat', alamat);
    _bump();
  }

  static Future<void> applyProfil({
    String status = '',
    String kelas = '',
    String tempatLahir = '',
    String tanggalLahir = '',
    String alamat = '',
  }) async {
    if (status.isNotEmpty) await _prefs.setString('status', status);
    if (kelas.isNotEmpty) await _prefs.setString('kelas', kelas);
    if (tempatLahir.isNotEmpty) await _prefs.setString('tempat_lahir', tempatLahir);
    if (tanggalLahir.isNotEmpty) await _prefs.setString('tanggal_lahir', tanggalLahir);
    if (alamat.isNotEmpty) await _prefs.setString('alamat', alamat);
    _bump();
  }

  static Future<void> logout() async {
    await _prefs.clear();
    _bump();
  }
}