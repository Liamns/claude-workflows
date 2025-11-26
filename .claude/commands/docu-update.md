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
/docu-update              # 상태 선택 UI
/docu-update "개발중"      # 직접 상태 지정
/docu-update --log        # 작업 로그 조회
/docu-update --log --days 7  # 최근 7일 로그
```

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
