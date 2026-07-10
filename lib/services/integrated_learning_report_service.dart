import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api.dart';
import '../config/auth_store.dart';
import '../models/final_touch.dart';
import '../models/integrated_learning_report.dart';
import '../models/learning_assignment.dart';
import '../models/vocabulary.dart';
import '../models/workbook.dart';
import '../models/workbook_attempt.dart';
import 'final_touch_service.dart';
import 'learning_assignment_service.dart';
import 'vocabulary_service.dart';
import 'workbook_attempt_service.dart';
import 'workbook_service.dart';

class IntegratedLearningReportService {
  const IntegratedLearningReportService({
    LearningAssignmentService assignmentService =
        const LearningAssignmentService(),
    WorkbookService workbookService = const WorkbookService(),
    WorkbookAttemptService workbookAttemptService =
        const WorkbookAttemptService(),
    VocabularyService vocabularyService = const VocabularyService(),
    FinalTouchService finalTouchService = const FinalTouchService(),
  })  : _assignmentService = assignmentService,
        _workbookService = workbookService,
        _workbookAttemptService = workbookAttemptService,
        _vocabularyService = vocabularyService,
        _finalTouchService = finalTouchService;

  final LearningAssignmentService _assignmentService;
  final WorkbookService _workbookService;
  final WorkbookAttemptService _workbookAttemptService;
  final VocabularyService _vocabularyService;
  final FinalTouchService _finalTouchService;

  Future<IntegratedLearningReport> fetchReport() async {
    try {
      return await _fetchBackendReport();
    } catch (_) {
      return _fetchFallbackReport(
        leadingWarning: '서버 집계 API를 사용할 수 없어 기존 자료 기준으로 계산했습니다.',
      );
    }
  }

