import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/auth_store.dart';

class CommunityService {
  static const String baseUrl =
      String.fromEnvironment('API_BASE', defaultValue: 'http://127.0.0.1:8000');

  // 🔐 공통 Authorization 헤더
  static Map<String, String> _authHeaders() {
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${AuthStore.accessToken}",
    };
  }

  // ─────────────────────────────────────────────
  // 📌 게시글 목록 조회 (비인증 가능)
  // ─────────────────────────────────────────────
  static Future<List<dynamic>> fetchPosts() async {
    print("🔥 BASE URL: $baseUrl");
    print("🔥 요청 URL: $baseUrl/community/posts");

    final response = await http.get(
      Uri.parse('$baseUrl/community/posts'),
    );

    print("🔥 상태 코드: ${response.statusCode}");
    print("🔥 응답 바디: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('게시글 목록 불러오기 실패');
    }
  }

  // ─────────────────────────────────────────────
  // 📌 게시글 상세 조회
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> fetchPostDetail(int postId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/community/posts/$postId'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('게시글 상세 조회 실패');
    }
  }

  // ─────────────────────────────────────────────
  // 📌 내 게시글 조회 (JWT 필요)
  // ─────────────────────────────────────────────
  static Future<List<dynamic>> fetchMyPosts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/community/my-posts'),
      headers: _authHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('내 게시글 조회 실패');
    }
  }

  // ─────────────────────────────────────────────
  // ✏ 게시글 작성 (author_id 제거)
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> createPost({
    required String title,
    required String content,
    required String region,
    required String category,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/community/posts"),
      headers: _authHeaders(),
      body: jsonEncode({
        "title": title,
        "content": content,
        "region": region,
        "category": category,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(response.body);
    }
  }

  // ─────────────────────────────────────────────
  // 📝 게시글 수정
  // ─────────────────────────────────────────────
  static Future<void> updatePost({
    required int postId,
    required String title,
    required String content,
    required String category,
    required String region,
  }) async {
    final response = await http.put(
      Uri.parse("$baseUrl/community/posts/$postId"),
      headers: _authHeaders(),
      body: jsonEncode({
        "title": title,
        "content": content,
        "category": category,
        "region": region,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("게시글 수정 실패");
    }
  }

  // ─────────────────────────────────────────────
  // 🗑 게시글 삭제
  // ─────────────────────────────────────────────
  static Future<void> deletePost(int postId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/community/posts/$postId"),
      headers: _authHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception("게시글 삭제 실패");
    }
  }

  // ─────────────────────────────────────────────
  // 💬 댓글 작성 (author_id 제거)
  // ─────────────────────────────────────────────
  static Future<void> createComment({
    required int postId,
    required String content,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/community/posts/$postId/comments"),
      headers: _authHeaders(),
      body: jsonEncode({
        "content": content,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }
  }

  // ─────────────────────────────────────────────
  // 💬 댓글 조회
  // ─────────────────────────────────────────────
  static Future<List<dynamic>> fetchComments(int postId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/community/posts/$postId/comments"),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("댓글 조회 실패");
    }
  }

  // ─────────────────────────────────────────────
  // ❤️ 좋아요 토글 (user_id 제거)
  // ─────────────────────────────────────────────
  static Future<bool> toggleLike(int postId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/community/posts/$postId/like"),
      headers: _authHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["liked"];
    } else {
      throw Exception(response.body);
    }
  }

  // ─────────────────────────────────────────────
  // ❤️ 좋아요 개수
  // ─────────────────────────────────────────────
  static Future<int> getLikeCount(int postId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/community/posts/$postId/like-count"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["count"];
    } else {
      throw Exception("좋아요 개수 조회 실패");
    }
  }

  // ─────────────────────────────────────────────
  // ❤️ 좋아요 상태 (JWT 기반 자동 처리)
  // ─────────────────────────────────────────────
  static Future<bool> getLikeStatus(int postId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/community/posts/$postId/like-status"),
      headers: _authHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["liked"];
    } else {
      throw Exception(response.body);
    }
  }

  // ─────────────────────────────────────────────
  // 💬 댓글 삭제
  // ─────────────────────────────────────────────
  static Future<void> deleteComment(int commentId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/community/comments/$commentId"),
      headers: _authHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception("댓글 삭제 실패");
    }
  }

  // ─────────────────────────────────────────────
  // 💬 댓글 수정
  // ─────────────────────────────────────────────
  static Future<void> updateComment(int commentId, String content) async {
    final response = await http.put(
      Uri.parse('$baseUrl/community/comments/$commentId'),
      headers: _authHeaders(),
      body: jsonEncode({"content": content}),
    );

    if (response.statusCode != 200) {
      throw Exception("댓글 수정 실패");
    }
  }

  // 🔹 내 정보 조회 (마이페이지용)
  static Future<Map<String, dynamic>> fetchMyProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/me'), // 🔥 여기 수정
      headers: _authHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print(response.body); // 🔥 디버깅용
      throw Exception('프로필 불러오기 실패');
    }
  }

// 랭킹 함수 추가
  static Future<List<dynamic>> fetchRanking() async {
    final response = await http.get(
      Uri.parse('$baseUrl/ranking'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('랭킹 불러오기 실패');
    }
  }
}
