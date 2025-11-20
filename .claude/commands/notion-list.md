# /notion-list - 진행 중인 Notion 작업 목록

**Claude를 위한 필수 지시사항:**

이 명령어가 실행될 때 반드시 다음 단계를 **순서대로** 따라야 합니다:

1. `.claude/cache/active-tasks.json` 파일 확인
2. 작업 목록을 우선순위순으로 정렬하여 표시
3. 현재 활성 작업 표시 (★ 마크)
4. 다음 액션 제안

**절대로 active-tasks.json이 없으면 빈 목록으로 처리하세요.**

---

## Overview

현재 진행 중인 모든 Notion 작업을 우선순위순으로 표시합니다. 여러 기능을 동시에 추적하고 관리할 수 있습니다.

## Output Language

**IMPORTANT**: 사용자와의 모든 대화는 반드시 **한글로 작성**해야 합니다.

## Usage

```bash
/notion-list
/notion-list --summary  # 요약만 표시
```

### 옵션

| 옵션 | 설명 | 기본값 |
|------|------|--------|
| `--summary` | 통계 요약만 표시 | `false` |

## Workflow

### Step 1: Active Tasks 조회

**목적**: `.claude/cache/active-tasks.json`에서 모든 작업 로드

```bash
# 라이브러리 함수 사용
source .claude/lib/notion-active-tasks.sh

# 작업 목록 조회 (우선순위순 정렬)
tasks=$(list_active_tasks)

# 현재 활성 작업 ID
current_id=$(get_current_task)
```

### Step 2: 작업 목록 표시

**출력 형식**:

```
📋 진행 중인 작업 목록
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

★ P0  [개발중]   프로필 조회          (화주 - 회원 관리)
  P2  [대기]     주문 상태 조회        (화주 - 회원 관리)
  P1  [테스트중] 결제 내역 조회        (화주 - 결제)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 총 3개 작업

💡 작업 전환: /notion-switch
💡 다음 작업 추천: /notion-recommend
```

**표시 형식**:
- `★` = 현재 활성 작업
- 우선순위: P0, P1, P2, P3
- 상태: [대기], [개발중], [테스트중], [테스트완료] 등
- 제목: 기능 설명
- 메타: (채널 - 기능 그룹)

### Step 3: 통계 표시 (--summary 옵션)

**출력 형식**:

```
📊 작업 통계
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

우선순위별:
  P0: 1개 (론칭 필수)
  P1: 1개
  P2: 1개

상태별:
  대기: 1개
  개발중: 1개
  테스트중: 1개

채널별:
  화주: 3개
```

### Step 4: 다음 액션 제안

**조건별 제안**:

1. **작업이 없는 경우**:
```
ℹ️  진행 중인 작업이 없습니다.

다음 액션:
  - /notion-start: 새로운 작업 시작
  - /notion-add: 새로운 기능정의서 추가
```

2. **현재 작업이 없는 경우** (작업 목록은 있음):
```
⚠️  현재 활성 작업이 없습니다.

다음 액션:
  - /notion-switch: 작업 선택
  - /notion-recommend: 다음 작업 추천받기
```

3. **정상 상태**:
```
💡 다음 액션:
  - /notion-switch: 다른 작업으로 전환
  - /notion-recommend: 우선순위 기반 추천
  - /major, /minor, /micro: 현재 작업 계속
```

---

## Examples

### Example 1: 기본 사용

```bash
/notion-list
```

**Output:**
```
📋 진행 중인 Notion 작업 목록
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

★ P0  [개발중]   프로필 조회          (화주 - 회원 관리)
    시작: 2025-11-20
    최근 활동: 2025-11-20 14:30

  P2  [대기]     주문 상태 조회        (화주 - 회원 관리)
    시작: -
    최근 활동: -

  P1  [테스트중] 결제 내역 조회        (화주 - 결제)
    시작: 2025-11-19
    최근 활동: 2025-11-20 10:15

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 총 3개 작업

💡 다음 액션:
  - /notion-switch: 다른 작업으로 전환
  - /notion-recommend: 우선순위 기반 추천
```

### Example 2: 요약만 표시

```bash
/notion-list --summary
```

**Output:**
```
📊 작업 통계
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

총 작업: 3개
현재 활성: 프로필 조회 (P0)

우선순위별:
  P0: 1개 (33%)
  P1: 1개 (33%)
  P2: 1개 (33%)

상태별:
  대기: 1개
  개발중: 1개
  테스트중: 1개
```

### Example 3: 작업이 없는 경우

```bash
/notion-list
```

**Output:**
```
📋 진행 중인 Notion 작업 목록
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ℹ️  진행 중인 작업이 없습니다.

다음 액션:
  - /notion-start: 새로운 작업 시작
  - /notion-add: 새로운 기능정의서 추가
```

---

## Implementation

### 작업 목록 렌더링 로직

```bash
# active-tasks.json 읽기
tasks=$(list_active_tasks)
current_id=$(get_current_task)

# 각 작업 표시
echo "$tasks" | jq -r '.[] | @json' | while IFS= read -r task; do
  page_id=$(echo "$task" | jq -r '.page_id')
  title=$(echo "$task" | jq -r '.title')
  priority=$(echo "$task" | jq -r '.priority')
  status=$(echo "$task" | jq -r '.status')
  channel=$(echo "$task" | jq -r '.channel')
  feature_group=$(echo "$task" | jq -r '.feature_group')
  started_at=$(echo "$task" | jq -r '.started_at')
  last_active=$(echo "$task" | jq -r '.last_active')

  # 현재 작업 표시
  if [ "$page_id" == "$current_id" ]; then
    marker="★"
  else
    marker=" "
  fi

  # 우선순위 색상
  printf "%s %s  [%s]   %-20s  (%s - %s)\n" \
    "$marker" "$priority" "$status" "$title" "$channel" "$feature_group"

  # 상세 정보
  printf "    시작: %s\n" "$started_at"
  printf "    최근 활동: %s\n\n" "$last_active"
done
```

---

## Error Handling

### "active-tasks.json not found"
- **원인**: 아직 작업을 추가하지 않음
- **해결**: 빈 목록으로 처리, `/notion-start` 제안

### "Invalid JSON format"
- **원인**: active-tasks.json 파일 손상
- **해결**: 백업 파일 복구 또는 초기화

---

## Related Commands

- `/notion-start` - 새로운 작업 시작 (자동으로 active-tasks에 추가)
- `/notion-switch` - 작업 전환
- `/notion-recommend` - 다음 작업 추천

---

**Version**: 3.4.0
**Last Updated**: 2025-11-20
