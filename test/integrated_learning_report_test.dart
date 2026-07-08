import 'package:english_analyzer_app/models/integrated_learning_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calculates completion, review count, and latest study date', () {
    final workbookDate = DateTime(2026, 7, 1);
    final vocabularyDate = DateTime(2026, 7, 7);
    final finalTouchDate = DateTime(2026, 7, 3);
    final student = StudentIntegratedLearningReport(
      studentId: 1,
      studentName: 'student1',
      email: 'student1@example.com',
      workbook: WorkbookReportSummary(
        totalCount: 8,
        completedCount: 5,
        incompleteCount: 3,
        averageScore: 76,
        lastStudyAt: workbookDate,
        weakTypes: const ['blank', 'grammar'],
      ),
      vocabulary: VocabularyReportSummary(
        assignedBookCount: 12,
        completedBookCount: 9,
        studiedWordCount: 320,
        wrongWordCount: 18,
        lastStudyAt: vocabularyDate,
      ),
      finalTouch: FinalTouchReportSummary(
        totalCount: 15,
        viewedCount: 6,
        notViewedCount: 9,
        sentenceAssemblyCompletedCount: 2,
        lastViewedAt: finalTouchDate,
      ),
      recommendedActions: const [
        RecommendedLearningAction(
          area: 'Vocabulary',
          title: '오답 단어 복습',
          message: '오답 단어를 다시 풀도록 안내해 보세요.',
        ),
      ],
    );

    expect(student.completedLearningCount, 20);
    expect(student.totalLearningCount, 35);
    expect(student.incompleteCount, 15);
    expect(student.reviewItemCount, 29);
    expect(student.needsReview, isTrue);
    expect(student.lastStudyAt, vocabularyDate);
    expect(student.overallCompletionRate, closeTo(20 / 35, 0.0001));
  });

  test('empty data stays safe for MVP fallback', () {
    const student = StudentIntegratedLearningReport(
      studentId: 2,
      studentName: 'student2',
      email: '',
      workbook: WorkbookReportSummary.empty,
      vocabulary: VocabularyReportSummary.empty,
      finalTouch: FinalTouchReportSummary.empty,
      recommendedActions: [],
    );

    expect(student.completedLearningCount, 0);
    expect(student.totalLearningCount, 0);
    expect(student.overallCompletionRate, 0);
    expect(student.hasAnyStudyRecord, isFalse);
    expect(student.lastStudyAt, isNull);
    expect(student.needsReview, isFalse);
  });

  test('report summary counts active and review-needed students', () {
    final report = IntegratedLearningReport(
      generatedAt: DateTime(2026, 7, 8),
      students: [
        StudentIntegratedLearningReport(
          studentId: 1,
          studentName: 'student1',
          email: '',
          workbook: const WorkbookReportSummary(
            totalCount: 1,
            completedCount: 1,
            incompleteCount: 0,
            averageScore: 90,
          ),
          vocabulary: VocabularyReportSummary.empty,
          finalTouch: FinalTouchReportSummary.empty,
          recommendedActions: const [],
        ),
        const StudentIntegratedLearningReport(
          studentId: 2,
          studentName: 'student2',
          email: '',
          workbook: WorkbookReportSummary.empty,
          vocabulary: VocabularyReportSummary.empty,
          finalTouch: FinalTouchReportSummary.empty,
          recommendedActions: [
            RecommendedLearningAction(
              area: '전체',
              title: '최근 학습 기록 없음',
              message: '학습 리마인드가 필요합니다.',
            ),
          ],
        ),
      ],
    );

    expect(report.totalStudents, 2);
    expect(report.activeStudentCount, 1);
    expect(report.needsReviewStudentCount, 1);
  });
}
