# Codex Prompt Template

아래 템플릿을 복사해서 과목별 작업 요청문으로 사용합니다.

```text
작업 제목:
예: korean_material_mvp_001

현재 Flutter + FastAPI 기반 종합 학습 앱에서 {과목명} 기능을 개발하려고 합니다.

프로젝트 경로:
Backend:
C:\python\my_new_project

Flutter:
C:\python\english_analyzer_app

실행 명령:
Backend:
cd C:\python\my_new_project
uvicorn main:app --reload --port 8001

Flutter:
cd C:\python\english_analyzer_app
flutter run -d chrome --dart-define=API_BASE=http://127.0.0.1:8001

현재 완료된 기능:
- 예: 기존 영어 Workbook / Vocabulary / Final Touch / Mock Exam 정상
- 예: teacher1 / student1 로그인 정상
- 예: {과목명} 기본 진입 화면만 있음

작업 목표:
- 이번 작업에서 구현할 기능을 구체적으로 작성
- Teacher 화면 목표
- Student 화면 목표
- 저장/배포/결과가 필요한지 명시

수정 가능 파일:
- lib/features/{subject}/
- lib/core/subject/
- 필요한 경우 docs/
- 필요한 경우 공통 route registry

수정 금지 또는 주의 파일:
- 기존 영어 기능 파일
- 인증/로그인 흐름
- 기존 Workbook / Vocabulary / Final Touch / Mock Exam
- Backend DB schema
- OpenAI/GPT 호출부

유지해야 할 기존 기능:
- teacher1 로그인
- student1 로그인
- 기존 영어 기능 진입 및 실행
- 기존 배포/결과 저장 흐름
- 기존 웹 빌드

테스트 기준:
1. 관련 unit/widget test 통과
2. 관련 파일 dart analyze 통과
3. 가능하면 flutter build web --debug 통과
4. teacher1 / student1 기본 흐름 유지
5. 기존 영어 주요 화면 진입 가능
6. Backend/API/DB 변경 여부 확인
7. OpenAI/GPT 호출 없음 또는 호출 위치 명시

완료 보고 형식:
1. 브랜치명
2. 커밋 해시
3. 수정/추가 파일 목록
4. 구현 내용 요약
5. 테스트 결과
6. Backend/API/DB 변경 여부
7. OpenAI/GPT 호출 여부
8. 남은 주의사항
```

## 작성 팁

- 한 PR에는 하나의 목적만 담습니다.
- DB 변경, 대규모 UI 개편, 기능 추가는 가능하면 분리합니다.
- 기존 영어 기능을 건드려야 한다면 이유와 영향 범위를 먼저 적습니다.
- 실제 테스트 계정과 확인 경로를 함께 적으면 협업자가 빠르게 검증할 수 있습니다.

