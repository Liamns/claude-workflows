---
name: docu-switch
---

> **DEPRECATED**: 이 명령어는 `/docu`로 통합되었습니다. `/docu {기능명} 전환` 형태로 사용하세요.

# Docu:Switch - 작업 컨텍스트 전환

> **참고**: 이 명령어는 `.claude/CLAUDE.md`의 규칙을 준수합니다.

진행 중인 작업 간에 컨텍스트를 전환합니다.

## Critical Rules

1. **유효성 검사**: 존재하지 않는 작업 번호로 전환 불가
2. **상태 요약 필수**: 전환 후 현재 작업 정보 출력
3. **AskUserQuestion**: 인터랙티브 모드 또는 다음 단계 제안 시 사용

## Configuration

```bash
source .claude/lib/config-loader.sh
load_config "docu"

source .claude/lib/notion-active-tasks.sh

# Cache 파일
ACTIVE_TASKS=".claude/cache/active-tasks.json"
CURRENT_PAGE=".claude/cache/current-notion-page.txt"
```

## Usage

```bash
/docu-switch <N>              # N번 작업으로 전환
/docu-switch --interactive    # 목록에서 선택
/docu-switch --web            # 화주 채널 작업만 표시
/docu-switch --admin          # 어드민 채널 작업만 표시
```

### 채널 필터 옵션

| 옵션 | 설명 |
|------|------|
| `--web` | 화주 채널 작업만 표시 |
| `--admin` | 어드민 채널 작업만 표시 |
| (없음) | 전체 채널 표시 |

---

## Workflow: 기본 모드

### Step 1: 작업 목록 조회

```bash
source .claude/lib/notion-active-tasks.sh
tasks=$(list_active_tasks)
```

### Step 2: 유효성 검사

```bash
total=$(count_active_tasks)

if [ "$N" -gt "$total" ] || [ "$N" -lt 1 ]; then
  echo "❌ 유효하지 않은 작업 번호입니다. (1-$total)"
  exit 1
fi
```

### Step 3: 작업 전환

```bash
# N번째 작업의 page_id 추출
page_id=$(echo "$tasks" | jq -r ".[$((N-1))].page_id")

# 현재 작업으로 설정
set_current_task "$page_id"
```

### Step 4: 전환 결과 출력

```
✅ 작업 전환 완료!

📋 현재 작업
- 제목: {기능명}
- 채널: {채널}
- 우선순위: {Px}
- 상태: {진행현황}
- 시작일: {YYYY-MM-DD}
- 경과일: {N}일

💡 다음 명령어:
- '/triage' - 워크플로우 시작
- '/docu-update' - 상태 업데이트
- '/docu-close' - 작업 완료
```

### Step 5: 다음 단계 제안 (AskUserQuestion)

```
AskUserQuestion 도구 호출:
- question: "다음으로 무엇을 하시겠습니까?"
- header: "Action"
- options:
  - label: "/triage"
    description: "복잡도 분석 후 워크플로우 시작"
  - label: "/docu-update"
    description: "작업 상태 업데이트"
  - label: "계속 작업"
    description: "현재 세션에서 작업 진행"
```

---

## Workflow: --interactive 모드

목록을 보고 선택합니다.

### Step 1: 작업 목록 출력

```
📋 진행 중인 작업 ({N}개)

1. ★ [P0] 로그인 기능 개선 - 개발중 | 화주
2.   [P1] 회원가입 기능 - 대기 | 운송사
3.   [P2] 비밀번호 찾기 - 대기 | 화주

★ = 현재 활성 작업
```

### Step 2: 작업 선택 (AskUserQuestion)

```
AskUserQuestion 도구 호출:
- question: "어떤 작업으로 전환하시겠습니까?"
- header: "작업 선택"
- options:
  - label: "1. 로그인 기능 개선"
    description: "P0 | 개발중 | 화주"
  - label: "2. 회원가입 기능"
    description: "P1 | 대기 | 운송사"
  - label: "3. 비밀번호 찾기"
    description: "P2 | 대기 | 화주"
```

### Step 3-5: 전환 및 결과 출력

(기본 모드와 동일)

---

## 에러 처리

### 작업 없음

```
❌ 전환할 수 있는 작업이 없습니다.

💡 '/docu-start'로 새 작업을 시작하세요.
```

### 잘못된 번호

```
❌ 유효하지 않은 작업 번호입니다.

현재 등록된 작업: 3개 (1-3)
'/docu-list'로 목록을 확인하세요.
```

### 이미 현재 작업

```
ℹ️ 이미 해당 작업이 활성화되어 있습니다.

📋 현재 작업: 로그인 기능 개선 (P0, 개발중)
```

---

## 출력 예시

### 성공적인 전환

```
✅ 작업 전환 완료!

📋 현재 작업
- 제목: 회원가입 기능
- 채널: 운송사
- 우선순위: P1
- 상태: 대기
- 시작일: 2025-01-20
- 경과일: 6일

💡 다음 명령어:
- '/triage' - 워크플로우 시작
- '/docu-update "개발중"' - 상태 변경
```

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
| `/docu-close` | 작업 완료 |
| `/triage` | 워크플로우 시작 |
