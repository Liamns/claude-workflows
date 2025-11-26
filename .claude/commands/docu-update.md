---
name: docu-update
---

# Docu:Update - 작업 상태 업데이트 및 로그 조회

> **참고**: 이 명령어는 `.claude/CLAUDE.md`의 규칙을 준수합니다.

현재 활성 작업의 상태를 업데이트하거나 작업 로그를 조회합니다.

## Critical Rules

1. **현재 작업 필수**: 활성 작업이 없으면 실행 불가
2. **Notion 동기화**: 상태 변경 시 Notion과 로컬 캐시 모두 업데이트
3. **AskUserQuestion**: 상태 선택 및 다음 단계 제안 시 사용

## Configuration

```bash
source .claude/lib/config-loader.sh
load_config "docu"

source .claude/lib/notion-active-tasks.sh
source .claude/lib/notion-utils.sh

# Cache 파일
ACTIVE_TASKS=".claude/cache/active-tasks.json"
```

## Usage

```bash
/docu-update                    # 상태 선택 UI (현재 작업)
/docu-update "개발중"            # 직접 상태 지정
/docu-update --web              # 화주 채널 작업만 대상
/docu-update --admin            # 어드민 채널 작업만 대상
/docu-update --log              # 작업 로그 조회
/docu-update --log --days 7     # 최근 7일 로그
/docu-update --today            # 오늘 커밋 기반 작업 로그 자동 업데이트
```

### 옵션 설명

| 옵션 | 설명 |
|------|------|
| `--web` | 화주 채널 작업만 대상으로 지정 |
| `--admin` | 어드민 채널 작업만 대상으로 지정 |
| `--today` | 오늘 Git 커밋을 분석하여 해당 기능의 '작업 로그'에 자동 기록 |
| `--log` | 작업 로그 조회 |

---

## Workflow: 상태 업데이트

### Step 1: 현재 작업 확인

```bash
source .claude/lib/notion-active-tasks.sh
current_id=$(get_current_task)

if [ -z "$current_id" ]; then
  echo "❌ 활성 작업이 없습니다."
  exit 1
fi

task_info=$(get_task_info "$current_id")
```

### Step 2: 현재 상태 표시

```
📋 현재 작업
- 제목: {기능명}
- 상태: {현재 상태}
- 우선순위: {Px}
```

### Step 3: 상태 선택 (AskUserQuestion)

직접 상태를 지정하지 않은 경우:

```
AskUserQuestion 도구 호출:
- question: "어떤 상태로 변경하시겠습니까?"
- header: "상태"
- options:
  - label: "대기"
    description: "작업 일시 중단"
  - label: "개발중"
    description: "현재 개발 진행 중"
  - label: "테스트중"
    description: "개발 완료, 테스트 진행 중"
  - label: "완료"
    description: "작업 완료 (docu-close 권장)"
```

### Step 4: Notion 업데이트

```bash
source .claude/lib/notion-utils.sh

# Notion 페이지 업데이트
update_notion_page "$current_id" '{"진행현황": "'"$new_status"'"}'
```

또는 MCP 도구 사용:
```
mcp__notion-company__notion-update-page
- page_id: {current_id}
- command: update_properties
- properties: {"진행현황": "{new_status}"}
```

### Step 5: 로컬 캐시 동기화

```bash
# active-tasks.json 업데이트
add_active_task "$current_id" "$title" "$priority" "$new_status" "$channel" "$feature_group"
```

### Step 6: 결과 출력

```
✅ 상태 업데이트 완료!

📋 {기능명}
- 이전: {이전 상태}
- 현재: {새 상태}

💡 Notion 페이지도 업데이트되었습니다.
```

### Step 6.5: 작업 로그 서브페이지 확인/생성

상태 업데이트 후 '작업 로그' 서브페이지를 확인하고 없으면 생성합니다.

```bash
# 1. 페이지 내용 조회
mcp__notion-personal__notion-fetch id="$current_id"

# 2. '작업 로그' 서브페이지 존재 여부 확인
#    → fetch 결과에서 <page>작업 로그</page> 검색

# 3. 미존재 시 생성
```

