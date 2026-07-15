import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api.dart';
import '../config/auth_store.dart';
import '../models/final_touch.dart';
import '../models/final_touch_report.dart';
import '../screens/teacher/teacher_problem_set_preview_screen.dart';
import 'teacher_final_touch_import_screen.dart';
import '../utils/final_touch_pdf_generator.dart';
import '../widgets/final_touch_core_analysis.dart';
import '../widgets/final_touch_sentence_analysis.dart';

class TextAnalysisHubScreen extends StatefulWidget {
  const TextAnalysisHubScreen({super.key});

  @override
  State<TextAnalysisHubScreen> createState() => _TextAnalysisHubScreenState();
}

class _TextAnalysisHubScreenState extends State<TextAnalysisHubScreen> {
  static const _brandBlue = Color(0xFF2563EB);
  static const _ink = Color(0xFF172033);
  static const _line = Color(0xFFE2E8F0);
  static const _surface = Color(0xFFF4F7FB);

  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _textbookFolderController =
      TextEditingController();
  final TextEditingController _unitFolderController = TextEditingController();
  final TextEditingController _passageController = TextEditingController();
  final TextEditingController _koreanTranslationController =
      TextEditingController();
  final TextEditingController _teacherTopicController = TextEditingController();

  Map<String, dynamic>? _result;
  bool _loading = false;
  bool _makingQuestions = false;
  bool _savingFinalTouch = false;
  int? _passageId;

  @override
  void dispose() {
    _sourceController.dispose();
    _textbookFolderController.dispose();
    _unitFolderController.dispose();
    _passageController.dispose();
    _koreanTranslationController.dispose();
    _teacherTopicController.dispose();
    super.dispose();
  }

