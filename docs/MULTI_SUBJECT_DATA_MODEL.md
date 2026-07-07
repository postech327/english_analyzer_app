# Multi-Subject Data Model Design

이 문서는 현재 영어 중심 Flutter + FastAPI 학습 앱을 국어, 영어, 수학, 과학, 한국대학입시컨설팅까지 확장하기 위한 공통 자료/문제/결과 데이터 모델 설계 초안입니다.

주의: 이 문서는 설계 문서입니다. 현재 단계에서는 실제 DB 스키마, migration, backend model, 기존 영어 기능을 변경하지 않습니다.

## 1. 설계 목표

공통 데이터 모델의 목표는 다음과 같습니다.

- 영어 전용 앱을 종합 학습 플랫폼으로 확장합니다.
- 과목별 개발자가 독립적으로 기능을 추가할 수 있게 합니다.
- 자료 업로드, 문제 풀이, 결과 저장, 오답 복습, 리포트를 공통 구조로 연결합니다.
- 기존 영어 Workbook, Vocabulary, Final Touch, Mock Exam 기능과 충돌하지 않게 점진적으로 확장합니다.
- DB 변경은 사전 설계 검토 후 별도 PR로 분리합니다.

## 2. 지원 과목

| subject_code | 한국어 이름 | 설명 |
| --- | --- | --- |
| `english` | 영어 | 기존 Workbook, Vocabulary, Final Touch, Mock Exam 중심 |
| `korean` | 국어 | 독서, 문학, 문법, 어휘 중심 |
| `math` | 수학 | 대수, 기하, 함수, 확률과 통계 중심 |
| `science` | 과학 | 물리, 화학, 생명과학, 지구과학 중심 |
| `admission` | 한국대학입시컨설팅 | 학생 프로필, 성적, 상담, 목표 대학, 리포트 중심 |

Flutter 공통 subject constants는 `lib/core/subject/subject_type.dart`의 `SubjectType`을 기준으로 사용합니다.

## 3. 공통 학습 흐름

### Teacher 흐름

1. 과목 선택
2. 자료 업로드
3. 문제 입력 또는 생성
4. 학생 또는 반에 배포
5. 결과 확인
6. 오답/약점 리포트 확인

### Student 흐름

1. 과목 선택
2. 배정된 자료 확인
3. 문제 풀이 또는 학습
4. 제출
5. 결과 확인
6. 오답 복습

## 4. 권장 공통 데이터 모델 초안

아래 모델은 장기 확장을 위한 초안입니다. 현재 단계에서는 실제 table 생성이나 migration을 진행하지 않습니다.

### Subject

과목 master data입니다.

| Field | Type 예시 | 설명 |
| --- | --- | --- |
| `id` | integer | 내부 식별자 |
| `code` | string | `english`, `korean`, `math`, `science`, `admission` |
| `name_ko` | string | 한국어 과목명 |
| `name_en` | string | 영어 과목명 |
| `is_active` | boolean | 사용 여부 |

### LearningMaterial

Teacher가 업로드하거나 작성한 학습 자료입니다.

| Field | Type 예시 | 설명 |
| --- | --- | --- |
| `id` | integer | 자료 ID |
| `subject_code` | string | 과목 코드 |
| `category` | string | 과목별 카테고리 |
| `title` | string | 자료 제목 |
| `source` | string nullable | 교재/출처 |
| `unit` | string nullable | 단원 |
| `lesson` | string nullable | 강/차시 |
| `content_text` | text nullable | 원문 텍스트 |
| `content_html` | text/json nullable | 렌더링용 HTML 또는 구조화 본문 |
| `original_file_name` | string nullable | 원본 파일명 |
| `created_by` | integer | Teacher user ID |
| `published` | boolean | 게시 여부 |
| `created_at` | datetime | 생성 시각 |
| `updated_at` | datetime | 수정 시각 |

### Question

자료에 연결되는 문제입니다.

| Field | Type 예시 | 설명 |
| --- | --- | --- |
| `id` | integer | 문제 ID |
| `material_id` | integer | LearningMaterial ID |
| `subject_code` | string | 과목 코드 |
| `question_type` | string | 문제 유형 |
| `question_text` | text | 문제 본문 |
| `passage_text` | text nullable | 지문/자료 본문 |
| `choices_json` | json nullable | 객관식 보기 |
| `answer` | text nullable | 정답 |
| `explanation` | text nullable | 해설 |
| `difficulty` | string/integer nullable | 난이도 |
| `order_index` | integer | 자료 내 정렬 순서 |
| `created_at` | datetime | 생성 시각 |
| `updated_at` | datetime | 수정 시각 |

