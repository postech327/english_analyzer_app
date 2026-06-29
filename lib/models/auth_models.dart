// lib/models/auth_models.dart

// =====================================================
// 회원가입 요청 모델
// =====================================================
class RegisterRequest {
  final String name;
  final String school;
  final String email;
  final String phone;
  final String username;
  final String password;
  final String role;
  final String interest;
  final String? refCode;
  final bool marketingOptIn;
  final bool tos;
  final bool privacy;

  RegisterRequest({
    required this.name,
    required this.school,
    required this.email,
    required this.phone,
    required this.username,
    required this.password,
    required this.role,
    required this.interest,
    this.refCode,
    required this.marketingOptIn,
    required this.tos,
    required this.privacy,
  });

  Map<String, dynamic> toJson() => {
        "name": name,
        "school": school,
        "email": email,
        "phone": phone,
        "username": username,
        "password": password,
        "role": role,
        "interest": interest,
        "ref_code": refCode,
        "agreements": {
          "marketing_opt_in": marketingOptIn,
          "tos": tos,
          "privacy": privacy,
        }
      };
}

// =====================================================
// 로그인 요청 모델 (Swagger: POST /login)
// =====================================================
class LoginRequest {
  final String username;
  final String password;

  LoginRequest({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        "username": username,
        "password": password,
      };
}

// =====================================================
// 로그인 응답 모델 (Swagger 응답 완전 대응)
// =====================================================
class LoginResponse {
  final String accessToken;
  final String? refreshToken;
  final String tokenType;
  final DateTime? expiresAt;

  // 선택 정보 (있으면 사용)
  final int? userId;
  final String? nickname;
  final String? role;

  LoginResponse({
    required this.accessToken,
    this.refreshToken,
    this.tokenType = 'bearer',
    this.expiresAt,
    this.userId,
    this.nickname,
    this.role,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>?;
    final rawUserId = user?['id'] ?? j['user_id'] ?? j['id'];

    return LoginResponse(
      accessToken: (j['access_token'] ?? j['token'] ?? '') as String,
      refreshToken: j['refresh_token'] as String?,
      tokenType: (j['token_type'] ?? 'bearer') as String,
      expiresAt: j['expires_at'] != null
          ? DateTime.tryParse(j['expires_at'].toString())
          : null,
      userId: rawUserId is int ? rawUserId : int.tryParse('$rawUserId'),
      nickname:
          (user?['nickname'] ?? j['nickname'] ?? j['username']) as String?,
      role: (user?['role'] ?? j['role']) as String?,
    );
  }
}
