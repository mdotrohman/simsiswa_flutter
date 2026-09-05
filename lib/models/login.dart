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

  LoginData({
    required this.role,
    required this.userId,
    required this.token,
    required this.username,
    required this.name,
    required this.nis,
    required this.nisn,
    required this.waliNama,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      role: json['role']?.toString() ?? '',
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      token: json['token']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      nis: json['nis']?.toString() ?? '',
      nisn: json['nisn']?.toString() ?? '',
      waliNama: json['wali_nama']?.toString() ?? '',
    );
  }
}