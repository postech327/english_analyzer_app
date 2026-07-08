# Subject Module Guide

이 문서는 기존 영어 학습 앱을 국어, 수학, 과학, 한국대학입시컨설팅까지 확장할 때 지켜야 할 과목별 모듈 개발 기준입니다.

## 1. 기본 원칙

새 과목 기능은 원칙적으로 `lib/features/{subject}/` 폴더 안에서 개발합니다.

예시:

```text
lib/features/korean/
lib/features/math/
lib/features/science/
lib/features/admission/
```

공통 기능은 `lib/core/` 또는 기존 공통 폴더를 사용합니다. 공통 위젯, 공통 라우팅, 공통 API helper, 공통 subject constants처럼 여러 과목에서 공유하는 코드만 공통 영역에 둡니다.

## 2. 기존 영어 기능 보호

기존 영어 기능은 임의로 수정하지 않습니다.

특히 아래 기능은 회귀가 생기면 안 됩니다.

- Workbook
- Vocabulary
- Final Touch
- Mock Exam
- Results / Report / Wrong Note

영어 기능을 수정해야 하는 경우에는 해당 목적을 명확히 한 별도 브랜치와 PR로 분리합니다.

## 3. 과목별 작업 범위

과목별 개발자는 자기 과목 폴더 밖의 파일 수정을 최소화합니다.

수정 권장 범위:

- `lib/features/{subject}/`
- 과목 공통 타입이 필요한 경우 `lib/core/subject/`
- 라우팅 연결이 필요한 경우 subject route registry 또는 공통 route 파일
- 문서 변경이 필요한 경우 `docs/`

수정 전 주의가 필요한 범위:

- 기존 영어 screen/service/model
- 인증/로그인 흐름
- 기존 Workbook / Vocabulary / Final Touch / Mock Exam
- Backend DB schema와 model

## 4. 라우팅 연결 기준

라우팅 연결이 필요한 경우 과목별 화면에서 직접 기존 영어 라우트를 침범하지 말고, subject route registry 또는 공통 route 파일만 수정합니다.

권장 흐름:

1. 과목 feature 폴더 안에 Teacher/Student 진입 화면 작성
2. 공통 subject route registry에 route metadata 추가
3. 기존 teacher/student dashboard에는 최소 연결만 추가

## 5. 로그인/역할 흐름 유지

`teacher1` / `student1` 로그인 흐름은 반드시 유지합니다.

각 과목은 Teacher 화면과 Student 화면을 분리해서 구현합니다.

권장 구조:

```text
lib/features/{subject}/teacher/
lib/features/{subject}/student/
lib/features/{subject}/models/
lib/features/{subject}/services/
lib/features/{subject}/widgets/
```

## 6. OpenAI/GPT 호출 제한

OpenAI/GPT 호출은 명시된 기능 외에는 금지합니다.

새 과목에서 AI 호출이 필요한 경우:

1. 별도 요청문에 목적과 비용/호출 시점을 명시
2. backend/API 영향 범위 명시
3. 테스트 기준과 fallback 정책 명시
4. 별도 PR로 분리

## 7. DB 변경 기준

DB 스키마 변경이 필요하면 별도 PR/요청문으로 분리합니다.

이번 과목 확장 초기 단계에서는 Flutter 구조와 문서 중심으로 개발하고, DB는 기존 구조를 우선 보존합니다.

DB 변경이 필요한 예:

- 새 subject별 material table 추가
- question/result 공통화
- subject/category 필드 추가
- migration 필요

이런 변경은 기능 PR에 섞지 말고 `db/*` 또는 `feature/{subject}-db-*` 브랜치에서 별도 진행합니다.

## 8. 과목별 완료 기준

각 과목 기능 PR은 최소한 아래를 보고해야 합니다.

- 수정/추가 파일 목록
- Teacher 화면 동작 여부
- Student 화면 동작 여부
- 기존 영어 기능 회귀 테스트 결과
- Backend/API/DB 변경 여부
- OpenAI/GPT 호출 여부
- 웹 빌드 또는 관련 analyze/test 결과

