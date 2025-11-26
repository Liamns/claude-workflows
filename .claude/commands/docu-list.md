---
name: docu-list
---

# Docu:List - 진행 중인 작업 목록 및 추천

> **참고**: 이 명령어는 `.claude/CLAUDE.md`의 규칙을 준수합니다.

진행 중인 Notion 작업 목록을 표시하고 다음 작업을 추천합니다.

## Critical Rules

1. **AskUserQuestion 필수**: 다음 액션 제안 시 반드시 사용
2. **출력 형식 준수**: 정해진 형식으로 목록 출력
3. **다음 단계 제안**: 목록 출력 후 액션 제안 필수

## Configuration

```bash
source .claude/lib/config-loader.sh
load_config "docu"

source .claude/lib/notion-active-tasks.sh

# Cache 파일
ACTIVE_TASKS=".claude/cache/active-tasks.json"
```

## Usage

```bash
/docu-list                    # 기본 목록 (전체 채널)
/docu-list --web              # 화주 채널만 표시
/docu-list --admin            # 어드민 채널만 표시
/docu-list --recommend        # 다음 작업 추천 포함
/docu-list --summary          # 요약 형식
```

### 채널 필터 옵션

| 옵션 | 설명 |
|------|------|
| `--web` | 화주 채널 작업만 표시 |
| `--admin` | 어드민 채널 작업만 표시 |
| (없음) | 전체 채널 표시 |

---

## Workflow: 기본 모드

### Step 1: Active Tasks 조회

```bash
source .claude/lib/notion-active-tasks.sh
list_active_tasks
```

### Step 2: 목록 출력

```
📋 진행 중인 작업 ({N}개)

★ [P0] 로그인 기능 개선 - 개발중 (3일차) | 화주
   [P1] 회원가입 기능 - 대기 | 운송사
   [P2] 비밀번호 찾기 - 대기 | 화주

★ = 현재 활성 작업
```

**출력 형식**:
- `★` 현재 활성 작업 표시
- `[Px]` 우선순위
- `기능명` 제목
- `상태` 진행현황 (대기/개발중/테스트중)
- `(N일차)` 시작일로부터 경과일
- `채널` 화주/운송사/기사앱

### Step 3: 다음 액션 제안 (AskUserQuestion)

```
AskUserQuestion 도구 호출:
- question: "다음으로 무엇을 하시겠습니까?"
- header: "Action"
- options:
  - label: "/docu-switch N"
    description: "N번 작업으로 전환"
  - label: "/docu-start"
    description: "새 작업 시작"
  - label: "/docu-update"
    description: "현재 작업 상태 업데이트"
```

---

## Workflow: --recommend 모드

기본 목록 + 다음 작업 추천

### Step 1-2: 기본 목록 출력

(기본 모드와 동일)

### Step 3: 추천 작업 계산

```bash
recommend_next_task
```

추천 로직:
1. 현재 작업이 아닌 것
2. P0 우선
3. 같은 우선순위면 "대기" 상태 우선

### Step 4: 추천 출력

```
💡 추천 작업

[P0] 회원가입 기능 - 대기 | 운송사
→ 우선순위가 높은 대기 중인 작업입니다.

'/docu-switch 2'로 전환하세요.
```

### Step 5: 다음 액션 제안 (AskUserQuestion)

```
AskUserQuestion 도구 호출:
- question: "추천 작업으로 전환하시겠습니까?"
- header: "전환"
- options:
  - label: "전환"
    description: "추천 작업으로 바로 전환"
  - label: "다른 작업"
    description: "다른 작업 선택"
  - label: "유지"
    description: "현재 작업 계속"
```

---

## Workflow: --summary 모드

간결한 요약 형식 출력

### Step 1: 통계 계산

```bash
total=$(count_active_tasks)
in_progress=$(count_tasks_by_status "개발중")
waiting=$(count_tasks_by_status "대기")
p0_count=$(count_tasks_by_priority "P0")
```

### Step 2: 요약 출력

```
📊 작업 현황

전체: {N}개
├── 개발중: {X}개
└── 대기: {Y}개

우선순위
├── P0: {A}개
├── P1: {B}개
└── P2: {C}개

★ 현재: 로그인 기능 개선 (P0, 개발중)
```

### Step 3: 다음 액션 제안

(기본 모드와 동일)

---

## 작업 없음 처리

활성 작업이 없을 경우:

```
📋 진행 중인 작업 (0개)

등록된 작업이 없습니다.

💡 '/docu-start'로 새 작업을 시작하세요.
```

```
AskUserQuestion 도구 호출:
- question: "새 작업을 시작하시겠습니까?"
- header: "시작"
- options:
  - label: "/docu-start"
    description: "Notion에서 기능 검색 후 시작"
  - label: "/docu-start --add"
    description: "새 기능정의서 추가"
  - label: "취소"
    description: "세션 종료"
```

---

## 출력 예시

### 기본 목록

```
📋 진행 중인 작업 (3개)

★ [P0] 로그인 기능 개선 - 개발중 (3일차) | 화주
   [P1] 회원가입 기능 - 대기 | 운송사
   [P2] 비밀번호 찾기 - 대기 | 화주

★ = 현재 활성 작업

💡 다음 액션을 선택하세요.
```

### --recommend 포함

```
📋 진행 중인 작업 (3개)

★ [P0] 로그인 기능 개선 - 개발중 (3일차) | 화주
   [P1] 회원가입 기능 - 대기 | 운송사
   [P2] 비밀번호 찾기 - 대기 | 화주

💡 추천 작업
[P1] 회원가입 기능 - 대기 | 운송사
→ 다음 우선순위 작업입니다.

💡 전환하시겠습니까?
```

### --summary

```
📊 작업 현황

전체: 3개
├── 개발중: 1개
└── 대기: 2개

우선순위
├── P0: 1개
├── P1: 1개
└── P2: 1개

★ 현재: 로그인 기능 개선 (P0, 개발중)
```

---

## Output Language

모든 출력은 **한글**로 작성합니다.

---

## 관련 명령어

| 명령어 | 설명 |
|--------|------|
| `/docu-start` | 새 작업 시작 |
| `/docu-switch` | 작업 전환 |
| `/docu-update` | 상태 업데이트 |
| `/docu-close` | 작업 완료 |