  Future<IntegratedLearningReport> _fetchBackendReport() async {
    final response = await http.get(
      ApiConfig.u('/teacher/integrated-learning-report'),
      headers: {
        'Content-Type': 'application/json',
        if (AuthStore.accessToken != null)
          'Authorization': 'Bearer ${AuthStore.accessToken}',
      },
    ).timeout(const Duration(seconds: 20));
    final text = utf8.decode(response.bodyBytes);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Integrated report API failed: ${response.statusCode}');
    }
    final decoded = text.trim().isEmpty ? null : jsonDecode(text);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid integrated report response');
    }
    return parseIntegratedLearningReportResponse(decoded);
  }

  Future<IntegratedLearningReport> _fetchFallbackReport({
    String? leadingWarning,
  }) async {
    final warnings = <String>[];
    if (leadingWarning != null && leadingWarning.trim().isNotEmpty) {
      warnings.add(leadingWarning);
    }
    final students = await _safe(
      () => _assignmentService.fetchStudents(),
      warnings,
      '학생 목록을 불러오지 못했습니다.',
      fallback: const <AssignableStudent>[],
    );

    final accumulators = <int, _StudentReportAccumulator>{
      for (final student in students)
        student.id: _StudentReportAccumulator(
          studentId: student.id,
          studentName: student.nickname,
          email: student.email,
        ),
    };

    await _collectWorkbook(accumulators, warnings);
    await _collectVocabulary(accumulators, warnings);
    await _collectFinalTouch(accumulators, warnings);

    final reports = accumulators.values
        .map((accumulator) => accumulator.toReport())
        .toList()
      ..sort((a, b) {
        final aNeeds = a.needsReview ? 0 : 1;
        final bNeeds = b.needsReview ? 0 : 1;
        if (aNeeds != bNeeds) return aNeeds.compareTo(bNeeds);
        final dateCompare =
            _compareNullableDateDesc(a.lastStudyAt, b.lastStudyAt);
        if (dateCompare != 0) return dateCompare;
        return a.studentName.compareTo(b.studentName);
      });

    return IntegratedLearningReport(
      generatedAt: DateTime.now(),
      students: reports,
      warnings: warnings,
    );
  }

  Future<void> _collectWorkbook(
    Map<int, _StudentReportAccumulator> accumulators,
    List<String> warnings,
  ) async {
    final workbooks = await _safe(
      () => _workbookService.fetchWorkbooks(status: 'all'),
      warnings,
      'Workbook 목록을 불러오지 못했습니다.',
      fallback: const <Workbook>[],
    );
    final workbookTitles = {
      for (final workbook in workbooks) workbook.id: workbook.title
    };

    for (final workbook in workbooks) {
      final assignments = await _safe(
        () => _assignmentService.fetchTeacherWorkbookStatus(workbook.id),
        warnings,
        'Workbook "${workbook.title}" 배정 상태를 불러오지 못했습니다.',
        fallback: const <LearningAssignment>[],
      );
      for (final assignment in assignments) {
        final accumulator = accumulators.putIfAbsent(
          assignment.studentId,
          () => _StudentReportAccumulator(
            studentId: assignment.studentId,
            studentName:
                assignment.studentName ?? 'student${assignment.studentId}',
            email: '',
          ),
        );
        accumulator.workbook.totalCount += 1;
        accumulator.workbook.touchDate(_parseDate(assignment.startedAt) ??
            _parseDate(assignment.completedAt));
        if (assignment.isCompleted) {
          accumulator.workbook.completedCount += 1;
        } else {
          accumulator.workbook.incompleteTitles.add(
            assignment.title.isNotEmpty
                ? assignment.title
                : workbookTitles[assignment.contentId] ?? workbook.title,
          );
        }

        if (assignment.isCompleted || assignment.isInProgress) {
          final attemptReport = await _safe<TeacherWorkbookAttemptReport?>(
            () => _workbookAttemptService
                .fetchTeacherAssignmentReport(assignment.id),
            warnings,
            'Workbook "${assignment.title}" 시도 결과를 불러오지 못했습니다.',
            fallback: null,
          );
          final latestAttempt = attemptReport?.latestAttempt;
          if (latestAttempt != null) {
            accumulator.workbook.scores.add(latestAttempt.scorePercent);
            accumulator.workbook
                .touchDate(_parseDate(latestAttempt.submittedAt));
            for (final result
                in latestAttempt.results.where((item) => !item.isCorrect)) {
              if (result.questionType.trim().isNotEmpty) {
                accumulator.workbook.weakTypes.add(result.questionType.trim());
              }
            }
          }
        }
      }
    }
  }

  Future<void> _collectVocabulary(
    Map<int, _StudentReportAccumulator> accumulators,
    List<String> warnings,
  ) async {
    final sets = await _safe(
      () => _vocabularyService.fetchTeacherSets(status: 'all'),
      warnings,
      '단어장 목록을 불러오지 못했습니다.',
      fallback: const <VocabularySet>[],
    );

    for (final set in sets) {
      final assignments = await _safe(
        () => _vocabularyService.fetchAssignments(set.id),
        warnings,
        '단어장 "${set.title}" 배정 상태를 불러오지 못했습니다.',
        fallback: const <VocabularyAssignment>[],
      );
      for (final assignment in assignments) {
        final accumulator = accumulators.putIfAbsent(
          assignment.studentId,
          () => _StudentReportAccumulator(
            studentId: assignment.studentId,
            studentName: assignment.studentName,
            email: '',
          ),
        );
        accumulator.vocabulary.assignedBookCount += 1;
        accumulator.vocabulary.touchDate(_parseDate(assignment.assignedAt));
      }

      final results = await _safe(
        () => _vocabularyService.fetchTeacherResults(set.id),
        warnings,
        '단어장 "${set.title}" 결과를 불러오지 못했습니다.',
        fallback: const <VocabularyStudentResultSummary>[],
      );
      for (final result in results) {
        final accumulator = accumulators.putIfAbsent(
          result.studentId,
          () => _StudentReportAccumulator(
            studentId: result.studentId,
            studentName: result.studentName,
            email: '',
          ),
        );
        if (result.attemptCount > 0) {
          accumulator.vocabulary.completedBookCount += 1;
        }
        accumulator.vocabulary.studiedWordCount += result.latestTotalCount;
        accumulator.vocabulary.wrongWordCount += result.wrongCount;
        accumulator.vocabulary.touchDate(_parseDate(result.latestAttemptAt));
      }
    }
  }

  Future<void> _collectFinalTouch(
    Map<int, _StudentReportAccumulator> accumulators,
    List<String> warnings,
  ) async {
    final finalTouches = await _safe(
      () => _finalTouchService.fetchFinalTouches(limit: 200),
      warnings,
      'Final Touch 목록을 불러오지 못했습니다.',
      fallback: const <FinalTouchSummary>[],
    );
    final titleById = {
      for (final item in finalTouches) item.id: _finalTouchTitle(item),
    };
    final practiceResults = await _safe(
      _fetchTeacherFinalTouchPracticeResults,
      warnings,
      'Final Touch 문장 조립 결과를 불러오지 못했습니다.',
      fallback: const <_TeacherFinalTouchPracticeResult>[],
    );

    for (final item in finalTouches) {
      final assignments = await _safe(
        () => _assignmentService.fetchTeacherFinalTouchStatus(item.id),
        warnings,
        'Final Touch "${_finalTouchTitle(item)}" 배정 상태를 불러오지 못했습니다.',
        fallback: const <LearningAssignment>[],
      );
      for (final assignment in assignments) {
        final accumulator = accumulators.putIfAbsent(
          assignment.studentId,
          () => _StudentReportAccumulator(
            studentId: assignment.studentId,
            studentName:
                assignment.studentName ?? 'student${assignment.studentId}',
            email: '',
          ),
        );
        accumulator.finalTouch.totalCount += 1;
        final lastTouched = _parseDate(assignment.completedAt) ??
            _parseDate(assignment.startedAt);
        accumulator.finalTouch.touchDate(lastTouched);
        if (assignment.isCompleted || assignment.isInProgress) {
          accumulator.finalTouch.viewedCount += 1;
        } else {
          accumulator.finalTouch.notViewedTitles.add(
            assignment.title.isNotEmpty
                ? assignment.title
                : titleById[assignment.contentId] ?? _finalTouchTitle(item),
          );
        }
      }
    }

    for (final result in practiceResults) {
      final accumulator = accumulators.putIfAbsent(
        result.studentId,
        () => _StudentReportAccumulator(
          studentId: result.studentId,
          studentName: result.studentName,
          email: '',
        ),
      );
      accumulator.finalTouch.practiceFinalTouchIds.add(result.finalTouchId);
      accumulator.finalTouch.touchDate(result.createdAt);
    }
  }

  Future<List<_TeacherFinalTouchPracticeResult>>
      _fetchTeacherFinalTouchPracticeResults() async {
    final response = await http.get(
      ApiConfig.u('/teacher/final-touch-practice-results'),
      headers: {
        'Content-Type': 'application/json',
        if (AuthStore.accessToken != null)
          'Authorization': 'Bearer ${AuthStore.accessToken}',
      },
    ).timeout(const Duration(seconds: 20));
    final text = utf8.decode(response.bodyBytes);
    final decoded = text.trim().isEmpty ? null : jsonDecode(text);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}: $text');
    }
    final items = decoded is Map<String, dynamic> ? decoded['items'] : decoded;
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((item) => _TeacherFinalTouchPracticeResult.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  Future<T> _safe<T>(
    Future<T> Function() loader,
    List<String> warnings,
    String warning, {
    required T fallback,
  }) async {
    try {
      return await loader();
    } catch (error) {
      if (!warnings.contains(warning)) {
        warnings.add(warning);
      }
      return fallback;
    }
  }
}

