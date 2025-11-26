---
name: docu-close
hooks:
  pre: .claude/hooks/docu-close-pre.sh
  post: .claude/hooks/docu-close-post.sh
---

# Docu:Close - 작업 완료 처리 및 커밋 동기화

> **참고**: 이 명령어는 `.claude/CLAUDE.md`의 규칙을 준수합니다.

현재 작업을 완료 처리하고 커밋 내역을 Notion에 동기화합니다.

## Critical Rules

1. **활성 작업 필수**: 현재 활성 작업이 있어야 실행 가능
2. **완료 확인**: 완료 처리 전 사용자 확인 필수 (AskUserQuestion)
3. **다음 작업 제안**: 완료 후 `/docu-list --recommend` 제안

## Configuration

```bash
source .claude/lib/config-loader.sh
load_config "docu"

source .claude/lib/notion-active-tasks.sh
source .claude/lib/notion-utils.sh

# Cache 파일
ACTIVE_TASKS=".claude/cache/active-tasks.json"
PENDING_COMMITS=".claude/cache/pending-commits.json"
```

## Usage

```bash
/docu-close              # 완료 처리 + 커밋 동기화
/docu-close --sync-only  # 커밋 동기화만 (완료 처리 안 함)
/docu-close --keep-branch # 브랜치 유지
```

---

## Workflow: 기본 모드 (완료 처리)

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

### Step 2: 작업 정보 표시

```
📋 완료 처리할 작업

- 제목: {기능명}
- 채널: {채널}
- 우선순위: {Px}
- 시작일: {YYYY-MM-DD}
- 경과일: {N}일
```

### Step 3: 완료 확인 (AskUserQuestion)

```
AskUserQuestion 도구 호출:
- question: "이 작업을 완료 처리하시겠습니까?"
- header: "완료"
- options:
  - label: "완료 처리"
    description: "Notion 상태를 '완료'로 변경하고 목록에서 제거"
  - label: "동기화만"
    description: "커밋 내역만 동기화 (완료 처리 안 함)"
  - label: "취소"
    description: "작업 취소"
```

### Step 4: Pending Commits 동기화

```bash
# pending-commits.json 확인
if [ -f "$PENDING_COMMITS" ]; then
  commits=$(cat "$PENDING_COMMITS")

  # Notion 작업로그에 커밋 내역 추가
  sync_commits_to_notion "$current_id"

  # 캐시 클리어
  echo "[]" > "$PENDING_COMMITS"
fi
```

### Step 5: Notion 완료 처리

```bash
# KST 오늘 날짜
today=$(TZ='Asia/Seoul' date +%Y-%m-%d)

# Notion 페이지 업데이트
update_notion_page "$current_id" '{
  "진행현황": "완료",
  "완료일": "'"$today"'"
}'
```

또는 MCP 도구:
```
mcp__notion-company__notion-update-page
- page_id: {current_id}
- command: update_properties
- properties: {
    "진행현황": "완료",
    "date:완료일:start": "{today}",
    "date:완료일:is_datetime": 0
  }
```

### Step 6: Active Tasks에서 제거

```bash
remove_active_task "$current_id"
```

### Step 7: 결과 출력

```
✅ 작업 완료 처리됨!

📋 완료된 작업
- 제목: {기능명}
- 완료일: {YYYY-MM-DD}
- 총 소요일: {N}일

📝 동기화된 커밋: {M}개

💡 다음 작업을 시작하세요.
```

### Step 8: 다음 작업 제안 (AskUserQuestion)

```
AskUserQuestion 도구 호출:
- question: "다음으로 무엇을 하시겠습니까?"
- header: "다음"
- options:
  - label: "/docu-list --recommend"
    description: "다음 작업 추천 받기"
  - label: "/docu-start"
    description: "새 작업 검색"
  - label: "종료"
    description: "세션 종료"
```

---

## Workflow: --sync-only 모드

커밋 동기화만 수행하고 완료 처리하지 않습니다.

### Step 1-2: 작업 확인

(기본 모드와 동일)

### Step 3: Pending Commits 동기화

(기본 모드와 동일)

### Step 4: 결과 출력

```
✅ 커밋 동기화 완료!

📝 동기화된 커밋: {N}개
- feat: 로그인 UI 구현
- chore: SDK 설정
- docs: 명세 작성

💡 작업 상태: {현재 상태} (변경 없음)
```

### Step 5: 다음 단계 제안

```
AskUserQuestion 도구 호출:
- question: "다음으로 무엇을 하시겠습니까?"
- header: "Action"
- options:
  - label: "완료 처리"
    description: "/docu-close로 작업 완료"
  - label: "계속 작업"
    description: "현재 작업 계속"
  - label: "/docu-list"
    description: "작업 목록 확인"
```

---

## Workflow: --keep-branch 옵션

브랜치를 삭제하지 않고 유지합니다.

기본적으로 `/docu-close`는 브랜치를 삭제하지 않지만, 향후 브랜치 정리 기능이 추가될 경우 이 옵션으로 브랜치를 명시적으로 유지할 수 있습니다.

---

## Pending Commits 형식

`.claude/cache/pending-commits.json`:

```json
[
  {
    "hash": "abc1234",
    "message": "feat: 로그인 UI 구현",
    "date": "2025-01-26",
    "author": "user"
  },
  {
    "hash": "def5678",
    "message": "chore: SDK 설정",
    "date": "2025-01-25",
    "author": "user"
  }
]
```

---

## 에러 처리

### 활성 작업 없음

```
❌ 완료할 작업이 없습니다.

💡 '/docu-list'로 작업 목록을 확인하세요.
```

### Notion 업데이트 실패

```
⚠️ Notion 업데이트에 실패했습니다.

로컬에서는 작업이 제거되었습니다.
Notion 페이지를 수동으로 업데이트해주세요.
```

### 동기화할 커밋 없음

```
ℹ️ 동기화할 커밋이 없습니다.

pending-commits.json이 비어있습니다.
완료 처리만 진행합니다.
```

---

## 출력 예시

### 완료 처리 성공

```
✅ 작업 완료 처리됨!

📋 완료된 작업
- 제목: 로그인 기능 개선
- 완료일: 2025-01-26
- 총 소요일: 5일

📝 동기화된 커밋: 8개
- feat: 카카오 로그인 구현
- feat: 로그인 UI 완성
- fix: 토큰 갱신 버그 수정
- ...

💡 다음 작업을 시작하세요.
```

### 동기화만 완료

```
✅ 커밋 동기화 완료!

📝 동기화된 커밋: 3개
- feat: 로그인 UI 구현
- chore: SDK 설정
- docs: 명세 작성

💡 작업 상태: 개발중 (변경 없음)
```

---

## PostHook 조건

다음 조건 충족 시 성공:
- active-tasks.json에서 작업 제거됨 (기본 모드)
- 또는 pending-commits.json이 비워짐 (--sync-only 모드)

---

## Output Language

모든 출력은 **한글**로 작성합니다.

---

## 관련 명령어

| 명령어 | 설명 |
|--------|------|
| `/docu-list` | 작업 목록 확인 |
| `/docu-start` | 새 작업 시작 |
| `/docu-update` | 상태 업데이트 |
| `/docu-switch` | 작업 전환 |
