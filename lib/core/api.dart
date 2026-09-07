import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/login.dart';
import '../models/profil.dart';
import 'session.dart';

const String kApiBaseUrl = 'https://sim.mtsbutambakberas.sch.id/';

class ApiException implements Exception {
  final int code;
  final String message;
  ApiException(this.code, this.message);

  @override
  String toString() => message;
}

class Api {
  static Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final base = Uri.parse(kApiBaseUrl);
    final uri = base.resolve(path);

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final token = Session.token;
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    http.Response res;
    try {
      if (method == 'POST') {
        res = await http
            .post(uri, headers: headers, body: jsonEncode(body ?? const {}))
            .timeout(const Duration(seconds: 20));
      } else {
        res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));
      }
    } catch (e) {
      throw ApiException(0, 'Koneksi gagal: $e');
    }

    switch (res.statusCode) {
      case 403:
        throw ApiException(403, 'Koneksi ditolak (pastikan menggunakan HTTPS)');
      case 429:
        throw ApiException(429, 'Terlalu banyak percobaan login. Coba lagi dalam 15 menit.');
      case 401:
        throw ApiException(401, 'Sesi berakhir. Silakan login ulang.');
      default:
        if (res.statusCode >= 500) {
          throw ApiException(res.statusCode, 'Server sedang bermasalah. Silakan coba lagi.');
        }
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw ApiException(res.statusCode, 'Gagal terhubung ke server (kode: ${res.statusCode})');
        }
    }

    try {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(res.statusCode, 'Respons tidak valid dari server.');
    }
  }

  static Future<LoginData> login({
    required String username,
    required String password,
    required String role,
  }) async {
    final json = await _send('POST', 'app/api/apk/siswa/login', body: {
      'username': username,
      'password': password,
      'role': role,
    });
    final resp = LoginResponse.fromJson(json);
    if (!resp.success || resp.data == null) {
      throw ApiException(200, resp.message.isEmpty ? 'Login gagal' : resp.message);
    }
    return resp.data!;
  }

  static Future<ProfilResponse> publicProfil() async {
    final json = await _send('GET', 'app/api/apk/siswa/public_profil');
    final resp = ProfilResponse.fromJson(json);
    if (!resp.ok || resp.profil == null) {
      throw ApiException(200, resp.message.isEmpty ? 'Data profil tidak tersedia' : resp.message);
    }
    return resp;
  }

  static Future<Map<String, dynamic>> dashboard() => _send('GET', 'api/dashboard');

  /// Profil lengkap siswa (GET app/api/apk/profil_siswa).
  /// Data siswa diambil dari sesi token (guard), bukan dari input klien.
  /// Mengembalikan objek `data` berisi `siswa`, `sekolah_asal`, `mutasi`,
  /// `orangtua` (ayah/ibu/wali), `lampiran`, dan `riwayat_kelas`.
  static Future<Map<String, dynamic>> profil() async {
    final json = await _send('GET', 'app/api/apk/profil_siswa');
    if (json['success'] != true || json['data'] is! Map) {
      throw ApiException(
          200, json['message']?.toString() ?? 'Data profil tidak tersedia');
    }
    return (json['data'] as Map<String, dynamic>);
  }

  /// Daftar pengumuman publik untuk siswa (POST app/api/apk/siswa/pengumuman).
  /// Mengembalikan objek `data` berisi `list`, `total`, `page`, `per_page`.
  static Future<Map<String, dynamic>> pengumumanList({
    int page = 1,
    int perPage = 20,
  }) async {
    final json = await _send('POST', 'app/api/apk/siswa/pengumuman', body: {
      'aksi': 'list',
      'siswa_id': Session.userId,
      'page': page,
      'per_page': perPage,
    });
    if (json['success'] != true || json['data'] is! Map) {
      throw ApiException(
          200, json['message']?.toString() ?? 'Gagal memuat pengumuman.');
    }
    return (json['data'] as Map<String, dynamic>);
  }

  /// Detail satu pengumuman (POST app/api/apk/siswa/pengumuman).
  static Future<Map<String, dynamic>> pengumumanDetail(int id) async {
    final json = await _send('POST', 'app/api/apk/siswa/pengumuman', body: {
      'aksi': 'detail',
      'siswa_id': Session.userId,
      'id': id,
    });
    if (json['success'] != true || json['data'] is! Map) {
      throw ApiException(
          200, json['message']?.toString() ?? 'Pengumuman tidak ditemukan.');
    }
    final data = json['data'] as Map<String, dynamic>;
    final detail = data['detail'];
    if (detail is! Map) {
      throw ApiException(200, 'Detail pengumuman tidak tersedia.');
    }
    return detail as Map<String, dynamic>;
  }

  /// Daftarkan/mutakhirkan token notifikasi HP milik siswa
  /// (POST app/api/apk/siswa/fcm_token). Best-effort; error diabaikan pemanggil.
  static Future<void> registerFcmToken(String token) async {
    await _send('POST', 'app/api/apk/siswa/fcm_token', body: {
      'aksi': 'simpan',
      'siswa_id': Session.userId,
      'token_hp': token,
    });
  }

  /// Simpan perubahan data siswa (POST app/api/apk/siswa/update_siswa).
  /// [fields] harus berisi kolom tabel `siswa` (sama persis dengan data
  /// `siswa` pada GET app/api/apk/profil_siswa). Mengembalikan pesan server.
  static Future<String> updateSiswa(Map<String, dynamic> fields) async {
    final json = await _send('POST', 'app/api/apk/siswa/update_siswa', body: {
      'siswa_id': Session.userId,
      'data': fields,
    });
    if (json['success'] == true) {
      return json['message']?.toString() ?? 'Data siswa berhasil disimpan.';
    }
    throw ApiException(
        200, json['message']?.toString() ?? 'Gagal menyimpan data siswa.');
  }
}