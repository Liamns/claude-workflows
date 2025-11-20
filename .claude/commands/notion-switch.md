# /notion-switch - Notion 작업 전환

**Claude를 위한 필수 지시사항:**

이 명령어가 실행될 때 반드시 다음 단계를 **순서대로** 따라야 합니다:

1. `.claude/cache/active-tasks.json`에서 작업 목록 로드
2. AskUserQuestion으로 작업 선택
3. 선택한 작업으로 전환
4. `current-notion-page.txt` 업데이트
5. 작업 정보 표시

**절대로 사용자 확인 없이 작업을 전환하지 마세요.**

---

## Overview

진행 중인 여러 Notion 작업 사이를 전환합니다. AskUserQuestion을 통해 대화형으로 작업을 선택할 수 있습니다.

## Output Language

**IMPORTANT**: 사용자와의 모든 대화는 반드시 **한글로 작성**해야 합니다.

## Usage

```bash
/notion-switch
/notion-switch "프로필 조회"  # 기능명으로 직접 전환
```

### 옵션

| 옵션 | 설명 | 기본값 |
|------|------|--------|
| `기능명` | 전환할 기능명 (부분 매칭) | AskUserQuestion으로 선택 |

## Workflow

### Step 1: Active Tasks 조회

**목적**: 전환 가능한 작업 목록 확인

```bash
# 라이브러리 함수 사용
source .claude/lib/notion-active-tasks.sh

# 작업 목록 조회
tasks=$(list_active_tasks)
current_id=$(get_current_task)

# 작업 개수 확인
count=$(count_active_tasks)

if [ "$count" -eq 0 ]; then
  echo "ℹ️  전환할 작업이 없습니다."
  echo "💡 /notion-start로 새로운 작업을 시작하세요."
  exit 0
fi

if [ "$count" -eq 1 ]; then
  echo "ℹ️  작업이 1개뿐입니다."
  exit 0
fi
```

### Step 2: 작업 선택 (AskUserQuestion)

**목적**: 사용자가 전환할 작업 선택

**기능명이 제공된 경우**:
```bash
# 부분 매칭으로 작업 찾기
target_task=$(echo "$tasks" | jq --arg name "$1" '
  .[] | select(.title | contains($name))
' | head -1)

if [ -z "$target_task" ]; then
  echo "❌ '$1'과 일치하는 작업을 찾을 수 없습니다."
  echo "💡 /notion-list로 작업 목록을 확인하세요."
  exit 1
fi
```

**기능명이 없는 경우 (AskUserQuestion)**:
```json
{
  "questions": [
    {
      "question": "어떤 작업으로 전환할까요?",
      "header": "작업 전환",
      "multiSelect": false,
      "options": [
        {
          "label": "P0 프로필 조회 [개발중]",
          "description": "화주 - 회원 관리 (시작: 2025-11-20)"
        },
        {
          "label": "P2 주문 상태 조회 [대기]",
          "description": "화주 - 회원 관리"
        },
        {
          "label": "P1 결제 내역 조회 [테스트중]",
          "description": "화주 - 결제 (시작: 2025-11-19)"
        }
      ]
    }
  ]
}
```

**주의**: AskUserQuestion은 최대 4개 옵션만 지원하므로, 작업이 4개 이상이면:
1. 우선순위 높은 4개만 표시
2. 또는 여러 번 질문으로 분할

### Step 3: 작업 전환

**목적**: 선택한 작업으로 전환

```bash
# 선택한 작업 정보 추출
page_id=$(echo "$selected_task" | jq -r '.page_id')
title=$(echo "$selected_task" | jq -r '.title')

# 현재 작업 설정
set_current_task "$page_id"

echo "✅ 작업 전환 완료: $title"
```

### Step 4: 작업 정보 표시

**출력 형식**:

```
✅ 작업 전환 완료!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📄 기능명: 프로필 조회
🔗 Notion URL: https://www.notion.so/...
📊 우선순위: P0
📈 진행현황: 개발중
🏷️ 기능 그룹: 회원 관리
📱 채널: 화주

⏰ 시작: 2025-11-20
🕐 최근 활동: 2025-11-20 14:30

다음 단계:
  - /major, /minor, /micro: 워크플로우 시작
  - /notion-list: 전체 작업 목록 확인
```

### Step 5: Context 업데이트 (선택사항)

**작업 전환 시 컨텍스트 로드**:

```bash
# Notion 페이지 내용 미리 fetch (선택사항)
# 사용자가 바로 작업할 수 있도록 페이지 내용 표시

page_content=$(mcp__notion-company__notion-fetch --id "$page_id")

echo "📋 페이지 요약:"
echo "$page_content" | grep -A 3 "## 🎯 기능 목적"
```

---

## Examples

### Example 1: AskUserQuestion으로 선택

```bash
/notion-switch
```

**Output:**
```
🔄 작업 전환
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

현재: 프로필 조회 (P0 - 개발중)

[AskUserQuestion: 작업 선택]
옵션:
  - P2 주문 상태 조회 [대기]
  - P1 결제 내역 조회 [테스트중]

→ 선택: P2 주문 상태 조회

✅ 작업 전환 완료: 주문 상태 조회
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📄 기능명: 주문 상태 조회
📊 우선순위: P2
📈 진행현황: 대기
```

### Example 2: 기능명으로 직접 전환

```bash
/notion-switch "결제"
```

**Output:**
```
🔍 "결제"와 일치하는 작업 검색 중...

✅ 작업 전환 완료: 결제 내역 조회
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📄 기능명: 결제 내역 조회
📊 우선순위: P1
📈 진행현황: 테스트중
```

### Example 3: 전환할 작업이 없는 경우

```bash
/notion-switch
```

**Output:**
```
ℹ️  전환할 작업이 없습니다.

현재 작업: 프로필 조회 (유일)

💡 다음 액션:
  - /notion-start: 새로운 작업 시작
  - /major, /minor, /micro: 현재 작업 계속
```

---

## Implementation

### 작업 선택 옵션 생성

```bash
# active-tasks에서 현재 작업 제외한 옵션 생성
build_task_options() {
  local tasks="$1"
  local current_id="$2"

  echo "$tasks" | jq -r --arg current "$current_id" '
    map(select(.page_id != $current)) |
    .[0:4] |  # 최대 4개
    map({
      label: "\(.priority) \(.title) [\(.status)]",
      description: "\(.channel) - \(.feature_group)" +
                   (if .started_at then " (시작: \(.started_at))" else "" end)
    })
  '
}
```

### 작업 전환 로직

```bash
switch_task() {
  local page_id="$1"
  local title="$2"

  # current-notion-page.txt 업데이트
  set_current_task "$page_id"

  # active-tasks.json의 last_active 업데이트
  update_last_active "$page_id"

  echo "✅ 작업 전환 완료: $title"
}
```

---

## Error Handling

### "No active tasks found"
- **원인**: active-tasks.json이 비어있음
- **해결**: `/notion-start`로 첫 작업 시작

### "Only one task available"
- **원인**: 전환할 다른 작업이 없음
- **해결**: 현재 작업 유지, 필요시 `/notion-start`로 추가 작업 시작

### "Task not found"
- **원인**: 기능명으로 검색했으나 일치하는 작업 없음
- **해결**: `/notion-list`로 정확한 기능명 확인 후 재시도

---

## Related Commands

- `/notion-list` - 전체 작업 목록 확인
- `/notion-start` - 새로운 작업 시작
- `/notion-recommend` - 다음 작업 추천받기

---

**Version**: 3.4.0
**Last Updated**: 2025-11-20
