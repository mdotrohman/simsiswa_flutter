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
      name: s(json['name']),
      nis: s(json['nis']),
      nisn: s(json['nisn']),
      waliNama: s(json['wali_nama']),
      status: s(json['status']),
      kelas: s(json['kelas']),
      tempatLahir: s(json['tempat_lahir']),
      tanggalLahir: s(json['tanggal_lahir']),
      alamat: s(json['alamat']),
    );
  }
}