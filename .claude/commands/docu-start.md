---
name: docu-start
hooks:
  pre: .claude/hooks/docu-start-pre.sh
  post: .claude/hooks/docu-start-post.sh
---

# Docu:Start - Notion 기능 명세서 기반 작업 시작

> **참고**: 이 명령어는 `.claude/CLAUDE.md`의 규칙을 준수합니다.

Notion 기능 명세서 데이터베이스에서 기능을 검색하고 작업을 시작합니다.

## Critical Rules

1. **AskUserQuestion 필수**: 기능 선택, Notion 업데이트 확인 시 반드시 사용
2. **구현 금지**: 이 명령어는 작업 시작만 담당 (코드 작성 안 함)
3. **다음 단계 제안**: 완료 후 `/triage` 또는 `/docu-list` 제안 필수

## Configuration

```bash
source .claude/lib/config-loader.sh
load_config "docu"

# Data Source IDs
HWAJU_DS="2ac47c08-6985-811b-a177-000b9ea43547"
UNSONGSA_DS="2ae47c08-6985-8179-bac0-e3bdda9c304d"

# Cache 파일
ACTIVE_TASKS=".claude/cache/active-tasks.json"
```

## Usage

```bash
/docu-start [keyword]              # 키워드로 검색 후 작업 시작 (채널 선택 필요)
/docu-start --web [keyword]        # 화주 데이터베이스에서 검색
/docu-start --admin [keyword]      # 어드민 데이터베이스에서 검색
/docu-start --add [name]           # 새 기능정의서 추가
/docu-start --search [query]       # 검색만 (작업 시작 안 함)
```

### 채널 옵션

| 옵션 | 데이터베이스 | 설명 |
|------|-------------|------|
| `--web` | hwaju | 화주 앱 기능 명세서 |
| `--admin` | admin | 어드민 WEB 기능정의서 |
| (없음) | - | AskUserQuestion으로 선택 |

## Workflow: 기본 모드

### Step 0: 채널 선택 (옵션 미입력 시)

`--web` 또는 `--admin` 옵션이 없으면 AskUserQuestion으로 채널 선택:

```
AskUserQuestion 도구 호출:
- question: "어떤 채널에서 작업하시겠습니까?"
- header: "채널"
- options:
  - label: "화주 (--web)"
    description: "화주 앱 기능 명세서"
  - label: "어드민 (--admin)"
    description: "어드민 WEB 기능정의서"
```

선택에 따라 데이터 소스 결정:
```bash
# 화주 선택 시
ds_id="2ac47c08-6985-811b-a177-000b9ea43547"

# 어드민 선택 시
ds_id="35d8c49c-a343-4bb4-a62a-8a418b8abca5"
```

### Step 1: Notion 검색

키워드로 기능 명세서 데이터베이스 검색 (선택된 채널에서):

```bash
source .claude/lib/notion-utils.sh
search_notion_features "$keyword"
```

또는 MCP 도구 사용:
- `mcp__notion-company__notion-search` 로 검색

### Step 2: 기능 선택 (AskUserQuestion)

```
AskUserQuestion 도구 호출:
- question: "어떤 기능을 작업하시겠습니까?"
- header: "Feature"
- options:
  - label: "기능명1"
    description: "P0 | 대기 | 화주"
  - label: "기능명2"
    description: "P1 | 개발중 | 운송사"
  - (최대 4개)
```

### Step 3: 템플릿 파싱

선택된 기능 페이지에서 정보 추출:
- 기능 목적
- 비즈니스 로직
- 체크리스트
- 연관 기능

### Step 4: Notion 업데이트 확인 (AskUserQuestion)

```
AskUserQuestion 도구 호출:
- question: "Notion 페이지를 업데이트하시겠습니까?"
- header: "Notion"
- options:
  - label: "업데이트"
    description: "시작일, 진행현황을 '개발중'으로 변경"
  - label: "스킵"
    description: "Notion 업데이트 없이 진행"
```

업데이트 시:
- 시작일: KST 오늘 날짜
- 진행현황: "개발중"

