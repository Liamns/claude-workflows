# /docu - Notion 문서 통합 관리 명령어

**버전**: 1.0.0
**대체**: `/notion-start`, `/notion-list`, `/notion-switch`, `/notion-recommend`, `/notion-sync-commits`

---

## Overview

Notion 기능 명세서 기반 작업 관리를 위한 통합 명령어입니다.

## Configuration

**⚠️ 명령어 실행 전 반드시 YAML 설정을 로드하세요:**

```bash
source .claude/lib/config-loader.sh
load_config "docu"
```

**설정 파일**: `.claude/commands-config/docu.yaml`

주요 설정값 참조:
```bash
# Notion 데이터 소스 ID
HWAJU_DS="2ac47c08-6985-811b-a177-000b9ea43547"
UNSONGSA_DS="2ae47c08-6985-8179-bac0-e3bdda9c304d"

# 캐시 파일
ACTIVE_TASKS=".claude/cache/active-tasks.json"
PENDING_COMMITS=".claude/cache/pending-commits.json"
```

## Usage

```bash
/docu <action> [options]
```

### Available Actions

| Action | 설명 | 대체 명령어 |
|--------|------|-------------|
| `start` | 기능 명세서 기반 작업 시작 | `/notion-start` |
| `list` | 진행 중인 작업 목록 | `/notion-list` |
| `switch` | 다른 작업으로 전환 | `/notion-switch` |
| `recommend` | 다음 작업 추천 | `/notion-recommend` |
| `update` | 현재 작업 상태 업데이트 | - |
| `log` | 작업 로그 조회 | - |
| `sync` | 커밋 내역 동기화 | `/notion-sync-commits` |
| `search` | Notion 검색 | - |
| `close` | 작업 완료 처리 | - |
| `add` | 새 기능정의서 추가 | `/notion-add` |

---

## Action: start

**기능 명세서에서 작업을 시작합니다.**

```bash
/docu start [keyword]
/docu start 로그인
/docu start --priority P0
```

### Workflow

1. **Notion 검색**: 키워드로 기능 명세서 데이터베이스 검색
   ```bash
   source .claude/lib/notion-utils.sh
   search_notion_features "$keyword"
   ```

2. **AskUserQuestion**: 검색 결과에서 기능 선택
   - question: "어떤 기능을 작업하시겠습니까?"
   - header: "Feature"
   - options: 검색 결과 (label: 기능명, description: "P0 | 대기")

3. **템플릿 파싱**: 선택된 기능의 상세 내용 파싱
   - 🎯 기능 목적
   - 🔄 비즈니스 로직
   - 📋 체크리스트
   - 🔗 연관 기능

4. **Notion 업데이트 확인**: AskUserQuestion으로 업데이트 여부 확인
   - 시작일: KST 오늘 날짜
   - 진행현황: "개발중"

5. **Active Tasks 저장**: `.claude/cache/active-tasks.json`에 작업 추가
   ```bash
   source .claude/lib/notion-active-tasks.sh
   add_active_task "$page_id" "$feature_name" "$priority" "개발중"
   ```

6. **/triage 자동 호출**: 파싱된 템플릿 기반으로 워크플로우 시작

---

## Action: list

**진행 중인 모든 작업을 표시합니다.**

```bash
/docu list
/docu list --summary
```

### Workflow

1. **Active Tasks 조회**:
   ```bash
   source .claude/lib/notion-active-tasks.sh
   list_active_tasks
   ```

2. **출력 형식**:
   ```
   📋 진행 중인 작업 (3개)

   ★ [P0] 로그인 기능 - 개발중 (3일차)
     [P1] 회원가입 기능 - 대기
     [P2] 비밀번호 찾기 - 대기

   💡 '/docu switch <번호>'로 작업 전환
   ```

---

## Action: switch

**다른 작업으로 컨텍스트를 전환합니다.**

```bash
/docu switch <task-number>
/docu switch 2
```

### Workflow

1. **작업 확인**: active-tasks.json에서 해당 작업 조회
2. **컨텍스트 전환**: 현재 활성 작업 변경
   ```bash
   source .claude/lib/notion-active-tasks.sh
   switch_active_task "$task_number"
   ```
3. **상태 출력**: 전환된 작업 정보 표시

---

## Action: recommend

**다음에 진행할 작업을 추천합니다.**

```bash
/docu recommend
```

### Workflow