IntegratedLearningReport parseIntegratedLearningReportResponse(
  Map<String, dynamic> json,
) {
  final rawStudents = json['students'];
  final warnings = <String>[
    for (final item in _asList(json['warnings']))
      if (_asString(item).isNotEmpty) _asString(item),
  ];
  final generatedAt =
      _parseDate(_asString(json['generated_at'])) ?? DateTime.now();
  return IntegratedLearningReport(
    generatedAt: generatedAt,
    students: _asList(rawStudents)
        .whereType<Map>()
        .map((item) => _parseBackendStudent(Map<String, dynamic>.from(item)))
        .toList(),
    warnings: warnings,
  );
}

StudentIntegratedLearningReport _parseBackendStudent(
  Map<String, dynamic> json,
) {
  final workbook = _asMap(json['workbook']);
  final vocabulary = _asMap(json['vocabulary']);
  final finalTouch = _asMap(json['final_touch']);
  return StudentIntegratedLearningReport(
    studentId: _asInt(json['student_id']),
    studentName: _asString(
      json['student_name'],
      fallback: 'student${_asInt(json['student_id'])}',
    ),
    email: _asString(json['email']),
    workbook: WorkbookReportSummary(
      totalCount: _asInt(workbook['total_count']),
      completedCount: _asInt(workbook['completed_count']),
      incompleteCount: _asInt(workbook['incomplete_count']),
      averageScore: _asDouble(workbook['average_score']),
      lastStudyAt: _parseDate(_asString(workbook['last_study_at'])),
      weakTypes: [
        for (final item in _asList(workbook['weak_types']))
          if (_asString(item).isNotEmpty) _asString(item),
      ],
    ),
    vocabulary: VocabularyReportSummary(
      assignedBookCount: _asInt(vocabulary['assigned_book_count']),
      completedBookCount: _asInt(vocabulary['completed_book_count']),
      studiedWordCount: _asInt(vocabulary['studied_word_count']),
      wrongWordCount: _asInt(vocabulary['wrong_word_count']),
      lastStudyAt: _parseDate(_asString(vocabulary['last_study_at'])),
    ),
    finalTouch: FinalTouchReportSummary(
      totalCount: _asInt(finalTouch['total_count']),
      viewedCount: _asInt(finalTouch['viewed_count']),
      notViewedCount: _asInt(finalTouch['not_viewed_count']),
      sentenceAssemblyCompletedCount:
          _asInt(finalTouch['sentence_assembly_completed_count']),
      lastViewedAt: _parseDate(_asString(finalTouch['last_viewed_at'])),
    ),
    recommendedActions: _parseBackendActions(json['recommended_actions']),
  );
}