### Step 5: Active Tasks 저장

```bash
source .claude/lib/notion-active-tasks.sh
add_active_task "$page_id" "$feature_name" "$priority" "개발중" "$channel" "$feature_group"
```

### Step 6: 다음 단계 제안 (AskUserQuestion)

```
AskUserQuestion 도구 호출:
- question: "다음으로 무엇을 하시겠습니까?"
- header: "다음 단계"
- options:
  - label: "/triage 실행"
    description: "복잡도 분석 후 적절한 워크플로우 시작"
  - label: "/docu-list"
    description: "진행 중인 작업 목록 확인"
  - label: "나중에"
    description: "현재 세션 종료"
```

---

## Workflow: --add 모드

새 기능정의서를 Notion에 추가합니다.

### Step 1: 유사 기능 검색

```bash
search_notion_features "$feature_name"
```

### Step 2: 중복 확인 (AskUserQuestion)

유사 기능 발견 시:
```
AskUserQuestion 도구 호출:
- question: "유사한 기능이 발견되었습니다. 어떻게 하시겠습니까?"
- header: "중복 확인"
- options:
  - label: "기존 기능 수정"
    description: "선택한 기존 기능으로 이동"
  - label: "새로 추가"
    description: "새 기능정의서 생성"
  - label: "취소"
    description: "작업 취소"
```

### Step 3: 필수 정보 수집 (AskUserQuestion)

```
AskUserQuestion #1:
- question: "어떤 채널의 기능입니까?"
- header: "채널"
- options: 화주, 운송사, 기사앱, 공통

AskUserQuestion #2:
- question: "우선순위를 선택하세요"
- header: "Priority"
- options: P0 (긴급), P1 (높음), P2 (보통), P3 (낮음)
```

### Step 4: 페이지 생성

```bash
# Data Source ID 선택
if [ "$channel" = "화주" ]; then
  ds_id="$HWAJU_DS"
else
  ds_id="$UNSONGSA_DS"
fi

# MCP 도구로 페이지 생성
mcp__notion-company__notion-create-pages
```

### Step 5: 결과 출력

```
✅ 기능정의서 생성 완료!

- 제목: {기능명}
- 채널: {채널}
- 우선순위: {priority}
- URL: {notion_url}

💡 '/docu-start {기능명}'으로 작업을 시작하세요.
```

---

## Workflow: --search 모드

검색만 수행하고 작업은 시작하지 않습니다.

### Step 1: Notion 검색

```bash
search_notion_features "$query"
```

### Step 2: 결과 출력

```
🔍 검색 결과 ({N}개)

1. [P0] 기능명1 - 개발중 | 화주
2. [P1] 기능명2 - 대기 | 운송사
3. [P2] 기능명3 - 대기 | 화주

💡 '/docu-start {키워드}'로 작업을 시작하세요.
```

---

## PostHook 조건

다음 조건 충족 시 성공:
- active-tasks.json에 작업이 추가됨 (기본/--add 모드)
- 또는 검색 결과가 출력됨 (--search 모드)

---

## 출력 예시

### 기본 모드 완료

```
✅ 작업이 시작되었습니다!

📋 기능 정보
- 제목: 로그인 기능 개선
- 채널: 화주
- 우선순위: P0
- 상태: 개발중

📝 기능 목적
사용자가 카카오 로그인으로 빠르게 접근할 수 있도록 합니다.

✅ 체크리스트
- [ ] 카카오 SDK 연동
- [ ] 로그인 UI 구현
- [ ] 토큰 관리 로직

💡 다음 단계를 선택하세요.
```

---

## Output Language

모든 출력은 **한글**로 작성합니다.

---

## 관련 명령어

| 명령어 | 설명 |
|--------|------|
| `/docu-list` | 진행 중인 작업 목록 |
| `/docu-switch` | 다른 작업으로 전환 |
| `/docu-update` | 상태 업데이트 |
| `/docu-close` | 작업 완료 |
| `/triage` | 복잡도 분석 및 워크플로우 시작 |
