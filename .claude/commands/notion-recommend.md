# /notion-recommend - 우선순위 기반 작업 추천

**Claude를 위한 필수 지시사항:**

이 명령어가 실행될 때 반드시 다음 단계를 **순서대로** 따라야 합니다:

1. `.claude/cache/active-tasks.json`에서 작업 목록 로드
2. 추천 로직 실행 (우선순위 기반)
3. 추천 작업 정보 표시
4. 추천 이유 설명
5. AskUserQuestion으로 액션 선택

**절대로 사용자 확인 없이 작업을 전환하지 마세요.**

---

## Overview

우선순위 기반으로 다음에 작업할 기능을 추천합니다. 여러 작업을 효율적으로 관리할 수 있도록 돕습니다.

## Output Language

**IMPORTANT**: 사용자와의 모든 대화는 반드시 **한글로 작성**해야 합니다.

## Usage

```bash
/notion-recommend
```

## Workflow

### Step 1: 추천 로직 실행

**목적**: 우선순위 기반으로 다음 작업 찾기

**추천 우선순위**:
1. **론칭 필수 (P0)** - 최우선
2. **중요 (P1)** - 두 번째
3. **필요 (P2)** - 세 번째
4. **선택 (P3)** - 마지막

**같은 우선순위 내에서**:
1. **상태**: 대기 > 개발중 > 테스트중
2. **기능 그룹**: 현재 작업과 같은 그룹 우선
3. **채널**: 현재 작업과 같은 채널 우선

```bash
# 라이브러리 함수 사용
source .claude/lib/notion-active-tasks.sh

# 추천 작업 조회
recommended=$(recommend_next_task)

if [ -z "$recommended" ] || [ "$recommended" == "null" ]; then
  echo "ℹ️  추천할 작업이 없습니다."
  echo "💡 모든 작업이 완료되었거나 작업 목록이 비어있습니다."
  exit 0
fi
```

### Step 2: 추천 이유 생성

**목적**: 왜 이 작업을 추천하는지 명확히 설명

```bash
# 추천 이유 생성 로직
generate_recommendation_reason() {
  local recommended="$1"
  local current="$2"

  local priority=$(echo "$recommended" | jq -r '.priority')
  local status=$(echo "$recommended" | jq -r '.status')
  local feature_group=$(echo "$recommended" | jq -r '.feature_group')
  local channel=$(echo "$recommended" | jq -r '.channel')

  local reasons=()

  # 우선순위 기반 이유
  case "$priority" in
    "P0")
      reasons+=("⭐ 론칭 필수 기능입니다")
      ;;
    "P1")
      reasons+=("🎯 중요도가 높은 기능입니다")
      ;;
    "P2")
      reasons+=("📌 구현이 필요한 기능입니다")
      ;;
  esac

  # 상태 기반 이유
  case "$status" in
    "대기")
      reasons+=("🆕 아직 시작하지 않은 작업입니다")
      ;;
    "개발중")
      reasons+=("⚡ 이미 진행 중인 작업으로 연속성이 좋습니다")
      ;;
    "테스트중")
      reasons+=("🏁 완료가 임박한 작업입니다")
      ;;
  esac

  # 기능 그룹 일치
  if [ -n "$current" ]; then
    local current_group=$(echo "$current" | jq -r '.feature_group')
    if [ "$feature_group" == "$current_group" ]; then
      reasons+=("🔗 현재 작업과 같은 기능 그룹($feature_group)입니다")
    fi
  fi

  # 이유 출력
  for reason in "${reasons[@]}"; do
    echo "  - $reason"
  done
}
```

### Step 3: 추천 정보 표시

**출력 형식**:

```
🎯 다음 작업 추천
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📄 기능명: 결제 내역 조회
📊 우선순위: P1
📈 진행현황: 대기
🏷️ 기능 그룹: 결제
📱 채널: 화주

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🤔 추천 이유:
  - 🎯 중요도가 높은 기능입니다
  - 🆕 아직 시작하지 않은 작업입니다
  - ⚠️ P0 작업은 모두 완료되었습니다

💡 다음 액션을 선택하세요
```

### Step 4: 액션 선택 (AskUserQuestion)

**목적**: 사용자가 추천 작업을 시작할지 결정

```json
{
  "questions": [
    {
      "question": "이 작업으로 전환할까요?",
      "header": "작업 시작",
      "multiSelect": false,
      "options": [
        {
          "label": "작업 시작",
          "description": "이 작업으로 전환하고 워크플로우 시작"
        },
        {
          "label": "작업만 전환",
          "description": "워크플로우 없이 작업만 전환"
        },
        {
          "label": "다른 작업 선택",
          "description": "/notion-switch로 직접 선택"
        },
        {
          "label": "나중에",
          "description": "현재 작업 유지"
        }
      ]
    }
  ]
}
```

