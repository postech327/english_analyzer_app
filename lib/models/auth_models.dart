// lib/models/auth_models.dart

/// 회원가입 요청 모델
class RegisterRequest {
  final String name;
  final String school;
  final String gradeBand;
  final String email;
  final String phone;
  final String username;
  final String password;
  final String interest;
  final String? refCode;
  final bool marketingOptIn;
  final bool tos;
  final bool privacy;

  RegisterRequest({
    required this.name,
    required this.school,
    required this.gradeBand,
    required this.email,
    required this.phone,
    required this.username,
    required this.password,
    required this.interest,
    this.refCode,
    required this.marketingOptIn,
    required this.tos,
    required this.privacy,
  });

  Map<String, dynamic> toJson() => {
        "name": name,
        "school": school,
        "grade_band": gradeBand,
        "email": email,
        "phone": phone,
        "username": username,
        "password": password,
        "interest": interest,
        "ref_code": refCode,
        "agreements": {
          "marketing_opt_in": marketingOptIn,
          "tos": tos,
          "privacy": privacy,
        }
      };
}

/// 로그인 요청 모델
class LoginRequest {
  final String username; // 또는 이메일을 쓰려면 필드명만 바꾸면 됩니다.
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

/// 로그인 응답 모델 (백엔드 응답 키를 유연하게 파싱)
class LoginResponse {
  final String accessToken; // e.g., "access_token" or "token"
  final String tokenType; // 기본 'bearer'
  final DateTime? expiresAt;

  LoginResponse({
    required this.accessToken,
    this.tokenType = 'bearer',
    this.expiresAt,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> j) => LoginResponse(
        accessToken: (j['access_token'] ?? j['token'] ?? '') as String,
        tokenType: (j['token_type'] ?? 'bearer') as String,
        expiresAt: j['expires_at'] != null
            ? DateTime.tryParse(j['expires_at'].toString())
            : null,
      );
}