### Assignment

Teacher가 특정 자료를 학생 또는 반에 배포한 기록입니다.

| Field | Type 예시 | 설명 |
| --- | --- | --- |
| `id` | integer | 배포 ID |
| `subject_code` | string | 과목 코드 |
| `material_id` | integer | LearningMaterial ID |
| `assigned_by` | integer | Teacher user ID |
| `assigned_to_type` | string | `student`, `class`, `group` 등 |
| `assigned_to_id` | integer | 대상 ID |
| `start_at` | datetime nullable | 시작 시각 |
| `due_at` | datetime nullable | 마감 시각 |
| `is_active` | boolean | 활성 여부 |

### StudentSubmission

학생 제출 단위의 결과 요약입니다.

| Field | Type 예시 | 설명 |
| --- | --- | --- |
| `id` | integer | 제출 ID |
| `student_id` | integer | Student user ID |
| `assignment_id` | integer nullable | Assignment ID |
| `material_id` | integer | LearningMaterial ID |
| `subject_code` | string | 과목 코드 |
| `score` | float/integer | 점수 |
| `total_questions` | integer | 전체 문항 수 |
| `correct_count` | integer | 정답 수 |
| `submitted_at` | datetime | 제출 시각 |

### StudentAnswer

학생의 문항별 답안입니다.

| Field | Type 예시 | 설명 |
| --- | --- | --- |
| `id` | integer | 답안 ID |
| `submission_id` | integer | StudentSubmission ID |
| `question_id` | integer | Question ID |
| `student_answer` | text/json nullable | 학생 답 |
| `correct_answer` | text/json nullable | 정답 |
| `is_correct` | boolean | 정답 여부 |
| `elapsed_seconds` | integer nullable | 풀이 시간 |

### ReviewItem

오답 복습 또는 약점 복습 항목입니다.

| Field | Type 예시 | 설명 |
| --- | --- | --- |
| `id` | integer | 복습 항목 ID |
| `student_id` | integer | Student user ID |
| `subject_code` | string | 과목 코드 |
| `question_id` | integer nullable | Question ID |
| `reason` | string | 오답, 취약 개념, teacher 지정 등 |
| `status` | string | `new`, `reviewing`, `mastered` 등 |
| `created_at` | datetime | 생성 시각 |
| `reviewed_at` | datetime nullable | 마지막 복습 시각 |

### CounselingRecord 또는 AdmissionRecord

입시컨설팅 전용 상담/성적/목표 대학 기록입니다.

| Field | Type 예시 | 설명 |
| --- | --- | --- |
| `id` | integer | 기록 ID |
| `student_id` | integer | Student user ID |
| `record_type` | string | `profile`, `grades`, `counseling`, `university`, `report` 등 |
| `title` | string | 기록 제목 |
| `content` | text/json | 상담 내용 또는 리포트 내용 |
| `target_university` | string nullable | 목표 대학 |
| `target_major` | string nullable | 목표 학과 |
| `grade_data_json` | json nullable | 성적 데이터 |
| `counselor_id` | integer nullable | 상담 teacher/counselor ID |
| `created_at` | datetime | 생성 시각 |
| `updated_at` | datetime | 수정 시각 |

## 5. 과목별 적용 예시

### 국어

권장 category:

- `reading`
- `literature`
- `grammar`
- `vocabulary`

권장 question_type:

- `main_idea`
- `detail`
- `inference`
- `grammar`
- `expression`

### 영어

권장 category:

- `workbook`
- `vocabulary`
- `final_touch`
- `mock_exam`

권장 question_type:

- `blank`
- `order`
- `insert`
- `grammar`
- `vocabulary`
- `summary`

주의: 기존 영어 기능은 현재 전용 table/API가 있으므로 즉시 공통 모델로 합치지 않습니다.

### 수학

권장 category:

- `algebra`
- `geometry`
- `function`
- `probability`

권장 question_type:

- `multiple_choice`
- `short_answer`
- `proof`
- `calculation`

### 과학

권장 category:

- `physics`
- `chemistry`
- `biology`
- `earth_science`

권장 question_type:

- `concept`
- `data_analysis`
- `experiment`
- `graph`
- `calculation`