**서브페이지 생성 (미존재 시):**
```
mcp__notion-personal__notion-update-page
- page_id: {current_id}
- command: insert_content_after
- selection_with_ellipsis: "(페이지 마지막 콘텐츠)..."
- new_str: |
    ---

    <page>작업 로그</page>
```

**서브페이지 내용 초기화 (새로 생성된 경우):**
```markdown
# 작업 로그

| 커밋ID | 핵심작업내용 | 작업날짜 |
|--------|-------------|----------|
```

**에러 핸들링:**
```
Notion API 실패 시:
1. 재시도: 최대 2회 (딜레이 1초)
2. 재시도 실패 시:
   - 로컬 캐시에 저장: .claude/cache/pending-work-logs.json
   - 안내: "Notion 연결 실패. 나중에 '/docu-update --sync'로 동기화하세요."
3. Rate Limit (429): 3초 대기 후 재시도
```

### Step 7: 다음 단계 제안 (AskUserQuestion)

"완료" 상태로 변경한 경우:
```
AskUserQuestion 도구 호출:
- question: "작업을 완료 처리하시겠습니까?"
- header: "완료"
- options:
  - label: "/docu-close"
    description: "완료 처리 및 커밋 동기화"
  - label: "나중에"
    description: "상태만 변경하고 종료"
```

다른 상태인 경우:
```
AskUserQuestion 도구 호출:
- question: "다음으로 무엇을 하시겠습니까?"
- header: "Action"
- options:
  - label: "/triage"
    description: "워크플로우 시작/계속"
  - label: "/docu-list"
    description: "작업 목록 확인"
  - label: "계속 작업"
    description: "현재 세션에서 작업"
```

---

## Workflow: --log 모드

작업 로그를 조회합니다.

### Step 1: 로그 수집

```bash
# 커밋 이력 조회
days=${DAYS:-7}
git log --since="$days days ago" --oneline | head -20

# Notion 작업로그 서브페이지 조회 (있는 경우)
```

### Step 2: 로그 출력

```
📜 작업 로그 (최근 {N}일)

현재 작업: {기능명}

🔨 커밋 이력
- 2025-01-26: feat: 로그인 UI 구현
- 2025-01-25: chore: 카카오 SDK 설정
- 2025-01-24: docs: 기능 명세 작성

📝 Notion 메모
- 2025-01-26: API 연동 진행 중
- 2025-01-24: 디자인 검토 완료
```

### Step 3: 다음 단계 제안

```
AskUserQuestion 도구 호출:
- question: "다음으로 무엇을 하시겠습니까?"
- header: "Action"
- options:
  - label: "상태 업데이트"
    description: "진행현황 변경"
  - label: "/docu-close"
    description: "작업 완료 처리"
  - label: "돌아가기"
    description: "작업 계속"
```

---

## 상태 옵션

| 상태 | 설명 | Notion 값 |
|------|------|-----------|
| 대기 | 작업 일시 중단, 우선순위 낮음 | "대기" |
| 개발중 | 현재 개발 진행 중 | "개발중" |
| 테스트중 | 개발 완료, 테스트 진행 | "테스트중" |
| 완료 | 작업 완료 (docu-close 권장) | "완료" |

---

## 에러 처리

### 활성 작업 없음

```
❌ 활성 작업이 없습니다.

💡 먼저 작업을 시작하세요:
- '/docu-start' - 기능 검색 후 시작
- '/docu-list' - 기존 작업 확인
```

### Notion 업데이트 실패

```
⚠️ Notion 업데이트에 실패했습니다.

로컬 상태는 업데이트되었습니다.
나중에 '/docu-update'로 다시 시도하세요.
```

---

## 출력 예시

### 상태 업데이트 성공

```
✅ 상태 업데이트 완료!

📋 로그인 기능 개선
- 이전: 대기
- 현재: 개발중

💡 Notion 페이지도 업데이트되었습니다.
```

### 로그 조회

