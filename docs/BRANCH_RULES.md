# Branch and Pull Request Rules

## 1. 과목별 브랜치 이름 규칙

과목별 기능은 `feature/{subject}-{feature}-mvp` 형태를 권장합니다.

예시:

- `feature/korean-material-mvp`
- `feature/math-question-mvp`
- `feature/science-material-mvp`
- `feature/admission-profile-mvp`

Codex 작업 브랜치는 기존 협업 흐름에 맞춰 `codex/` prefix를 사용할 수 있습니다.

예시:

- `codex/korean-material-mvp`
- `codex/math-question-mvp`

## 2. 기존 영어 기능 수정 규칙

기존 영어 기능을 수정할 때는 별도 브랜치를 사용합니다.

예시:

- `feature/english-workbook-fix`
- `feature/english-vocabulary-ui`
- `feature/final-touch-import-fix`

새 과목 기능 PR에 영어 기능 수정을 섞지 않습니다.

## 3. DB 변경 PR 분리

DB 변경 PR은 반드시 별도로 분리합니다.

DB 변경에 포함되는 작업:

- table 추가/삭제
- column 추가/삭제
- migration 추가
- 기존 데이터 변환
- backend model/schema 변경

권장 브랜치 예시:

- `feature/math-db-schema`
- `feature/science-db-schema`
- `db/subject-foundation`

## 4. UI 개편과 기능 추가 분리

대규모 UI 개편과 기능 추가를 한 PR에 섞지 않습니다.

권장 분리:

- 기능 MVP PR
- UI polish PR
- DB/schema PR
- test/refactor PR

## 5. PR 완료 보고 규칙

PR 완료 보고에는 테스트 결과를 포함합니다.

필수 보고:

- 브랜치명
- 커밋 해시
- 수정/추가 파일 목록
- 테스트 명령과 결과
- Backend/API/DB 변경 여부
- OpenAI/GPT 호출 여부
- 남은 주의사항

## 6. 충돌 방지 규칙

각 개발자는 자기 subject feature 폴더 중심으로 작업합니다.

권장 작업 범위:

- 국어: `lib/features/korean/`
- 수학: `lib/features/math/`
- 과학: `lib/features/science/`
- 입시컨설팅: `lib/features/admission/`
- 공통 subject 타입: `lib/core/subject/`

공통 파일을 수정해야 할 때는 PR 설명에 이유를 명확히 적고, 영향받는 과목을 함께 표시합니다.

