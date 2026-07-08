# Final Touch Import 및 UI 개선 PR 병합 전 확인 문서

이 문서는 `codex/flutter-collaboration-test` 브랜치의 Flutter PR #1 병합 전 확인을 위한 정리 문서입니다.

이번 PR은 Final Touch HWPX Import 안정화, Final Touch 저장/정렬 UX 개선, Teacher/Student 화면 진입 구조 정리, Final Touch 상세 학습 화면 개선을 포함합니다. Backend/API/DB 스키마 변경 없이 Flutter 중심으로 진행되었습니다.

## 작업 요약

### 1. Final Touch HWPX Import 안정화

- HWPX 하나에 여러 지문이 들어 있는 경우 draft 후보를 다중 지문으로 분리하도록 안정화했습니다.
- `Unit 1 Gateway`, `Unit 1 No. 1`, `Unit 1 No. 2`, `Unit 2 Gateway`, `Unit 2 No. 1`, `Unit 2 No. 2` 같은 Unit/Gateway/No. 구조를 인식합니다.
- 2단/표 형태 HWPX에서 왼쪽 영어 지문과 오른쪽 정답/소재/해석/해설/어휘 영역이 분리되어 추출되는 경우, 대응되는 지문끼리 병합하도록 보정했습니다.
- 오른쪽 영역의 `Gateway`, `01`, `02`, `No. 1`, `No. 2` 같은 제목이 별도 지문으로 생성되지 않도록 처리했습니다.
- `[해석]`, `해석:`, `[한글 해석]` 블록은 한국어 해석으로 추출하고, `[해설]`, `[풀이]`, `[어휘]` 이후 내용이 해석에 섞이지 않도록 분리했습니다.
- ①~⑫ 등 번호 marker가 붙은 영어 문장, 따옴표 시작 문장, dash, `[ ]`, `{ }`, `( )`가 포함된 문장을 영어 지문으로 유지하도록 보강했습니다.
- 6지문 HWPX Import 기준으로 후보 6개가 생성되고, 각 후보에 영어 지문과 원본 한국어 해석이 반영되는 흐름을 안정화했습니다.

### 2. Final Touch 저장/정렬 개선

- 교재 폴더 내부에서 HWPX 가져오기를 실행하면 해당 `folderId`/`folderName`이 Import 화면과 저장 payload에 전달되도록 수정했습니다.
- 폴더 안에서 가져온 자료가 `미분류`로 저장되는 문제를 수정했습니다.
- 저장 완료 후 snackbar에 저장 개수와 저장 위치가 표시되도록 개선했습니다.
- Final Touch 목록에서 `Unit/Gateway/No.` 기준 자연 정렬을 적용했습니다.
  - 예: `Unit 1 Gateway` → `Unit 1 No. 1` → `Unit 1 No. 2` → `Unit 2 Gateway` → `Unit 2 No. 1` → `Unit 2 No. 2`
- 교재 폴더 루트 및 폴더 내부 목록에서 HWPX 가져오기 진입점을 정리했습니다.
  - 루트 화면의 floating import 버튼 제거
  - 폴더 내부에서는 “이 폴더에 HWPX 가져오기” 형태로 저장 위치를 명확히 표시

### 3. Final Touch 상세 화면 개선

- Final Touch 상세 상단 영역을 영어 지문 / 한국어 해석 비교형 레이아웃으로 개선했습니다.
- 넓은 화면에서는 영어 지문과 한국어 해석을 좌우 2단으로 표시합니다.
- 최근 정리에서 상단 비율을 영어 8 : 해석 2로 조정해 영어 지문을 중심으로 읽기 쉽게 만들었습니다.
- 상단 영어 영역에 반복적으로 보이던 문장별 카드/번호 배지를 제거하고, 전체 영어 지문만 표시하도록 정리했습니다.
- 괄호 구조 보기 / 일반 지문 보기 토글과 괄호 색상 표시는 유지했습니다.
- 아래쪽 “문장별 세부 분석” 영역은 기존 구조를 유지했습니다.
  - 문장 번호
  - 문장 역할
  - 영문 분석
  - 해석
  - 문법/문제화 포인트

### 4. Teacher UI 개선