### Step 5: 선택에 따른 액션 실행

**분기 처리**:

```bash
case "$user_choice" in
  "작업 시작")
    # 작업 전환 + /notion-start 실행
    set_current_task "$page_id"
    echo "✅ 작업 전환 완료: $title"
    echo ""
    echo "🚀 워크플로우를 시작합니다..."
    # /notion-start 자동 실행 (필요 시)
    ;;

  "작업만 전환")
    # 작업 전환만
    set_current_task "$page_id"
    echo "✅ 작업 전환 완료: $title"
    echo "💡 /major, /minor, /micro로 워크플로우를 시작하세요"
    ;;

  "다른 작업 선택")
    # /notion-switch 실행
    echo "🔄 작업 선택 화면으로 이동합니다..."
    # /notion-switch 실행
    ;;

  "나중에")
    echo "ℹ️ 현재 작업을 계속 진행합니다"
    ;;
esac
```

---

## Examples

### Example 1: P0 작업 추천

```bash
/notion-recommend
```

**Output:**
```
🎯 다음 작업 추천
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📄 기능명: 사용자 인증
📊 우선순위: P0 (론칭 필수)
📈 진행현황: 대기
🏷️ 기능 그룹: 인증
📱 채널: 화주

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🤔 추천 이유:
  - ⭐ 론칭 필수 기능입니다
  - 🆕 아직 시작하지 않은 작업입니다
  - 🔥 가장 높은 우선순위 작업입니다

[AskUserQuestion: 작업 시작]
→ 선택: 작업 시작

✅ 작업 전환 완료: 사용자 인증
🚀 /major 워크플로우를 시작할까요?
```

### Example 2: 같은 기능 그룹 추천

```bash
/notion-recommend
```

**Output:**
```
🎯 다음 작업 추천
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

현재 작업: 결제하기 (결제)

📄 추천: 결제 내역 조회
📊 우선순위: P1
📈 진행현황: 대기
🏷️ 기능 그룹: 결제

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🤔 추천 이유:
  - 🎯 중요도가 높은 기능입니다
  - 🔗 현재 작업과 같은 기능 그룹(결제)입니다
  - ⚡ 연관 기능을 연속으로 작업하면 효율적입니다
```

### Example 3: 추천할 작업이 없는 경우

```bash
/notion-recommend
```

**Output:**
```
🎉 축하합니다!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ℹ️  추천할 작업이 없습니다.

현재 상태:
  - 진행 중인 작업: 1개
  - 다른 대기 작업 없음

💡 다음 액션:
  - /notion-add: 새로운 기능정의서 추가
  - /major, /minor, /micro: 현재 작업 계속
  - /notion-list: 전체 작업 상태 확인
```

---

## Implementation

### 추천 로직 알고리즘

```bash
recommend_next_task() {
  local tasks="$1"
  local current_id="$2"

  # 1. 현재 작업 제외
  local candidates=$(echo "$tasks" | jq --arg current "$current_id" '
    map(select(.page_id != $current))
  ')

  # 2. 우선순위 점수 계산
  local scored=$(echo "$candidates" | jq '
    map(. + {
      score: (
        # 우선순위 점수 (P0=100, P1=75, P2=50, P3=25)
        (if .priority == "P0" then 100
         elif .priority == "P1" then 75
         elif .priority == "P2" then 50
         elif .priority == "P3" then 25
         else 0 end)
        +
        # 상태 점수 (대기=30, 개발중=20, 테스트중=10)
        (if .status == "대기" then 30
         elif .status == "개발중" then 20
         elif .status == "테스트중" then 10
         else 0 end)
      )
    })
  ')

  # 3. 점수순 정렬 후 첫 번째 반환
  echo "$scored" | jq 'sort_by(-.score) | .[0]'
}
```

---

## Error Handling

### "No tasks to recommend"
- **원인**: 모든 작업 완료 또는 작업 목록 비어있음
- **해결**: `/notion-add`로 새 작업 추가 제안

### "All P0 tasks completed"
- **원인**: 론칭 필수 작업 모두 완료
- **해결**: P1 작업 추천, 축하 메시지 표시

---

## Related Commands

- `/notion-list` - 전체 작업 목록 확인
- `/notion-switch` - 직접 작업 선택
- `/notion-start` - 추천된 작업으로 바로 시작

---

**Version**: 3.4.0
**Last Updated**: 2025-11-20
