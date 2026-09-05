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

  static String get role => _str('role');
  static int get userId => _num('user_id');
  static String get token => _str('token');
  static String get username => _str('username');
  static String get name => _str('name');
  static String get nis => _str('nis');
  static String get nisn => _str('nisn');
  static String get waliNama => _str('wali_nama');

  static void save({
    required String role,
    required int userId,
    required String token,
    required String username,
    required String name,
    required String nis,
    required String nisn,
    required String waliNama,
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
    _bump();
  }

  static Future<void> logout() async {
    await _prefs.clear();
    _bump();
  }
}