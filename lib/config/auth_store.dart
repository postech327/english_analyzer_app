// lib/config/auth_store.dart

class AuthStore {
  static String? accessToken;
  static String? refreshToken;
  static int? userId;
  static String? nickname;
  static String? role;

  static bool get isLoggedIn => accessToken != null;
  static String get normalizedRole => (role ?? '').trim().toLowerCase();
  static bool get isTeacher => normalizedRole == 'teacher';
  static bool get isStudent => normalizedRole == 'student';

  static void saveLogin({
    required String accessTokenValue,
    String? refreshTokenValue,
    int? userIdValue,
    String? nicknameValue,
    String? roleValue,
  }) {
    accessToken = accessTokenValue;
    refreshToken = refreshTokenValue;
    userId = userIdValue;
    nickname = nicknameValue;
    role = roleValue;
  }

  static String landingRoute({String? fallbackUsername}) {
    if (isTeacher) return '/teacher';
    if (isStudent) return '/app';

    final username = (fallbackUsername ?? '').trim().toLowerCase();
    if (username == 'teacher1') return '/teacher';
    return '/app';
  }

  static void clear() {
    accessToken = null;
    refreshToken = null;
    userId = null;
    nickname = null;
    role = null;
  }
}