1. **Notion 검색**: 대기 중인 기능 검색 (진행현황 = "대기")
2. **우선순위 정렬**: P0 > P1 > P2
3. **AskUserQuestion**: 추천 작업 제시
   - question: "다음 작업으로 어떤 기능을 시작하시겠습니까?"
   - options: 상위 3개 추천 + "직접 검색"

---

## Action: update

**현재 작업의 상태를 업데이트합니다.**

```bash
/docu update <status>
/docu update "개발중"
/docu update "테스트중"
/docu update "완료"
```

### Workflow

1. **현재 작업 확인**: active-tasks.json에서 현재 활성 작업
2. **Notion 업데이트**: 진행현황 변경
   ```bash
   source .claude/lib/notion-utils.sh
   update_notion_page "$page_id" '{"진행현황": "'"$status"'"}'
   ```
3. **로컬 캐시 업데이트**: active-tasks.json 동기화

---

## Action: log

**작업 로그를 조회합니다.**

```bash
/docu log
/docu log --days 7
```

### Workflow

1. **커밋 이력 조회**: 현재 작업 관련 커밋
   ```bash
   git log --since="7 days ago" --oneline | head -20
   ```
2. **Notion 이력 조회**: 작업로그 서브페이지 내용
3. **통합 출력**: 타임라인 형식

---

## Action: sync

**커밋 내역을 Notion에 동기화합니다.**

```bash
/docu sync
/docu sync --force
```

### Workflow

1. **Pending Commits 확인**: `.claude/cache/pending-commits.json`
2. **Notion 업데이트**: 작업로그 서브페이지에 커밋 내역 추가
   ```bash
   source .claude/lib/notion-utils.sh
   sync_commits_to_notion "$page_id"
   ```
3. **캐시 클리어**: 동기화 완료 후 pending-commits.json 비우기

---

## Action: search

**Notion 데이터베이스를 검색합니다.**

```bash
/docu search <keyword>
/docu search "로그인"
```

### Workflow

1. **Notion 검색**: 키워드로 검색
2. **결과 출력**: 페이지 목록 (ID, 제목, 상태)

---

## Action: close

**작업을 완료 처리합니다.**

```bash
/docu close
/docu close --keep-branch
```

### Workflow

1. **현재 작업 확인**: active-tasks.json에서 현재 활성 작업
2. **Notion 업데이트**:
   - 진행현황: "완료"
   - 완료일: KST 오늘 날짜
3. **Active Tasks 제거**: 목록에서 작업 삭제
4. **다음 작업 추천**: `/docu recommend` 자동 호출

---

## Action: add

**새로운 기능정의서를 추가합니다.**

```bash
/docu add [기능명]
/docu add "로그인 기능"
/docu add --interactive
```

### 데이터베이스 정보

| 채널 | Data Source ID |
|------|----------------|
| 화주 | `2ac47c08-6985-811b-a177-000b9ea43547` |
| 운송사 | `2ae47c08-6985-8179-bac0-e3bdda9c304d` |

### Workflow

1. **유사 기능 검색**: 중복 방지
   ```bash
   source .claude/lib/notion-utils.sh
   search_notion_features "$feature_name"
   ```

2. **중복 확인 (AskUserQuestion)**:
   - question: "다음 유사 기능이 발견되었습니다. 어떻게 하시겠습니까?"
   - options: ["기존 기능 수정", "새로운 기능 추가", "취소"]

3. **필수 정보 수집 (AskUserQuestion)**:
   - 채널 선택: 화주, 운송사, 기사앱, 공통
   - 기능 그룹 선택: 채널별 실제 데이터에서 조회
   - 우선순위 선택: P0, P1, P2, P3

4. **템플릿 기반 페이지 생성**:
   ```bash
   create_notion_feature_page "$channel" "$group" "$name" "$priority"
   ```

5. **결과 반환**: 생성된 페이지 URL

---

## Required Libraries

```bash
source .claude/lib/notion-utils.sh
source .claude/lib/notion-active-tasks.sh
```

---

## Migration Guide

| 기존 명령어 | 새 명령어 |
|-------------|-----------|
| `/notion-start` | `/docu start` |
| `/notion-list` | `/docu list` |
| `/notion-switch` | `/docu switch` |
| `/notion-recommend` | `/docu recommend` |
| `/notion-sync-commits` | `/docu sync` |
| `/notion-add` | `/docu add` |

---

## Output Language

모든 사용자 출력은 **한글**로 작성합니다.

---

**문서 버전**: 1.0.0
**최종 수정**: 2025-11-21
