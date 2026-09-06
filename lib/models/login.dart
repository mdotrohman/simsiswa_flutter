class LoginResponse {
  final bool success;
  final String message;
  final LoginData? data;

  LoginResponse({required this.success, required this.message, this.data});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: json['data'] == null
          ? null
          : LoginData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class LoginData {
  final String role;
  final int userId;
  final String token;
  final String username;
  final String name;
  final String nis;
  final String nisn;
  final String waliNama;

  // Data bio siswa/wali (opsional — bila server mengirimnya).
  final String status;
  final String kelas;
  final String tempatLahir;
  final String tanggalLahir;
  final String alamat;

  LoginData({
    required this.role,
    required this.userId,
    required this.token,
    required this.username,
    required this.name,
    required this.nis,
    required this.nisn,
    required this.waliNama,
    this.status = '',
    this.kelas = '',
    this.tempatLahir = '',
    this.tanggalLahir = '',
    this.alamat = '',
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => v?.toString() ?? '';
    return LoginData(
      role: s(json['role']),
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      token: s(json['token']),
      username: s(json['username']),
      name: s(json['name'] ?? json['nama_lengkap']),
      nis: s(json['nis']),
      nisn: s(json['nisn']),
      waliNama: s(json['wali_nama']),
      status: s(json['status'] ?? json['status_siswa']),
      kelas: s(json['kelas'] ?? json['nama_kelas']),
      tempatLahir: s(json['tempat_lahir']),
      tanggalLahir: s(json['tanggal_lahir']),
      alamat: _composeAlamat(json, s(json['alamat'])),
    );
  }

  /// Menyusun alamat rumah lengkap dari bagian-bagiannya (bila server
  /// mengirimnya terpisah di login), pola sama dengan endpoint profil siswa.
  static String _composeAlamat(Map<String, dynamic> j, String raw) {
    final parts = <String>[];
    if (raw.isNotEmpty) parts.add(raw);
    final rt = (j['rt']?.toString() ?? '').trim();
    final rw = (j['rw']?.toString() ?? '').trim();
    if (rt.isNotEmpty || rw.isNotEmpty) {
      if (rt.isNotEmpty && rw.isNotEmpty) {
        parts.add('RT $rt/RW $rw');
      } else if (rt.isNotEmpty) {
        parts.add('RT $rt');
      } else {
        parts.add('RW $rw');
      }
    }
    for (final key in ['desa_kelurahan', 'kecamatan', 'kabupaten_kota', 'provinsi']) {
      final v = (j[key]?.toString() ?? '').trim();
      if (v.isNotEmpty) parts.add(v);
    }
    final kp = (j['kode_pos']?.toString() ?? '').trim();
    if (kp.isNotEmpty) parts.add(kp);
    return parts.join(', ');
  }
}