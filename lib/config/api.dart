// lib/config/api.dart

class ApiConfig {
  /// 🔥 서버 기본 URL (지금은 8001로 고정)
  static const String baseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://127.0.0.1:8001',
  );

  /// 🔥 URL 생성 헬퍼
  static Uri u(String path) => Uri.parse('$baseUrl$path');

  // ─────────────────────────────
  // ① 인증
  // ─────────────────────────────
  static const String login = '/auth/login';
  static const String authRegister = '/auth/register';

  // ─────────────────────────────
  // ② 지문 분석 허브
  // ─────────────────────────────
  static const String textAnalysisHub = '/text_analysis_hub';
  static const String analyses = '/analyses';

  // ─────────────────────────────
  // ③ 분석 기능
  // ─────────────────────────────
  static const String analyzeParagraph = '/analyze_paragraph';
  static const String analyzeStructure = '/analyze_structure';
  static const String analyzeTopicTitleSummary = '/analyze_topic_title_summary';

  static const String passageAnalyzeAndSave =
      '/teacher/passage/analyze_and_save';

  // ─────────────────────────────
  // ④ 문제 생성 (🔥 핵심)
  // ─────────────────────────────

  /// 기본 문제 생성 (지금 사용 중)
  static const String generateBasic = '/question_maker/generate_basic';

  /// 유형별 생성 (추후 확장용)
  static String qm(String type) => '/question_maker/$type';

  // ─────────────────────────────
  // ⑤ 단어 기능
  // ─────────────────────────────
  static const String wordSynonyms = '/word_synonyms';
  static const String wordMcq = '/word_mcq';
  static const String wordMcqStruct = '/word_mcq_struct';

  // ─────────────────────────────
  // ⑥ 기타
  // ─────────────────────────────
  static const String dashboard = '/dashboard';
  static const String chat = '/chat';

  // ─────────────────────────────
  // ⑦ 교사용
  // ─────────────────────────────
  static const String problemSetGenerateAndSave =
      '/teacher/problem_sets/generate_and_save';
}