  Future<void> _openHwpxImport() async {
    final textbookFolder = _textbookFolderController.text.trim();
    final unitFolder = _unitFolderController.text.trim();
    final destinationLabel = unitFolder.isNotEmpty
        ? unitFolder
        : textbookFolder.isNotEmpty
            ? textbookFolder
            : null;

    final savedCount = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherFinalTouchImportScreen(
          folderName: destinationLabel,
          textbookFolderName: textbookFolder.isEmpty ? null : textbookFolder,
          unitFolderName: unitFolder.isEmpty ? null : unitFolder,
        ),
      ),
    );

    if (!mounted || savedCount == null || savedCount <= 0) return;
    final label = destinationLabel?.trim().isNotEmpty == true
        ? destinationLabel!.trim()
        : '미분류';
    _showSnackBar('$label에 Final Touch $savedCount개를 저장했습니다.');
  }

  Widget _buildAnalysisInputHeader() {
    final importButton = OutlinedButton.icon(
      onPressed: _loading ? null : _openHwpxImport,
      icon: const Icon(Icons.upload_file_rounded, size: 20),
      label: const Text('HWPX 가져오기'),
      style: OutlinedButton.styleFrom(
        foregroundColor: _brandBlue,
        side: const BorderSide(color: Color(0xFFBFDBFE)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 560;
        const title = _SectionTitle(
          title: '분석 입력',
          subtitle: '학원 자료 관리에 필요한 출처를 함께 남겨두세요.',
        );
        final helper = Text(
          'HWPX 파일을 불러와 Final Touch 자료를 자동 생성합니다.',
          style: TextStyle(
            color: Colors.blueGrey.shade600,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        );

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: importButton),
              const SizedBox(height: 8),
              helper,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(child: title),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                importButton,
                const SizedBox(height: 8),
                SizedBox(width: 280, child: helper),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> analyze() async {
    final passageText = _passageController.text.trim();

    if (passageText.isEmpty) {
      _showSnackBar('지문을 입력해 주세요.');
      return;
    }

    setState(() {
      _loading = true;
      _result = null;
      _passageId = null;
    });

    try {
      final url = ApiConfig.u("/analyze/summary_flow");
      final headers = {
        "Content-Type": "application/json",
        if (AuthStore.accessToken != null)
          "Authorization": "Bearer ${AuthStore.accessToken}",
      };

      final res = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          "passage": passageText,
          "source": _sourceController.text.trim(),
          "textbook_folder_name": _textbookFolderController.text.trim(),
          "unit_folder_name": _unitFolderController.text.trim(),
          "korean_translation_text": _koreanTranslationController.text.trim(),
          "teacher_topic_sentence": _teacherTopicController.text.trim(),
          "force_analyze": true,
        }),
      );

      if (res.statusCode != 200) {
        throw Exception("분석 실패: ${res.statusCode} / ${res.body}");
      }

      final raw = jsonDecode(res.body);
      final parsed =
          Map<String, dynamic>.from(raw["result"] ?? raw["data"] ?? raw);
      _bindTeacherInputsToAnalysisResult(parsed);
      final dynamic passageIdValue = parsed["passage_id"];

      if (!mounted) return;
      setState(() {
        _result = parsed;
        if (passageIdValue is int) {
          _passageId = passageIdValue;
        } else if (passageIdValue is String) {
          _passageId = int.tryParse(passageIdValue);
        }
      });

      if (_passageId == null) {
        _showSnackBar('분석은 완료됐지만 passage_id가 없습니다.');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("분석 실패: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _bindTeacherInputsToAnalysisResult(Map<String, dynamic> result) {
    final providedTranslation = _koreanTranslationController.text.trim();
    if (providedTranslation.isNotEmpty) {
      result['korean_translation_text'] = providedTranslation;
      result['translation_bracketed'] = providedTranslation;
      result['translation_ko'] = providedTranslation;
      _clearTranslationLeakCoreValues(result, providedTranslation);
      _fillSentenceTranslations(
          result['sentence_details'], providedTranslation);
    }

    final teacherTopic = _teacherTopicController.text.trim();
    if (teacherTopic.isNotEmpty) {
      result['teacher_topic_sentence'] = teacherTopic;
      if (_looksEnglish(teacherTopic) &&
          (result['topic_en']?.toString().trim() ?? '').isEmpty) {
        result['topic_en'] = teacherTopic;
      }
      if (_looksEnglish(teacherTopic) &&
          (result['gist_en']?.toString().trim() ?? '').isEmpty) {
        result['gist_en'] = teacherTopic;
      }
    }
  }

  void _clearTranslationLeakCoreValues(
    Map<String, dynamic> result,
    String translationText,
  ) {
    final firstLine = translationText
        .split(RegExp(r'\n\s*\n|\r?\n'))
        .map((line) => line.trim())
        .firstWhere((line) => line.isNotEmpty, orElse: () => '');
    if (firstLine.isEmpty) return;
    for (final key in const [
      'topic_ko',
      'title_ko',
      'gist_ko',
      'summary_ko',
    ]) {
      final value = result[key]?.toString().trim() ?? '';
      if (value == firstLine || value.startsWith('$firstLine ')) {
        result[key] = '';
      }
    }
  }

  bool _looksEnglish(String text) {
    final hasEnglish = RegExp(r'[A-Za-z]').hasMatch(text);
    final hasKorean = RegExp(r'[가-힣]').hasMatch(text);
    return hasEnglish && !hasKorean;
  }

  void _fillSentenceTranslations(dynamic rawDetails, String translationText) {
    if (rawDetails is! List) return;
    final translations = translationText
        .split(RegExp(r'\n\s*\n|\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (translations.isEmpty) return;

    for (var i = 0; i < rawDetails.length; i++) {
      final item = rawDetails[i];
      if (item is! Map) continue;
      final current = (item['translation'] ?? item['translation_bracketed'])
          ?.toString()
          .trim();
      if (current != null && current.isNotEmpty) continue;
      final fallback = translations[i < translations.length ? i : 0];
      item['translation'] = fallback;
      item['translation_bracketed'] = fallback;
    }
  }

  Future<void> makeQuestions() async {
    final source = _sourceController.text.trim();
    final passageText = _passageController.text.trim();

    if (passageText.isEmpty) {
      _showSnackBar('지문을 입력해 주세요.');
      return;
    }

    if (source.isEmpty) {
      _showSnackBar('출처를 입력해 주세요. 예: 2025년 고2 3월 모의고사 23번');
      return;
    }

    if (_passageId == null) {
      _showSnackBar('먼저 분석하기를 눌러 passage_id를 생성해 주세요.');
      return;
    }

    final String problemSetName = _buildProblemSetName(source);
    setState(() => _makingQuestions = true);

    try {
      final url = ApiConfig.u("/teacher/problem_sets/generate_and_save");
      final analysisPayload = _buildProblemSetAnalysisPayload(
        source: source,
        passage: passageText,
      );
      final body = {
        "passage_id": _passageId,
        "name": problemSetName,
        "types": [
          "topic",
          "title",
          "gist",
          "summary",
          "cloze",
          "insertion",
          "order",
          "grammar",
          "vocabulary",
          "mismatch",
          "content",
        ],
        "mode": "teacher",
        "created_by": AuthStore.nickname ?? "teacher1",
        "folder_id": _result?["folder_id"],
        "folder_name": _unitFolderController.text.trim().isNotEmpty
            ? _unitFolderController.text.trim()
            : _textbookFolderController.text.trim(),
        "analysis": analysisPayload,
      };

      final res = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          if (AuthStore.accessToken != null)
            "Authorization": "Bearer ${AuthStore.accessToken}",
        },
        body: jsonEncode(body),
      );

      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception("문제 생성 실패: ${res.statusCode} / ${res.body}");
      }

      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      final problemSetId = _extractProblemSetId(decoded);
      if (problemSetId == null) {
        throw Exception("문제세트 ID를 응답에서 찾지 못했습니다: $decoded");
      }

      if (!mounted) return;
      _showSnackBar("10문제 세트가 저장되었습니다.");
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TeacherProblemSetPreviewScreen(
            problemSetId: problemSetId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("문제 생성 실패: $e");
    } finally {
      if (mounted) setState(() => _makingQuestions = false);
    }
  }

  Future<void> saveFinalTouch() async {
    final result = _result;
    if (result == null) return;

    final existingId = result['analysis_record_id'] ?? result['final_touch_id'];
    if (existingId != null && existingId.toString().trim().isNotEmpty) {
      _showSnackBar('Final Touch에 이미 저장되어 있습니다.');
      return;
    }

    final passage = _passageController.text.trim();
    if (passage.isEmpty) {
      _showSnackBar('지문을 입력해 주세요.');
      return;
    }

    setState(() => _savingFinalTouch = true);
    try {
      final uri = ApiConfig.u('/analysis-records');
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (AuthStore.accessToken != null)
            'Authorization': 'Bearer ${AuthStore.accessToken}',
        },
        body: jsonEncode({
          'source': _sourceController.text.trim(),
          'passage': passage,
          'passage_bracketed': result['passage_bracketed'] ?? '',
          'topic_en': result['topic_en'] ?? '',
          'topic_ko': result['topic_ko'] ?? '',
          'title_en': result['title_en'] ?? '',
          'title_ko': result['title_ko'] ?? '',
          'gist_en': result['gist_en'] ?? '',
          'gist_ko': result['gist_ko'] ?? '',
          'summary_en': result['summary_en'] ?? '',
          'summary_ko': result['summary_ko'] ?? '',
          'translation_bracketed': result['translation_bracketed'] ??
              _koreanTranslationController.text.trim(),
          'outline': result['outline'] ?? const {},
          'sentence_details': result['sentence_details'] ?? const [],
          'textbook_folder_name': _textbookFolderController.text.trim(),
          'unit_folder_name': _unitFolderController.text.trim(),
        }),
      );
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('${res.statusCode} / ${res.body}');
      }

      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      final record = decoded is Map<String, dynamic>
          ? decoded['analysis_record'] as Map<String, dynamic>?
          : null;
      final savedId = record?['id'] ?? decoded['id'];
      setState(() {
        _result = {
          ...result,
          if (savedId != null) 'analysis_record_id': savedId,
        };
      });

      final folderLabel = _unitFolderController.text.trim().isNotEmpty
          ? _unitFolderController.text.trim()
          : _textbookFolderController.text.trim();
      _showSnackBar(
        folderLabel.isEmpty
            ? 'Final Touch에 저장되었습니다.'
            : '$folderLabel에 Final Touch가 저장되었습니다.',
      );
    } catch (e) {
      _showSnackBar('Final Touch 저장 실패: $e');
    } finally {
      if (mounted) setState(() => _savingFinalTouch = false);
    }
  }

  String _buildProblemSetName(String source) {
    final unit = _unitFolderController.text.trim();
    final textbook = _textbookFolderController.text.trim();
    final base = [
      if (textbook.isNotEmpty) textbook,
      if (unit.isNotEmpty) unit,
      source,
    ].where((part) => part.trim().isNotEmpty).join(' ');

    if (base.trim().isEmpty) return 'Final Touch 10문제';
    return '$base - Final Touch 10문제';
  }

  Map<String, dynamic> _buildProblemSetAnalysisPayload({
    required String source,
    required String passage,
  }) {
    final result = _result ?? const <String, dynamic>{};
    final sentenceDetails = _asMapList(result['sentence_details']);
    final grammarPoints = <Map<String, dynamic>>[];
    final questionPoints = <Map<String, dynamic>>[];

    for (final sentence in sentenceDetails) {
      final sentenceNo = sentence['sentence_no'];
      for (final point in _asMapList(sentence['grammar_points'])) {
        grammarPoints.add({
          "sentence_no": sentenceNo,
          "target": point["target"],
          "label": point["label"],
          "explanation": point["explanation"],
          "reference_no": point["reference_no"],
        });
      }
      final questionPoint = sentence['question_point']?.toString().trim();
      if (questionPoint != null && questionPoint.isNotEmpty) {
        questionPoints.add({
          "sentence_no": sentenceNo,
          "sentence_role": sentence["sentence_role"],
          "role_highlight_type": sentence["role_highlight_type"],
          "is_blank_candidate": sentence["is_blank_candidate"],
          "question_point": questionPoint,
        });
      }
    }

    return {
      "passage_id": _passageId,
      "final_touch_id":
          result["final_touch_id"] ?? result["analysis_record_id"],
      "analysis_record_id": result["analysis_record_id"],
      "source": source,
      "textbook_folder": _textbookFolderController.text.trim(),
      "unit_folder": _unitFolderController.text.trim(),
      "passage": passage,
      "passage_bracketed": result["passage_bracketed"] ?? "",
      "korean_translation_text": _koreanTranslationController.text.trim(),
      "translation_bracketed": result["translation_bracketed"] ??
          _koreanTranslationController.text.trim(),
      "teacher_topic_sentence": _teacherTopicController.text.trim(),
      "outline": result["outline"] ?? const {},
      "topic_en": result["topic_en"] ?? "",
      "topic_ko": result["topic_ko"] ?? "",
      "title_en": result["title_en"] ?? "",
      "title_ko": result["title_ko"] ?? "",
      "gist_en": result["gist_en"] ?? "",
      "gist_ko": result["gist_ko"] ?? "",
      "summary_en": result["summary_en"] ?? "",
      "summary_ko": result["summary_ko"] ?? "",
      "sentence_details": sentenceDetails,
      "grammar_points": grammarPoints,
      "question_points": questionPoints,
      "generation_guidance": {
        "use_final_touch_analysis": true,
        "use_sentence_question_points": true,
        "use_grammar_points_when_appropriate": true,
        "use_blank_candidate_sentences": true,
        "answer_storage": "questions.answer_index",
      },
    };
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  int? _extractProblemSetId(dynamic decoded) {
    if (decoded is Map) {
      final id = decoded['id'] ?? decoded['problem_set_id'];
      if (id is int) return id;
      if (id is num) return id.toInt();
      if (id is String) return int.tryParse(id);
    }
    return null;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final outline = _result?['outline'];
    String intro = "";
    String body = "";
    String conclusion = "";

    if (outline is Map) {
      intro = outline['intro']?.toString() ?? '';
      body = outline['body']?.toString() ?? '';
      conclusion = outline['conclusion']?.toString() ?? '';
    }

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: const Text(
          "지문 분석",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1320),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _HeaderCard(
                  icon: Icons.article_outlined,
                  title: '지문 분석 허브',
                  subtitle: '출처와 지문을 입력하면 구조, 주제, 제목, 요지를 한 번에 정리합니다.',
                ),
                const SizedBox(height: 16),
                _AdminCard(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAnalysisInputHeader(),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _sourceController,
                          decoration: _inputDecoration(
                            label: "출처",
                            hint: "예: 2025년 고2 3월 모의고사 23번",
                          ),
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final stacked = constraints.maxWidth < 640;
                            final textbookField = TextField(
                              controller: _textbookFolderController,
                              decoration: _inputDecoration(
                                label: "교재 폴더",
                                hint: "예: 수특라이트 영독",
                              ),
                            );
                            final unitField = TextField(
                              controller: _unitFolderController,
                              decoration: _inputDecoration(
                                label: "단원/강 폴더",
                                hint: "예: 13강",
                              ),
                            );

                            if (stacked) {
                              return Column(
                                children: [
                                  textbookField,
                                  const SizedBox(height: 12),
                                  unitField,
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: textbookField),
                                const SizedBox(width: 12),
                                Expanded(child: unitField),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passageController,
                          minLines: 8,
                          maxLines: 14,
                          keyboardType: TextInputType.multiline,
                          decoration: _inputDecoration(
                            label: "지문",
                            hint: "분석할 영어 지문을 붙여넣으세요.",
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _OptionalAnalysisInputs(
                          koreanTranslationController:
                              _koreanTranslationController,
                          teacherTopicController: _teacherTopicController,
                          inputDecoration: _inputDecoration,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: FilledButton.icon(
                            onPressed: _loading ? null : analyze,
                            icon: _loading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.analytics_outlined),
                            label: Text(_loading ? "분석 중..." : "분석하기"),
                            style: FilledButton.styleFrom(
                              backgroundColor: _brandBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_result == null)
                  const _EmptyStateCard()
                else
                  _ResultCard(
                    passageId: _passageId,
                    source: _sourceController.text.trim(),
                    textbookFolder: _textbookFolderController.text.trim(),
                    unitFolder: _unitFolderController.text.trim(),
                    passage: _passageController.text.trim(),
                    intro: intro,
                    body: body,
                    conclusion: conclusion,
                    result: _result!,
                    savingFinalTouch: _savingFinalTouch,
                    onSaveFinalTouch: saveFinalTouch,
                    makingQuestions: _makingQuestions,
                    onMakeQuestions: makeQuestions,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _brandBlue, width: 1.5),
      ),
    );
  }
}

class _OptionalAnalysisInputs extends StatelessWidget {
  const _OptionalAnalysisInputs({
    required this.koreanTranslationController,
    required this.teacherTopicController,
    required this.inputDecoration,
  });

  final TextEditingController koreanTranslationController;
  final TextEditingController teacherTopicController;
  final InputDecoration Function({
    required String label,
    required String hint,
    bool alignLabelWithHint,
  }) inputDecoration;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC4B5FD), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x147C3AED),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: const Color(0xFF6D28D9),
        collapsedIconColor: const Color(0xFF64748B),
        title: const Row(
          children: [
            Icon(
              Icons.tips_and_updates_outlined,
              color: Color(0xFF6D28D9),
              size: 20,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '분석 정확도 높이기 선택 입력',
                style: TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        subtitle: const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '한글 해석 · 주제문을 직접 넣으면 결과가 더 정확해집니다.',
                style: TextStyle(
                  color: Color(0xFF5B21B6),
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _OptionalInputChip(
                    label: '한글 해석 선택',
                    backgroundColor: Color(0xFFECFDF5),
                    borderColor: Color(0xFF99F6E4),
                    textColor: Color(0xFF0F766E),
                  ),
                  _OptionalInputChip(
                    label: '주제문 직접 입력',
                    backgroundColor: Color(0xFFEEF2FF),
                    borderColor: Color(0xFFC7D2FE),
                    textColor: Color(0xFF4338CA),
                  ),
                ],
              ),
            ],
          ),
        ),
        children: [
          const _OptionalGuideBox(),
          const SizedBox(height: 12),
          const _OptionalInputHelp(
            title: '한글 해석 선택 입력',
            message:
                '교재나 자료에 있는 한글 해석을 붙여넣으면 문장별 해석에 우선 반영합니다. 비워두면 GPT가 자동으로 해석을 생성합니다.',
          ),
          const SizedBox(height: 8),
          TextField(
            controller: koreanTranslationController,
            minLines: 4,
            maxLines: 8,
            keyboardType: TextInputType.multiline,
            decoration: inputDecoration(
              label: '한글 해석 선택 입력',
              hint: '예) 연구 결과는 우리가 특정 아이디어의 중요성과 타당성을 더 잘 이해하도록 도와준다...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          const _OptionalInputHelp(
            title: '주제문 직접 입력 선택',
            message:
                '선생님이 생각하는 주제문이 있다면 입력하세요. 입력한 문장은 주제문 후보와 핵심 분석에 우선 반영됩니다.',
          ),
          const SizedBox(height: 8),
          TextField(
            controller: teacherTopicController,
            minLines: 1,
            maxLines: 3,
            keyboardType: TextInputType.multiline,
            decoration: inputDecoration(
              label: '주제문 직접 입력 선택',
              hint: '예) Research findings can inject life into an idea...',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionalInputChip extends StatelessWidget {
  const _OptionalInputChip({
    required this.label,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _OptionalGuideBox extends StatelessWidget {
  const _OptionalGuideBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF99F6E4)),
      ),
      child: const Text(
        '선택 입력은 필수가 아닙니다.\n'
        '한글 해석이나 주제문을 넣으면 분석 정확도가 올라가고 API 사용량을 줄일 수 있습니다.',
        style: TextStyle(
          color: Color(0xFF0F766E),
          fontSize: 13,
          height: 1.45,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _OptionalInputHelp extends StatelessWidget {
  const _OptionalInputHelp({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.only(top: 7),
          decoration: const BoxDecoration(
            color: Color(0xFF0F766E),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.passageId,
    required this.source,
    required this.textbookFolder,
    required this.unitFolder,
    required this.passage,
    required this.intro,
    required this.body,
    required this.conclusion,
    required this.result,
    required this.savingFinalTouch,
    required this.onSaveFinalTouch,
    required this.makingQuestions,
    required this.onMakeQuestions,
  });

  final int? passageId;
  final String source;
  final String textbookFolder;
  final String unitFolder;
  final String passage;
  final String intro;
  final String body;
  final String conclusion;
  final Map<String, dynamic> result;
  final bool savingFinalTouch;
  final VoidCallback onSaveFinalTouch;
  final bool makingQuestions;
  final VoidCallback onMakeQuestions;

  @override
  Widget build(BuildContext context) {
    final sentenceDetails = FinalTouchSentenceDetail.listFromJson(
      result['sentence_details'],
    );
    final report = FinalTouchReport.fromAnalysisResult(
      passageId: passageId,
      source: source,
      textbookFolder: textbookFolder,
      unitFolder: unitFolder,
      passage: passage,
      result: result,
    );
    final savedRecordId =
        result['analysis_record_id'] ?? result['final_touch_id'];
    final isSaved =
        savedRecordId != null && savedRecordId.toString().trim().isNotEmpty;

    return _AdminCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: _SectionTitle(
                    title: '분석 결과',
                    subtitle: '수업 자료로 바로 전환할 수 있도록 요약했습니다.',
                  ),
                ),
                if (passageId != null) _Badge(label: 'Passage ID $passageId'),
              ],
            ),
            const SizedBox(height: 16),
            _ResultMetadata(
              source: source,
              textbookFolder: textbookFolder,
              unitFolder: unitFolder,
            ),
            const SizedBox(height: 14),
            _FlowAnalysisCard(
              intro: intro,
              body: body,
              conclusion: conclusion,
            ),
            const SizedBox(height: 18),
            FinalTouchCoreAnalysis(
              topicEn: result['topic_en']?.toString() ?? '',
              topicKo: result['topic_ko']?.toString() ?? '',
              titleEn: result['title_en']?.toString() ?? '',
              titleKo: result['title_ko']?.toString() ?? '',
              gistEn: result['gist_en']?.toString() ?? '',
              gistKo: result['gist_ko']?.toString() ?? '',
              topicFallback:
                  _preferredResultText(result['topic_en'], result['topic_ko']),
              titleFallback:
                  _preferredResultText(result['title_en'], result['title_ko']),
              gistFallback:
                  _preferredResultText(result['gist_en'], result['gist_ko']),
              summaryEn: result['summary_en']?.toString() ?? '',
              summaryKo: result['summary_ko']?.toString() ?? '',
            ),
            const SizedBox(height: 8),
            FinalTouchSentenceAnalysis(
              details: sentenceDetails,
              translation: result['translation_bracketed']?.toString() ?? '',
            ),
            if (sentenceDetails.isNotEmpty) const SizedBox(height: 12),
            FinalTouchFullBracketedPassage(
              body:
                  (result['passage_bracketed']?.toString().trim().isNotEmpty ??
                          false)
                      ? result['passage_bracketed'].toString()
                      : passage,
              plainBody: passage,
              sentenceDetails: sentenceDetails,
              topic:
                  _preferredResultText(result['topic_en'], result['topic_ko']),
              title:
                  _preferredResultText(result['title_en'], result['title_ko']),
              gist: _preferredResultText(result['gist_en'], result['gist_ko']),
              summary: _preferredResultText(
                  result['summary_en'], result['summary_ko']),
              translation: result['translation_bracketed']?.toString() ?? '',
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.icon(
                onPressed:
                    isSaved || savingFinalTouch ? null : onSaveFinalTouch,
                icon: savingFinalTouch
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(isSaved
                        ? Icons.check_circle_outline_rounded
                        : Icons.save_alt_rounded),
                label: Text(
                  savingFinalTouch
                      ? 'Final Touch 저장 중...'
                      : isSaved
                          ? 'Final Touch에 자동 저장됨'
                          : 'Final Touch로 저장',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      isSaved ? const Color(0xFF16A34A) : _TeacherColors.blue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: isSaved
                      ? const Color(0xFFD1FAE5)
                      : const Color(0xFFE2E8F0),
                  disabledForegroundColor: isSaved
                      ? const Color(0xFF166534)
                      : const Color(0xFF64748B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.icon(
                onPressed: () => _printPdf(context, report),
                icon: const Icon(Icons.print_outlined),
                label: const Text('PDF 출력'),
                style: FilledButton.styleFrom(
                  backgroundColor: _TeacherColors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: makingQuestions ? null : onMakeQuestions,
                icon: makingQuestions
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.library_add_outlined),
                label: Text(makingQuestions ? '문제 생성 중...' : '10문제 만들기'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _TeacherColors.blue,
                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _printPdf(BuildContext context, FinalTouchReport report) async {
    try {
      await FinalTouchPdfGenerator.previewOrPrint(report);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF 생성 중 오류가 발생했습니다.')),
      );
    }
  }
}

String _preferredResultText(dynamic primary, dynamic fallback) {
  final primaryText = primary?.toString().trim() ?? '';
  if (primaryText.isNotEmpty) return primaryText;
  return fallback?.toString().trim() ?? '';
}

class _ResultMetadata extends StatelessWidget {
  const _ResultMetadata({
    required this.source,
    required this.textbookFolder,
    required this.unitFolder,
  });

  final String source;
  final String textbookFolder;
  final String unitFolder;

  @override
  Widget build(BuildContext context) {
    final items = [
      if (source.isNotEmpty) ('출처', source),
      if (textbookFolder.isNotEmpty) ('교재', textbookFolder),
      if (unitFolder.isNotEmpty) ('단원', unitFolder),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _TeacherColors.line),
            ),
            child: Text(
              '${item.$1} · ${item.$2}',
              style: const TextStyle(
                color: _TeacherColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _AnalysisSectionLabel extends StatelessWidget {
  const _AnalysisSectionLabel({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _TeacherColors.ink,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: _TeacherColors.muted,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _FlowAnalysisCard extends StatelessWidget {
  const _FlowAnalysisCard({
    required this.intro,
    required this.body,
    required this.conclusion,
  });

  final String intro;
  final String body;
  final String conclusion;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AnalysisSectionLabel(
            title: '글의 흐름',
            subtitle: '지문의 전개를 서론, 본론, 결론 순서로 읽어 보세요.',
          ),
          const SizedBox(height: 14),
          _FlowLine(index: 1, label: '서론', value: intro),
          const _FlowDivider(),
          _FlowLine(index: 2, label: '본론', value: body),
          const _FlowDivider(),
          _FlowLine(index: 3, label: '결론', value: conclusion),
        ],
      ),
    );
  }
}

class _FlowLine extends StatelessWidget {
  const _FlowLine({
    required this.index,
    required this.label,
    required this.value,
  });

  final int index;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: _TeacherColors.blue,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$index',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _TeacherColors.blue,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.isEmpty ? '-' : value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _TeacherColors.ink,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FlowDivider extends StatelessWidget {
  const _FlowDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 11),
      child: SizedBox(
        height: 18,
        child: VerticalDivider(
          color: Color(0xFF93C5FD),
          thickness: 1,
          width: 1,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _TeacherColors.blue,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard();

  @override
  Widget build(BuildContext context) {
    return _AdminCard(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        child: const Column(
          children: [
            Icon(
              Icons.insights_outlined,
              color: _TeacherColors.blue,
              size: 34,
            ),
            SizedBox(height: 10),
            Text(
              '아직 분석 결과가 없습니다.',
              style: TextStyle(
                color: _TeacherColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '지문을 입력한 뒤 분석하기를 눌러 주세요.',
              style: TextStyle(color: _TeacherColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return _AdminCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: _TeacherColors.blue),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _TeacherColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _TeacherColors.muted,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _TeacherColors.ink,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: _TeacherColors.muted,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _AdminCard extends StatelessWidget {
  const _AdminCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _TeacherColors.line),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            offset: const Offset(0, 10),
            blurRadius: 24,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TeacherColors {
  static const blue = Color(0xFF2563EB);
  static const ink = Color(0xFF172033);
  static const muted = Color(0xFF64748B);
  static const line = Color(0xFFE2E8F0);
}
