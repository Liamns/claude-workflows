---
name: docu
---

# /docu - Notion 기능 명세서 통합 게이트웨이

> **참고**: 이 명령어는 `.claude/CLAUDE.md`의 규칙을 준수합니다.

자연어로 Notion 기능 명세서를 관리합니다.

## Critical Rules

1. **HK 워크스페이스 Notion MCP 사용**: MCP 이름(notion-company, notion-personal 등)은 환경마다 다를 수 있음. **HK 워크스페이스에 연결된 Notion MCP**를 사용
2. **AskUserQuestion 필수**: 채널 선택, 기능 선택, 다음 단계 제안 시 사용
3. **한글 출력**: 모든 출력은 한글로 작성

## Usage

```bash
/docu [자연어로 하고 싶은 것]
/docu --web [자연어]    # 화주 채널 지정
/docu --admin [자연어]  # 어드민 채널 지정
```

### 예시

```bash
/docu 로그인 기능 시작
/docu 지금 뭐하고 있지
/docu 주문 취소 완료 처리
/docu 새 기능 추가: 결제 연동
/docu API 연동 검색
```

## Configuration

### Data Source ID

| 채널 | Data Source ID |
|------|----------------|
| 화주 | `2ac47c08-6985-811b-a177-000b9ea43547` |
| 어드민 | `35d8c49c-a343-4bb4-a62a-8a418b8abca5` |

### Cache 파일

```bash
ACTIVE_TASKS=".claude/cache/active-tasks.json"
```

---

## Workflow

### Step 1: 채널 선택

`--web` 또는 `--admin` 옵션이 없으면 AskUserQuestion으로 채널 선택:

```
AskUserQuestion 도구 호출:
- question: "어떤 채널에서 작업하시겠습니까?"
- header: "채널"
- options:
  - label: "화주"
    description: "화주 앱 기능 명세서"
  - label: "어드민"
    description: "어드민 WEB 기능정의서"
```

선택에 따라 Data Source ID 결정:
- 화주 → `2ac47c08-6985-811b-a177-000b9ea43547`
- 어드민 → `35d8c49c-a343-4bb4-a62a-8a418b8abca5`

### Step 2: 자연어 의도 파악 및 처리

Claude Code가 입력된 자연어를 이해하여 적절한 동작 수행.

#### 의도별 가이드

| 사용자 의도 | 키워드 예시 | 동작 |
|------------|-----------|------|
| **작업 시작** | "시작", "작업", "개발", "구현" | Notion 검색 → 기능 선택 → active-tasks에 추가 |
| **목록 조회** | "목록", "뭐하고", "현재", "진행중" | active-tasks.json 조회 후 출력 |
| **상태 변경** | "변경", "업데이트", "개발중으로" | Notion update-page로 진행현황 변경 |
| **완료 처리** | "완료", "끝", "done", "마무리" | Notion update-page (완료) + active-tasks에서 제거 |
| **새로 추가** | "새로", "추가", "생성" | Notion create-pages로 새 기능정의서 생성 |
| **검색만** | "검색", "찾아", "있어?" | Notion search (작업 시작 안 함) |
| **상세 조회** | "상태", "진행상황", "어디까지" | Notion fetch → 요약 출력 |

---

## 의도별 상세 동작

### 작업 시작 (start)

1. Notion search로 키워드 검색 (선택된 채널의 data_source_url 사용)
2. AskUserQuestion으로 기능 선택
3. 선택된 기능 정보 출력
4. AskUserQuestion: Notion 업데이트 여부 확인
   - "업데이트" 선택 시: 진행현황을 "개발중"으로, 시작일 설정
5. active-tasks.json에 추가

```bash
source .claude/lib/notion-active-tasks.sh
add_active_task "$page_id" "$title" "$priority" "개발중" "$channel" "$feature_group"
```

### 목록 조회 (list)

1. active-tasks.json 조회
2. 우선순위순 정렬하여 출력

```bash
source .claude/lib/notion-active-tasks.sh
list_active_tasks
```

**출력 형식:**
```
📋 진행 중인 작업 ({N}개)

★ [P0] 로그인 기능 개선 - 개발중 (3일차) | 화주
   [P1] 회원가입 기능 - 대기 | 어드민

★ = 현재 활성 작업
```

### 완료 처리 (close)

1. 현재 활성 작업 또는 지정된 작업 확인
2. AskUserQuestion: 완료 확인
3. Notion update-page: 진행현황을 "완료"로, 완료일 설정
4. active-tasks.json에서 제거

```bash
source .claude/lib/notion-active-tasks.sh
remove_active_task "$page_id"
```

### 새로 추가 (create)

1. AskUserQuestion: 필수 정보 수집 (기능명, 우선순위)
2. Notion create-pages로 새 페이지 생성
3. 결과 URL 출력

### 검색만 (search)

1. Notion search로 키워드 검색
2. 결과 목록 출력 (작업 시작 안 함)

**출력 형식:**
```
🔍 검색 결과 ({N}개)

1. [P0] 로그인 기능 - 개발중 | 화주
2. [P1] 회원가입 - 대기 | 화주

💡 '/docu {기능명} 시작'으로 작업을 시작하세요.
```

---

## Step 3: 다음 단계 제안

각 동작 완료 후 AskUserQuestion으로 다음 단계 제안:

```
AskUserQuestion 도구 호출:
- question: "다음으로 무엇을 하시겠습니까?"
- header: "다음"
- options:
  - label: "/triage"
    description: "복잡도 분석 후 워크플로우 시작"
  - label: "/docu 목록"
    description: "진행 중인 작업 확인"
  - label: "종료"
    description: "세션 종료"
```

---

## 날짜 처리

모든 날짜는 KST 기준:

```bash
today=$(TZ='Asia/Seoul' date +%Y-%m-%d)
```

---

## 에러 처리

### 활성 작업 없음

```
📋 진행 중인 작업 (0개)

등록된 작업이 없습니다.

💡 '/docu {키워드} 시작'으로 새 작업을 시작하세요.
```

### 검색 결과 없음

```
🔍 검색 결과 (0개)

'{키워드}'에 해당하는 기능을 찾을 수 없습니다.

💡 '/docu 새로 추가: {기능명}'으로 새 기능정의서를 만드세요.
```

---

## Output Language

모든 출력은 **한글**로 작성합니다.

---

## 관련 리소스

### 유틸리티 함수
- `.claude/lib/notion-active-tasks.sh` - 작업 관리
- `.claude/lib/notion-utils.sh` - MCP 래퍼 (참고용)

### 설정
- `.claude/commands-config/docu.yaml` - Data Source 설정

---

**Version**: 1.0.0
**Last Updated**: 2025-11-26