### 입시컨설팅

권장 category:

- `profile`
- `grades`
- `counseling`
- `university`
- `report`

입시컨설팅은 일반 문제 풀이형 `question_type`이 필수는 아닙니다. 학생 프로필, 성적, 상담 기록, 목표 대학, 리포트 중심으로 별도 관리합니다.

## 6. 기존 영어 기능과의 연결 전략

기존 영어 Workbook, Vocabulary, Final Touch, Mock Exam table/API를 바로 공통 모델로 합치지 않습니다.

권장 단계:

1. 기존 영어 기능 유지
2. 새 공통 모델을 신규 과목부터 적용
3. 영어 기능 일부를 공통 모델과 연결
4. 통합 리포트에서 기존 영어 결과와 새 과목 결과를 함께 표시

### 단계별 연결 방식

#### 1단계: 기존 기능 유지

- 영어 Workbook/Vocabulary/Final Touch/Mock Exam은 기존 구조 유지
- 신규 과목은 아직 DB 변경 없이 feature 폴더와 화면 설계부터 시작

#### 2단계: 신규 과목부터 공통 모델 적용

- 국어 MVP 등 신규 과목에 `LearningMaterial`, `Question`, `Assignment`, `StudentSubmission` 구조 적용
- 기존 영어 table과 API는 그대로 유지

#### 3단계: 영어 일부 연결

- 영어 결과를 공통 리포트에서 읽을 수 있도록 adapter 또는 view 계층 추가
- 기존 table을 물리적으로 합치기보다 API response normalize부터 시작

#### 4단계: 통합 리포트

- 기존 영어 결과와 신규 과목 결과를 학생별/과목별로 함께 표시
- 오답 복습과 약점 분석도 subject_code 기준으로 통합

## 7. API 설계 초안

아래 API는 설계 초안입니다. 실제 구현 시 인증, 권한, pagination, 응답 schema를 별도로 정의합니다.

### Subject

```http
GET /subjects
```

### Teacher

```http
GET /teacher/{subject}/materials
POST /teacher/{subject}/materials
GET /teacher/{subject}/materials/{material_id}
POST /teacher/{subject}/materials/{material_id}/questions
POST /teacher/{subject}/assignments
GET /teacher/{subject}/submissions
```

### Student

```http
GET /student/{subject}/assignments
GET /student/{subject}/materials/{material_id}
POST /student/{subject}/submissions
GET /student/{subject}/results
GET /student/{subject}/review-items
```

### Admission

```http
GET /teacher/admission/students/{student_id}/records
POST /teacher/admission/students/{student_id}/records
GET /teacher/admission/students/{student_id}/report
```

## 8. 협업 개발 규칙

- 과목별 개발자는 자기 subject feature 폴더 안에서 작업합니다.
- 공통 데이터 모델 변경은 별도 PR로 분리합니다.
- DB 마이그레이션은 사전 설계 검토 후 진행합니다.
- 기존 영어 기능을 임의로 변경하지 않습니다.
- `teacher1` / `student1` 테스트 흐름을 깨지 않습니다.
- API 이름과 `subject_code`는 이 문서 기준을 따릅니다.
- 대규모 UI 개편, DB 변경, 기능 추가를 한 PR에 섞지 않습니다.
- OpenAI/GPT 호출은 명시된 기능 외에는 추가하지 않습니다.

## 9. 단계별 구현 로드맵

### Phase 1

- 문서화
- subject constants
- 과목 선택 UI
- 준비 중 화면

### Phase 2

- 공통 자료 업로드 MVP
- 국어 자료/문제 풀이 MVP

### Phase 3

- 수학/과학 문제 풀이 MVP
- 공통 결과 저장

### Phase 4

- 통합 리포트
- 오답 복습
- 학생별 과목별 약점 분석

### Phase 5

- 입시컨설팅 학생 프로필
- 상담 기록
- 목표 대학/학과 관리
- 입시 리포트

## 10. 다음 설계 검토 항목

실제 DB 변경 전에 아래를 추가 검토합니다.

- 기존 user/class/student model과 Assignment 연결 방식
- `assigned_to_type`의 허용 값
- `choices_json`, `grade_data_json`, `content_html`의 JSON schema
- question_type 표준화 범위
- 과목별 scoring 정책
- 기존 영어 결과를 통합 리포트로 노출하는 adapter 방식
- migration 전략과 rollback 전략