- Teacher 사이드바에 `Workbook 관리`, `단어장 관리` 메뉴를 추가했습니다.
- 메뉴 위치는 `Final Touch 모음` 바로 아래로 배치했습니다.
- Teacher 사이드바 메뉴가 화면 높이를 초과할 때 overflow가 나지 않도록 스크롤 가능한 구조로 보정했습니다.

### 5. Student UI 개선

- Student 화면에 학생용 drawer/sidebar를 추가했습니다.
- Student 메뉴에는 학생용 항목만 표시되도록 정리했습니다.
  - 오늘의 학습
  - Final Touch 복습
  - 워크북 학습
  - 단어장 학습
  - 모의고사 풀기
  - 내 결과
  - 마이페이지
  - 로그아웃
- Teacher 전용 메뉴가 Student 화면에 노출되지 않도록 분리했습니다.
- Student 홈의 “오늘의 학습” 카드 구조를 통일했습니다.
- 기존에 별도 카드로 떨어져 있던 워크북 학습을 오늘의 학습 목록 안으로 이동했습니다.

## 주요 변경 파일

아래는 이번 PR에서 핵심적으로 변경된 Flutter 파일입니다.

- `lib/screens/teacher_final_touch_import_screen.dart`
  - Final Touch HWPX Import 미리보기, 다중 지문 후보, 저장 위치 표시, 저장 처리
- `lib/utils/final_touch_hwpx_import_parser.dart`
  - HWPX 다중 지문 분리, companion 해석 블록 병합, 영어 문장 복구
- `lib/utils/final_touch_sort_key.dart`
  - Unit/Gateway/No. 기반 정렬 key 계산
- `lib/screens/final_touch_list_screen.dart`
  - Final Touch 목록 정렬, 폴더별 저장 위치, Import 진입점 정리, 상세 화면 진입
- `lib/widgets/final_touch_sentence_analysis.dart`
  - Final Touch 상세 상단 영어/해석 비교 레이아웃, 괄호 구조 표시, 문장별 세부 분석 UI
- `lib/screens/teacher_mode.dart`
  - Teacher 사이드바 메뉴 추가 및 overflow 대응
- `lib/screens/student_home_screen.dart`
  - Student 홈 오늘의 학습 카드 구조 정리
- `lib/screens/student_mode.dart`
  - Student drawer/sidebar 추가 및 학생용 메뉴 분리
- 관련 테스트 파일
  - Final Touch Import parser 테스트
  - Final Touch 정렬 테스트
  - Final Touch 전체 지문 위젯 테스트

## 테스트 완료 항목

진행된 확인 항목은 다음과 같습니다.

- HWPX 6지문 Import 후보 생성
  - `Unit 1 Gateway`
  - `Unit 1 No. 1`
  - `Unit 1 No. 2`
  - `Unit 2 Gateway`
  - `Unit 2 No. 1`
  - `Unit 2 No. 2`
- 오른쪽 영역의 `Gateway`, `01`, `02` 등이 별도 후보로 생성되지 않는지 확인
- `[해석]`부터 `[해설]` 전까지의 원본 해석 추출 확인
- `[해설]`, `[풀이]`, `[어휘]` 내용이 한국어 해석에 섞이지 않는지 확인
- 번호 marker가 붙은 영어 문장 복구 확인
- 폴더 내부 HWPX Import 시 저장 위치 표시 확인
- 저장 후 해당 폴더 목록에 자료가 표시되는지 확인
- Final Touch 목록 Unit/No. 정렬 확인
- Teacher 사이드바에 Workbook 관리 / 단어장 관리 메뉴 표시 확인
- Student drawer/sidebar에 학생용 메뉴만 표시되는지 확인
- Student 홈 오늘의 학습 카드 구조 통일 확인
- Final Touch 상세 상단 영어/해석 2단 비교 레이아웃 확인
- 상단 반복 문장 카드 제거 및 하단 문장별 세부 분석 유지 확인

## 수동 테스트 체크리스트

병합 전 또는 병합 직후 아래 흐름을 한 번 더 확인하는 것을 권장합니다.

### Backend 실행

```powershell
cd C:\python\my_new_project
uvicorn main:app --reload --port 8001
```

