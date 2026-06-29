// lib/services/auth_service.dart
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/api.dart';
import '../config/auth_store.dart';
import '../models/auth_models.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _kToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kUserId = 'user_id';
  static const _kNickname = 'nickname';
  static const _kRole = 'role';

  final _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> register(RegisterRequest req) async {
    final uri = ApiConfig.u(ApiConfig.authRegister);

    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(req.toJson()),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(_extractError(res.body, fallback: '회원가입 실패'));
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> checkUsername(String username) async {
    final uri = ApiConfig.u(
      '/auth/check-username?username=${Uri.encodeQueryComponent(username)}',
    );

    final res = await http.get(uri).timeout(const Duration(seconds: 12));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(_extractError(res.body, fallback: '아이디 확인 실패'));
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<LoginResponse> login(LoginRequest req) async {
    final uri = ApiConfig.u(ApiConfig.login);

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'username': req.username,
        'password': req.password,
      },
    ).timeout(const Duration(seconds: 20));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(_extractError(res.body, fallback: '로그인 실패'));
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final login = LoginResponse.fromJson(data);

    await _persistLogin(login);

    AuthStore.saveLogin(
      accessTokenValue: login.accessToken,
      refreshTokenValue: login.refreshToken,
      userIdValue: login.userId,
      nicknameValue: login.nickname,
      roleValue: login.role,
    );

    return login;
  }

  Future<String?> getToken() => _storage.read(key: _kToken);

  Future<String?> currentAccessToken() async {
    final memoryToken = AuthStore.accessToken?.trim();
    if (memoryToken != null && memoryToken.isNotEmpty) return memoryToken;

    final storedToken = (await _storage.read(key: _kToken))?.trim();
    if (storedToken == null || storedToken.isEmpty) return null;
    AuthStore.accessToken = storedToken;
    return storedToken;
  }

  Future<String?> refreshAccessToken() async {
    final refreshToken =
        (AuthStore.refreshToken ?? await _storage.read(key: _kRefreshToken))
            ?.trim();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    final response = await http
        .post(
          ApiConfig.u('/auth/refresh'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh_token': refreshToken}),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) return null;

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! Map<String, dynamic>) return null;
    final accessToken = data['access_token']?.toString().trim();
    if (accessToken == null || accessToken.isEmpty) return null;

    await _storage.write(key: _kToken, value: accessToken);
    AuthStore.accessToken = accessToken;
    AuthStore.refreshToken ??= refreshToken;
    return accessToken;
  }

  Future<void> restoreSession() async {
    final accessToken = await _storage.read(key: _kToken);
    if (accessToken == null) return;

    final refreshToken = await _storage.read(key: _kRefreshToken);
    final userId = await _storage.read(key: _kUserId);
    final nickname = await _storage.read(key: _kNickname);
    final role = await _storage.read(key: _kRole);

    AuthStore.saveLogin(
      accessTokenValue: accessToken,
      refreshTokenValue: refreshToken,
      userIdValue: userId == null ? null : int.tryParse(userId),
      nicknameValue: nickname,
      roleValue: role,
    );
  }

  Future<void> logout() async {
    await _storage.delete(key: _kToken);
    await _storage.delete(key: _kRefreshToken);
    await _storage.delete(key: _kUserId);
    await _storage.delete(key: _kNickname);
    await _storage.delete(key: _kRole);
    AuthStore.clear();
  }

  Future<void> _persistLogin(LoginResponse login) async {
    await _storage.write(key: _kToken, value: login.accessToken);

    if (login.refreshToken != null) {
      await _storage.write(key: _kRefreshToken, value: login.refreshToken);
    }
    if (login.userId != null) {
      await _storage.write(key: _kUserId, value: login.userId.toString());
    }
    if (login.nickname != null) {
      await _storage.write(key: _kNickname, value: login.nickname);
    }
    if (login.role != null) {
      await _storage.write(key: _kRole, value: login.role);
    }
  }

  static String _extractError(String body, {String fallback = '요청 실패'}) {
    try {
      final m = jsonDecode(body) as Map<String, dynamic>;
      if (m['detail'] is String) return m['detail'] as String;
      if (m['detail'] is List) {
        final errors = (m['detail'] as List)
            .map((item) {
              if (item is! Map<String, dynamic>) return '';
              final loc =
                  item['loc'] is List ? (item['loc'] as List).join(' > ') : '';
              final msg = item['msg']?.toString() ?? '';
              if (loc.isEmpty) return msg;
              return '$loc: $msg';
            })
            .where((text) => text.trim().isNotEmpty)
            .join('\n');
        if (errors.isNotEmpty) return errors;
      }
      if (m['message'] is String) return m['message'] as String;
      if (m['error'] is String) return m['error'] as String;
    } catch (_) {}
    return fallback;
  }
}
