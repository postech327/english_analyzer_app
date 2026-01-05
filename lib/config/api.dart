// lib/config/api.dart

class ApiConfig {
  /// 서버 기본 URL
  static const String baseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://127.0.0.1:8000',
  );

  /// 내부 유틸: path => Uri
  static Uri u(String path) => Uri.parse('$baseUrl$path');

  /// 🔥 통합 지문 분석 허브
  static const String textAnalysisHub = '/text_analysis_hub';

  /// 🔥 분석 기록 저장 (FastAPI /analyses)
  static const String analyses = '/analyses';

  // ─────────────────────────────
  // ① 인증 관련
  // ─────────────────────────────
  static const String authRegister = '/auth/register';
  static const String login = '/auth/login';

  // ─────────────────────────────
  // ② 분석기 관련
  // ─────────────────────────────
  static const String analyzeParagraph = '/paragraph/analyze';
  static const String analyzeStructure = '/analyze_structure';
  static const String analyzeTopicTitleSummary = '/analyze_topic_title_summary';
  static const String wordSynonyms = '/word_synonyms';
  static const String chat = '/chat';

  // ─────────────────────────────
  // ③ 단어 MCQ 관련
  // ─────────────────────────────
  static const String wordMcq = '/word_mcq';
  static const String wordMcqStruct = '/word_mcq_struct';

  // ─────────────────────────────
  // ④ 대시보드
  // ─────────────────────────────
  static const String dashboard = '/dashboard';

  // ─────────────────────────────
  // ⑤ Question Maker (타입별 엔드포인트)
  // ─────────────────────────────
  /// 예: /question_maker/topic, /question_maker/title ...
  static String qm(String type) => '/question_maker/$type';

  // ─────────────────────────────
  // ⑥ (신규) 지문 분석 허브 + 문제 세트
  // ─────────────────────────────
  static const String passageAnalyzeAndSave =
      '/teacher/passage/analyze_and_save';

  static const String problemSetGenerateAndSave =
      '/teacher/problem_sets/generate_and_save';
}
