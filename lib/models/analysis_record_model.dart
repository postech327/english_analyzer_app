// lib/models/analysis_record_model.dart
class AnalysisRecord {
  final int id;
  final String kind;
  final String inputText;
  final String resultText;
  final String resultJson; // 서버에서 string 으로 저장/반환
  final String createdAt;

  AnalysisRecord({
    required this.id,
    required this.kind,
    required this.inputText,
    required this.resultText,
    required this.resultJson,
    required this.createdAt,
  });

  factory AnalysisRecord.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['analysis_id'];
    final id = rawId is int ? rawId : int.parse(rawId.toString());

    return AnalysisRecord(
      id: id,
      kind: (json['kind'] ?? '').toString(),
      inputText: (json['input_text'] ?? '').toString(),
      resultText: (json['result_text'] ?? '').toString(),
      resultJson: (json['result_json'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}