List<RecommendedLearningAction> _parseBackendActions(dynamic value) {
  return [
    for (final item in _asList(value))
      if (item is Map)
        RecommendedLearningAction(
          area: _asString(item['area'], fallback: '통합'),
          title: _asString(item['title'], fallback: '추천 학습'),
          message: _asString(item['message']),
          priority: _parsePriority(_asString(item['priority'])),
        )
      else if (_asString(item).isNotEmpty)
        RecommendedLearningAction(
          area: '통합',
          title: '추천 학습',
          message: _asString(item),
        ),
  ];
}

ReportActionPriority _parsePriority(String value) {
  switch (value.trim().toLowerCase()) {
    case 'high':
      return ReportActionPriority.high;
    case 'low':
      return ReportActionPriority.low;
    default:
      return ReportActionPriority.medium;
  }
}

class _StudentReportAccumulator {
  _StudentReportAccumulator({
    required this.studentId,
    required this.studentName,
    required this.email,
  });

  final int studentId;
  final String studentName;
  final String email;
  final workbook = _WorkbookAccumulator();
  final vocabulary = _VocabularyAccumulator();
  final finalTouch = _FinalTouchAccumulator();

  StudentIntegratedLearningReport toReport() {
    final workbookSummary = workbook.toSummary();
    final vocabularySummary = vocabulary.toSummary();
    final finalTouchSummary = finalTouch.toSummary();
    final actions = _buildActions(
      workbook: workbookSummary,
      vocabulary: vocabularySummary,
      finalTouch: finalTouchSummary,
    );

    return StudentIntegratedLearningReport(
      studentId: studentId,
      studentName: studentName,
      email: email,
      workbook: workbookSummary,
      vocabulary: vocabularySummary,
      finalTouch: finalTouchSummary,
      recommendedActions: actions,
    );
  }
}

class _WorkbookAccumulator {
  int totalCount = 0;
  int completedCount = 0;
  final scores = <double>[];
  final weakTypes = <String>{};
  final incompleteTitles = <String>[];
  DateTime? lastStudyAt;

  void touchDate(DateTime? date) {
    lastStudyAt = latestDate([lastStudyAt, date]);
  }

  WorkbookReportSummary toSummary() {
    final average = scores.isEmpty
        ? 0.0
        : scores.reduce((value, element) => value + element) / scores.length;
    final incomplete = totalCount - completedCount;
    return WorkbookReportSummary(
      totalCount: totalCount,
      completedCount: completedCount,
      incompleteCount: incomplete < 0 ? 0 : incomplete,
      averageScore: average,
      lastStudyAt: lastStudyAt,
      weakTypes: weakTypes.toList()..sort(),
      incompleteTitles: incompleteTitles.take(3).toList(),
    );
  }
}

class _VocabularyAccumulator {
  int assignedBookCount = 0;
  int completedBookCount = 0;
  int studiedWordCount = 0;
  int wrongWordCount = 0;
  DateTime? lastStudyAt;

