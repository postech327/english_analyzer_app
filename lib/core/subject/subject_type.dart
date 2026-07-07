enum SubjectType {
  english('english', '영어'),
  korean('korean', '국어'),
  math('math', '수학'),
  science('science', '과학'),
  admission('admission', '한국대학입시컨설팅');

  const SubjectType(this.key, this.koreanName);

  final String key;
  final String koreanName;

  static SubjectType? tryParse(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toLowerCase();
    for (final subject in SubjectType.values) {
      if (subject.key == normalized || subject.name == normalized) {
        return subject;
      }
    }
    return null;
  }
}

const supportedSubjectTypes = SubjectType.values;
