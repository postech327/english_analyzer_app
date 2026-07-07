class FinalTouchSortKey implements Comparable<FinalTouchSortKey> {
  const FinalTouchSortKey({
    required this.unitNumber,
    required this.itemOrder,
    required this.itemNumber,
    required this.label,
    required this.isParsed,
  });

  final int unitNumber;
  final int itemOrder;
  final int itemNumber;
  final String label;
  final bool isParsed;

  @override
  int compareTo(FinalTouchSortKey other) {
    final unitCompare = unitNumber.compareTo(other.unitNumber);
    if (unitCompare != 0) return unitCompare;
    final orderCompare = itemOrder.compareTo(other.itemOrder);
    if (orderCompare != 0) return orderCompare;
    final itemCompare = itemNumber.compareTo(other.itemNumber);
    if (itemCompare != 0) return itemCompare;
    return label.toLowerCase().compareTo(other.label.toLowerCase());
  }
}

FinalTouchSortKey parseFinalTouchSortKey(String value) {
  final label = value.trim();
  final normalized = label
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'[－–—]'), '-')
      .trim();
  final lower = normalized.toLowerCase();

  final unitNumber = _firstNumber([
    RegExp(r'\bunit\s*0*(\d+)\b', caseSensitive: false),
    RegExp(r'\blesson\s*0*(\d+)\b', caseSensitive: false),
    RegExp(r'\bchapter\s*0*(\d+)\b', caseSensitive: false),
    RegExp(r'\bch\.?\s*0*(\d+)\b', caseSensitive: false),
    RegExp(r'(?:제\s*)?0*(\d+)\s*강'),
  ], normalized);
  final noNumber = _firstNumber([
    RegExp(r'\bno\.?\s*[-.]?\s*0*(\d+)\b', caseSensitive: false),
    RegExp(r'0*(\d+)\s*번'),
  ], normalized);
  final isGateway = lower.contains('gateway');
  final isParsed = unitNumber != null || noNumber != null || isGateway;

  return FinalTouchSortKey(
    unitNumber: unitNumber ?? 1 << 30,
    itemOrder: isGateway ? 0 : 1,
    itemNumber: isGateway ? 0 : noNumber ?? 1 << 30,
    label: label,
    isParsed: isParsed,
  );
}

List<T> sortByFinalTouchNaturalOrder<T>(
  Iterable<T> items, {
  required String Function(T item) labelOf,
  String Function(T item)? folderOf,
  String Function(T item)? createdAtOf,
}) {
  final sorted = List<T>.from(items);
  sorted.sort((a, b) {
    final folderA = (folderOf?.call(a) ?? '').trim().toLowerCase();
    final folderB = (folderOf?.call(b) ?? '').trim().toLowerCase();
    final folderCompare = folderA.compareTo(folderB);
    if (folderCompare != 0) return folderCompare;

    final labelA = labelOf(a).trim();
    final labelB = labelOf(b).trim();
    final keyA = parseFinalTouchSortKey(labelA);
    final keyB = parseFinalTouchSortKey(labelB);
    if (keyA.isParsed && keyB.isParsed) {
      final keyCompare = keyA.compareTo(keyB);
      if (keyCompare != 0) return keyCompare;
    } else if (keyA.isParsed != keyB.isParsed) {
      return keyA.isParsed ? -1 : 1;
    }

    final dateCompare = _dateScore(createdAtOf?.call(b))
        .compareTo(_dateScore(createdAtOf?.call(a)));
    if (dateCompare != 0) return dateCompare;
    return labelA.toLowerCase().compareTo(labelB.toLowerCase());
  });
  return sorted;
}

int? _firstNumber(List<RegExp> patterns, String value) {
  for (final pattern in patterns) {
    final match = pattern.firstMatch(value);
    if (match == null) continue;
    final parsed = int.tryParse(match.group(1) ?? '');
    if (parsed != null) return parsed;
  }
  return null;
}

int _dateScore(String? value) {
  if (value == null || value.trim().isEmpty) return 0;
  return DateTime.tryParse(value)?.millisecondsSinceEpoch ?? 0;
}