### Flutter 실행

```powershell
cd C:\python\english_analyzer_app
flutter run -d chrome --dart-define=API_BASE=http://127.0.0.1:8001
```

### Teacher Final Touch Import

- [ ] `teacher1` 로그인
- [ ] Final Touch 모음 진입
- [ ] 교재 폴더 선택
- [ ] “이 폴더에 HWPX 가져오기” 클릭
- [ ] Import 화면 상단 저장 위치가 선택한 폴더명으로 표시되는지 확인
- [ ] 6지문 HWPX 선택
- [ ] 후보가 정확히 6개 생성되는지 확인
- [ ] `Gateway` 또는 `01` 같은 오른쪽 제목만 별도 후보로 생성되지 않는지 확인
- [ ] 각 후보에 영어 지문과 원본 한국어 해석이 함께 표시되는지 확인
- [ ] 저장 후 선택한 폴더 안에 자료가 표시되는지 확인
- [ ] 목록이 Unit/Gateway/No. 순서로 정렬되는지 확인

### Student Final Touch 상세

- [ ] `student1` 또는 배포받은 학생 계정 로그인
- [ ] Final Touch 복습 진입
- [ ] 자료 상세 화면 진입
- [ ] 넓은 화면에서 상단이 영어/해석 2단 비교 레이아웃으로 보이는지 확인
- [ ] 영어 영역이 더 넓고, 한국어 해석이 보조 칼럼으로 보이는지 확인
- [ ] 상단 영어 영역에 문장별 반복 카드가 더 이상 보이지 않는지 확인
- [ ] 아래쪽 문장별 세부 분석은 기존처럼 보이는지 확인
- [ ] 괄호 구조 보기 / 일반 지문 보기 토글이 정상 동작하는지 확인
- [ ] PDF 출력 버튼이 정상 동작하는지 확인
- [ ] 문장 조립 연습 진입이 정상 동작하는지 확인

### Teacher/Student Navigation

- [ ] Teacher 사이드바에 `Workbook 관리`, `단어장 관리`가 보이는지 확인
- [ ] Teacher 사이드바에서 overflow가 발생하지 않는지 확인
- [ ] Student drawer/sidebar에 학생용 메뉴만 보이는지 확인
- [ ] Student 홈의 오늘의 학습 안에 `워크북 학습`이 포함되어 있는지 확인
- [ ] Teacher 전용 메뉴가 Student 화면에 보이지 않는지 확인

## 알려진 제한사항

- 일부 버튼 디자인은 추후 디자인 마감 단계에서 개선 예정입니다.
- HWPX parser는 현재 학원 자료 구조 기준으로 안정화되었지만, 완전히 다른 양식의 HWPX는 추가 패턴 대응이 필요할 수 있습니다.
- 전체 `dart analyze`에는 기존 프로젝트 경고가 남아 있을 수 있습니다.
- 현재 Import parser는 HWPX 추출 텍스트의 순서와 표/텍스트박스 구조에 의존하므로, HWPX 작성 방식이 크게 다른 자료는 별도 샘플 기반 보강이 필요할 수 있습니다.
- 구형 `.hwp`는 직접 지원하지 않고, HWPX로 변환 후 가져오는 흐름을 기준으로 합니다.

## 다음 추천 작업

1. Workbook / Vocabulary / Final Touch 통합 리포트
   - 학생별 학습 현황, 오답, 약점, 교재별 진행률을 한 화면에서 보는 리포트
2. `multi_subject_feature_shell_004`
   - 국어/수학/과학/입시컨설팅 과목별 feature shell과 준비 중 화면 연결
3. 국어 MVP 시작
   - 국어 자료 업로드, 지문/문항 관리, 학생 풀이 MVP
4. Teacher/Student 디자인 마감
   - 버튼/카드/상태 badge/반응형 레이아웃의 최종 디자인 통일

## 병합 전 확인 메모

- 이번 문서는 PR 병합 전 확인용이며, 앱 기능 코드는 변경하지 않습니다.
- Backend/API/DB 변경은 포함하지 않습니다.
- OpenAI/GPT 호출 기능 추가 또는 호출은 포함하지 않습니다.
