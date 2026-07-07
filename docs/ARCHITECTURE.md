# Architecture

## 1. 앱 목표

현재 앱은 영어 학습 기능을 중심으로 구축되어 있습니다. 장기 목표는 영어 앱에서 종합 학습 플랫폼으로 확장하는 것입니다.

확장 대상 과목:

- 영어
- 국어
- 수학
- 과학
- 한국대학입시컨설팅

## 2. 역할 구조

앱의 기본 역할은 두 가지입니다.

### Teacher

Teacher는 자료를 업로드하고, 학습 콘텐츠를 구성하고, 학생에게 배포하고, 결과를 확인합니다.

### Student

Student는 배포받은 자료를 학습하거나 풀이하고, 결과를 저장하고, 오답/복습/리포트를 확인합니다.

기존 `teacher1` / `student1` 로그인 흐름은 모든 과목 확장 이후에도 유지되어야 합니다.

## 3. 과목 구조

과목 key는 다음 값을 기준으로 사용합니다.

| Key | 이름 |
| --- | --- |
| `english` | 영어 |
| `korean` | 국어 |
| `math` | 수학 |
| `science` | 과학 |
| `admission` | 한국대학입시컨설팅 |

Flutter에서는 `lib/core/subject/subject_type.dart`의 `SubjectType`을 공통 상수로 사용합니다.

## 4. 공통 학습 흐름

대부분의 과목 기능은 아래 흐름을 공유합니다.

1. Teacher 자료 업로드
2. DB 저장
3. 학생 배포
4. Student 풀이/학습
5. 결과 저장
6. Teacher 결과 확인
7. 리포트/오답 복습

과목마다 자료 형태와 문제 유형은 다를 수 있지만, 배포/학습/결과/리포트 흐름은 가능한 한 공통화합니다.

## 5. Flutter 권장 폴더 구조

```text
lib/
  core/
    subject/
    routing/
    widgets/
    services/
  features/
    english/
    korean/
    math/
    science/
    admission/
```

현재 영어 기능은 기존 폴더 구조에 많이 남아 있으므로, 새 과목부터 `lib/features/{subject}/` 구조를 우선 적용합니다. 영어 기능을 feature 구조로 이동하는 작업은 별도 리팩터링 PR에서만 진행합니다.

과목별 예시:

```text
lib/features/math/
  teacher/
  student/
  models/
  services/
  widgets/
  utils/
```

## 6. Backend 권장 구조

현재 backend는 FastAPI 기반이며, 장기적으로 아래 구조를 권장합니다.

```text
routers/
models.py 또는 models/
schemas/
services/
```

subject별 확장 방식 예시:

```text
routers/korean.py
routers/math.py
routers/science.py
routers/admission.py
services/korean/
services/math/
services/science/
services/admission/
```

단, 초기 단계에서는 DB 스키마와 기존 API를 최대한 보존합니다. 새 subject API가 필요한 경우에도 기존 영어 API를 깨지 않도록 별도 router와 별도 PR로 진행합니다.

## 7. DB 장기 확장 방향

장기적으로 DB는 다음과 같은 공통 구조로 확장할 수 있습니다.

- `subject`
- `category`
- `material`
- `question`
- `assignment`
- `attempt`
- `result`
- `report`

예시 개념:

```text
subject -> category -> material -> question
material -> assignment -> student
student -> attempt/result -> report/wrong note
```

하지만 현재 단계에서는 DB 스키마 변경을 최소화하고, schema 변경은 별도 migration/PR로 분리합니다.

## 8. 회귀 방지 우선순위

과목 확장 중에도 아래 기존 영어 기능은 우선 보호 대상입니다.

- Workbook
- Vocabulary
- Final Touch
- Mock Exam
- Student Dashboard / Teacher Dashboard
- Results / Integrated Report / Wrong Note