  void touchDate(DateTime? date) {
    lastStudyAt = latestDate([lastStudyAt, date]);
  }

  VocabularyReportSummary toSummary() {
    return VocabularyReportSummary(
      assignedBookCount: assignedBookCount,
      completedBookCount: completedBookCount,
      studiedWordCount: studiedWordCount,
      wrongWordCount: wrongWordCount,
      lastStudyAt: lastStudyAt,
    );
  }
}

class _FinalTouchAccumulator {
  int totalCount = 0;
  int viewedCount = 0;
  final practiceFinalTouchIds = <int>{};
  final notViewedTitles = <String>[];
  DateTime? lastViewedAt;

  void touchDate(DateTime? date) {
    lastViewedAt = latestDate([lastViewedAt, date]);
  }

  FinalTouchReportSummary toSummary() {
    final notViewed = totalCount - viewedCount;
    return FinalTouchReportSummary(
      totalCount: totalCount,
      viewedCount: viewedCount,
      notViewedCount: notViewed < 0 ? 0 : notViewed,
      sentenceAssemblyCompletedCount: practiceFinalTouchIds.length,
      lastViewedAt: lastViewedAt,
      notViewedTitles: notViewedTitles.take(3).toList(),
    );
  }
}

class _TeacherFinalTouchPracticeResult {
  const _TeacherFinalTouchPracticeResult({
    required this.studentId,
    required this.studentName,
    required this.finalTouchId,
    this.createdAt,
  });

  final int studentId;
  final String studentName;
  final int finalTouchId;
  final DateTime? createdAt;

  factory _TeacherFinalTouchPracticeResult.fromJson(Map<String, dynamic> json) {
    final studentId = _asInt(json['student_id']);
    return _TeacherFinalTouchPracticeResult(
      studentId: studentId,
      studentName: _asString(
        json['student_name'],
        fallback: 'student$studentId',
      ),
      finalTouchId: _asInt(json['final_touch_id']),
      createdAt: _parseDate(_asString(json['created_at'])),
    );
  }
}

List<RecommendedLearningAction> _buildActions({
  required WorkbookReportSummary workbook,
  required VocabularyReportSummary vocabulary,
  required FinalTouchReportSummary finalTouch,
}) {
  final actions = <RecommendedLearningAction>[];
  if (vocabulary.wrongWordCount > 0) {
    actions.add(
      RecommendedLearningAction(
        area: 'Vocabulary',
        title: '오답 단어 복습',
        message: '오답 단어 ${vocabulary.wrongWordCount}개를 다시 풀도록 안내해 보세요.',
        priority: ReportActionPriority.high,
      ),
    );
  }
  if (finalTouch.notViewedCount > 0) {
    actions.add(
      RecommendedLearningAction(
        area: 'Final Touch',
        title: '미열람 자료 복습',
        message:
            '아직 열람하지 않은 Final Touch ${finalTouch.notViewedCount}개를 확인하게 해 주세요.',
      ),
    );
  }
  if (workbook.incompleteCount > 0) {
    actions.add(
      RecommendedLearningAction(
        area: 'Workbook',
        title: '미완료 Workbook 마무리',
        message: '미완료 Workbook ${workbook.incompleteCount}개를 먼저 완료하도록 안내해 보세요.',
      ),
    );
  }
  if (latestDate([
        workbook.lastStudyAt,
        vocabulary.lastStudyAt,
        finalTouch.lastViewedAt,
      ]) ==
      null) {
    actions.add(
      const RecommendedLearningAction(
        area: '전체',
        title: '최근 학습 기록 없음',
        message: '최근 학습 기록이 없습니다. 학습 리마인드가 필요합니다.',
        priority: ReportActionPriority.low,
      ),
    );
  }
  return actions;
}

String _finalTouchTitle(FinalTouchSummary item) {
  final parts = [
    item.source,
    item.titleKo,
    item.titleEn,
  ].map((part) => part.trim()).where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) return 'Final Touch ${item.id}';
  return parts.first;
}

DateTime? _parseDate(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return DateTime.tryParse(value);
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _asString(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty || text == 'null') return fallback;
  return text;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  return const [];
}

int _compareNullableDateDesc(DateTime? a, DateTime? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return b.compareTo(a);
}