```
📜 작업 로그 (최근 7일)

현재 작업: 로그인 기능 개선

🔨 커밋 이력 (5개)
- 2025-01-26: feat: 카카오 로그인 버튼 추가
- 2025-01-25: feat: 로그인 화면 UI 구현
- 2025-01-24: chore: 카카오 SDK 설정
- 2025-01-23: docs: 로그인 기능 명세 작성
- 2025-01-22: init: 프로젝트 초기 설정

💡 다음 액션을 선택하세요.
```

---

## Workflow: --today 모드

오늘 Git 커밋을 분석하여 해당하는 기능의 '작업 로그'에 자동으로 기록합니다.

### Step 1: 커밋 없음 확인

```bash
commit_count=$(git log --since="today 00:00" --oneline | wc -l)
```

**커밋이 0개인 경우:**
```
AskUserQuestion 도구 호출:
- question: "오늘 커밋이 없습니다. 다른 날짜 범위를 선택하시겠습니까?"
- header: "날짜"
- options:
  - label: "어제 커밋"
    description: "--since='yesterday 00:00'"
  - label: "이번 주"
    description: "--since='1 week ago'"
  - label: "취소"
    description: "명령어 종료"
```

### Step 2: 작업자 확인

```bash
git log --since="today 00:00" --format="%an" | sort -u
```

**작업자가 2명 이상인 경우:**
```
AskUserQuestion 도구 호출:
- question: "오늘 여러 작업자의 커밋이 있습니다. 어떤 작업자의 내용을 정리하시겠습니까?"
- header: "작업자"
- options:
  - label: "{작업자1}"
    description: "{N}개 커밋"
  - label: "{작업자2}"
    description: "{M}개 커밋"
  - label: "전체"
    description: "모든 작업자 ({총합}개 커밋)"
```

### Step 3: Git 커밋 수집

```bash
git log --since="today 00:00" --author="$author" --format="%h|%s|%ad" --date=short
```

### Step 4: 기능 매칭 알고리즘

각 커밋에 대해:

```
우선순위 1: Conventional Commit scope 추출
- 패턴: /^(feat|fix|refactor|chore)\(([^)]+)\):/
- 예: "feat(login): 버튼 추가" → scope = "login"

우선순위 2: active-tasks.json 퍼지 매칭
- 기능명을 토큰화하여 scope와 비교
- 임계값: 70% 이상 유사도

우선순위 3: Notion 검색
- scope 키워드로 기능 명세서 검색

우선순위 4: 사용자 선택 (매칭 실패 시)
- AskUserQuestion으로 후보 기능 목록 제시
- "새 기능으로 등록" 옵션 포함
- "건너뛰기" 옵션 포함
```

### Step 5: 작업 로그 업데이트

매칭된 각 기능에 대해:

1. **'작업 로그' 서브페이지 확인**
   - 없으면 Step 6.5 로직으로 생성

2. **중복 방지 확인**
   ```
   기존 작업 로그 표에서 커밋ID 검색
   - 중복 시: 스킵, "[스킵] 이미 등록된 커밋: {커밋ID}" 출력
   ```

3. **표에 행 추가**
   ```
   mcp__notion-personal__notion-update-page
   - page_id: {작업로그_page_id}
   - command: replace_content_range
   - selection_with_ellipsis: "|--------|...----------|"
   - new_str: |
       |--------|-------------|----------|
       | {커밋ID} | {핵심작업내용} | {작업날짜} |
   ```

### Step 6: 결과 출력

```
✅ 오늘 작업 로그 업데이트 완료!

📊 처리 결과
- 분석된 커밋: {N}개
- 매칭된 기능: {M}개
- 업데이트된 로그: {K}개
- 스킵 (중복): {S}개

📝 업데이트된 기능:
- 로그인 기능: 2개 커밋 추가
- 회원가입: 1개 커밋 추가

💡 '/docu-list'로 전체 작업 현황을 확인하세요.
```

---

## Output Language

모든 출력은 **한글**로 작성합니다.

---

## 관련 명령어

| 명령어 | 설명 |
|--------|------|
| `/docu-list` | 작업 목록 확인 |
| `/docu-switch` | 작업 전환 |
| `/docu-close` | 작업 완료 처리 |
| `/docu-start` | 새 작업 시작 |
