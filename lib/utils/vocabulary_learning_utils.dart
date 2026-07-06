import '../models/vocabulary.dart';

String displayVocabularyMeaning(String raw) {
  return raw
      .split(RegExp(r'\s*[,;/]\s*'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .join(' · ');
}

class VocabularyLearningRange {
  const VocabularyLearningRange({
    required this.label,
    required this.start,
    required this.end,
    required this.totalCount,
    this.isAll = false,
  });

  final String label;
  final int start;
  final int end;
  final int totalCount;
  final bool isAll;

  int get count => end - start;
  String get rangeLabel => isAll ? '전체 $totalCount단어' : '${start + 1}~$end';

  List<VocabularyItem> select(List<VocabularyItem> items) =>
      items.sublist(start, end);
}

List<VocabularyLearningRange> buildVocabularyLearningRanges(
  int totalCount, {
  int chunkSize = 20,
}) {
  if (totalCount <= 0) return const [];
  final ranges = <VocabularyLearningRange>[
    VocabularyLearningRange(
      label: '전체',
      start: 0,
      end: totalCount,
      totalCount: totalCount,
      isAll: true,
    ),
  ];
  var setNumber = 1;
  for (var start = 0; start < totalCount; start += chunkSize) {
    final end = start + chunkSize > totalCount ? totalCount : start + chunkSize;
    ranges.add(
      VocabularyLearningRange(
        label: '$setNumber세트',
        start: start,
        end: end,
        totalCount: totalCount,
      ),
    );
    setNumber++;
  }
  return ranges;
}

class VocabularyLearningGroup {
  const VocabularyLearningGroup({
    required this.label,
    required this.items,
  });

  final String label;
  final List<VocabularyItem> items;
  int get count => items.length;
}

List<VocabularyLearningGroup> buildVocabularyLearningGroups(
  List<VocabularyItem> items,
) {
  final grouped = <String, List<VocabularyItem>>{};
  for (final item in items) {
    final label = (item.groupLabel ?? '').trim();
    grouped.putIfAbsent(label.isEmpty ? '미분류' : label, () => []).add(item);
  }
  return [
    for (final entry in grouped.entries)
      VocabularyLearningGroup(label: entry.key, items: entry.value),
  ];
}

bool hasVocabularyGroups(List<VocabularyItem> items) =>
    items.any((item) => (item.groupLabel ?? '').trim().isNotEmpty);

List<VocabularyItem> wrongVocabularyItems(
  List<VocabularyItem> items,
  Iterable<VocabularyAttemptResult> results,
) {
  final wrongIds = results
      .where((result) => !result.isCorrect)
      .map((result) => result.itemId)
      .toSet();
  return items.where((item) => wrongIds.contains(item.id)).toList();
}
