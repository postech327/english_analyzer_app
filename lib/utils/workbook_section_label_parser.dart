class WorkbookSectionLabel {
  const WorkbookSectionLabel({
    required this.sectionTitle,
    required this.sectionKey,
    this.detailLabel,
  });

  final String sectionTitle;
  final String sectionKey;
  final String? detailLabel;
}

WorkbookSectionLabel parseWorkbookSectionLabel(
  String input, {
  String? explicitDetailLabel,
}) {
  final text = input.trim().replaceAll(RegExp(r'\s+'), ' ');
  final explicitDetail = normalizeWorkbookDetailLabel(explicitDetailLabel);

  final unitMatch = RegExp(
    r'^Unit\s*(\d+)(?:\s+(.*))?$',
    caseSensitive: false,
  ).firstMatch(text);
  if (unitMatch != null) {
    final number = unitMatch.group(1)!;
    return WorkbookSectionLabel(
      sectionTitle: '$number강',
      sectionKey: 'unit_$number',
      detailLabel:
          explicitDetail ?? normalizeWorkbookDetailLabel(unitMatch.group(2)),
    );
  }

  final koreanUnitMatch = RegExp(r'^(\d+)\s*강(?:\s*(.*))?$').firstMatch(text);
  if (koreanUnitMatch != null) {
    final number = koreanUnitMatch.group(1)!;
    return WorkbookSectionLabel(
      sectionTitle: '$number강',
      sectionKey: 'unit_$number',
      detailLabel: explicitDetail ??
          normalizeWorkbookDetailLabel(koreanUnitMatch.group(2)),
    );
  }

  final testMatch = RegExp(
    r'^Test(?:\s+(.*))?$',
    caseSensitive: false,
  ).firstMatch(text);
  if (testMatch != null) {
    return WorkbookSectionLabel(
      sectionTitle: 'Test',
      sectionKey: 'test',
      detailLabel:
          explicitDetail ?? normalizeWorkbookDetailLabel(testMatch.group(1)),
    );
  }

  final slug = text
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll(RegExp(r'[^a-z0-9가-힣_-]'), '');
  return WorkbookSectionLabel(
    sectionTitle: text,
    sectionKey: 'custom_${slug.isEmpty ? 'section' : slug}',
    detailLabel: explicitDetail,
  );
}

String? normalizeWorkbookDetailLabel(String? value) {
  final text = value?.trim().replaceAll(RegExp(r'\s+'), ' ') ?? '';
  if (text.isEmpty) return null;

  final noMatch = RegExp(
    r'^(?:No\.?\s*)?(\d+)(?:\s*번)?$',
    caseSensitive: false,
  ).firstMatch(text);
  if (noMatch != null) return '${noMatch.group(1)}번';

  final gatewayMatch = RegExp(
    r'^Gateway(?:\s*(\d+))?$',
    caseSensitive: false,
  ).firstMatch(text);
  if (gatewayMatch != null) {
    final number = gatewayMatch.group(1);
    return number == null ? 'Gateway' : 'Gateway $number';
  }

  return text;
}
