# /tracker - 프로젝트 & 이슈 트래커

**버전**: 1.0.0
**Database**: Projects
**Data Source**: `collection://2ad47c08-6985-8016-b033-000bdcffaec7`

---

## Overview

프로젝트 및 이슈를 추적하고 관리하는 명령어입니다. 기능 명세서(`/docu`)와는 별개의 트래커 데이터베이스를 사용합니다.

## Configuration

**⚠️ 명령어 실행 전 반드시 YAML 설정을 로드하세요:**

```bash
source .claude/lib/config-loader.sh
load_config "tracker"
```

**설정 파일**: `.claude/commands-config/tracker.yaml`

주요 설정값 참조:
```bash
# Projects 데이터 소스
TRACKER_DS="2ad47c08-6985-8016-b033-000bdcffaec7"
TRACKER_DS_URL="collection://2ad47c08-6985-8016-b033-000bdcffaec7"

# 속성명
PROP_TITLE="Project name"
PROP_STATUS="Status"
PROP_PRIORITY="Priority"
PROP_TAG="Tag"
```

## Usage

```bash
/tracker <action> [options]
```

### Available Actions

| Action | 설명 |
|--------|------|
| `add` | 새 프로젝트/이슈 추가 |
| `list` | 프로젝트 목록 조회 |
| `update` | 상태 업데이트 |
| `assign` | 담당자 배정 |
| `close` | 완료 처리 |

---

## Database Schema

| 필드 | 타입 | 값 |
|------|------|-----|
| Project name | title | 프로젝트/이슈 제목 |
| Status | status | `Not started`, `In progress`, `Done` |
| Priority | select | `High`, `Medium`, `Low` |
| Tag | multi_select | `Issue`, `Bug`, `Feature`, `Refatoring` |
| Assignee | person | 담당자 |
| Start date | date | 시작일 |
| End date | date | 종료일 |
| Team | multi_select | 팀 |
| Progress | formula | 진행률 (자동 계산) |

---

## Action: add

**새 프로젝트/이슈를 추가합니다.**

```bash
/tracker add [제목]
/tracker add "로그인 버그 수정"
```

### Workflow

1. **정보 수집 (AskUserQuestion)**:

   **Tag 선택**:
   - question: "유형을 선택하세요"
   - options: ["Issue", "Bug", "Feature", "Refatoring"]

   **Priority 선택**:
   - question: "우선순위를 선택하세요"
   - options: ["High", "Medium", "Low"]

2. **Notion 페이지 생성**:
   ```bash
   source .claude/lib/notion-utils.sh

   # KST 날짜
   start_date=$(TZ=Asia/Seoul date +%Y-%m-%d)

   # 페이지 생성
   mcp__notion-company__notion-create-pages \
     --parent '{"data_source_id": "2ad47c08-6985-8016-b033-000bdcffaec7"}' \
     --pages '[{
       "properties": {
         "Project name": "'"$title"'",
         "Status": "Not started",
         "Priority": "'"$priority"'",
         "Tag": "[\"'"$tag"'\"]",
         "date:Start date:start": "'"$start_date"'"
       }
     }]'
   ```

3. **결과 반환**: 생성된 페이지 URL

---

## Action: list

**프로젝트 목록을 조회합니다.**

```bash
/tracker list
/tracker list --status "In progress"
/tracker list --priority High
/tracker list --tag Bug
```

### Options

| 옵션 | 설명 |
|------|------|
| `--status` | 상태 필터 (Not started, In progress, Done) |
| `--priority` | 우선순위 필터 (High, Medium, Low) |
| `--tag` | 유형 필터 (Issue, Bug, Feature, Refatoring) |

### Workflow

1. **Notion 검색**:
   ```bash
   mcp__notion-company__notion-search \
     --query "$keyword" \
     --data_source_url "collection://2ad47c08-6985-8016-b033-000bdcffaec7"
   ```

2. **결과 출력**:
   ```
   📋 프로젝트 목록

   [High] 🐛 로그인 버그 수정 - In progress - @홍길동
   [Medium] ✨ 알림 기능 추가 - Not started - 미배정
   [Low] 🔧 코드 리팩토링 - Done - @김철수

   총 3개
   ```

   **Tag 아이콘**:
   - Issue: 📌
   - Bug: 🐛
   - Feature: ✨
   - Refatoring: 🔧

---

## Action: update

**프로젝트 상태를 업데이트합니다.**

```bash
/tracker update <page-id> <status>
/tracker update "abc123" "In progress"
/tracker update "abc123" "Done"
```

### Status Options

- `Not started`: 시작 전
- `In progress`: 진행 중
- `Done`: 완료

### Workflow

1. **페이지 확인**: Notion에서 페이지 존재 확인
2. **상태 업데이트**:
   ```bash
   mcp__notion-company__notion-update-page \
     --data '{"page_id": "'"$page_id"'", "command": "update_properties", "properties": {"Status": "'"$status"'"}}'
   ```
3. **결과 출력**: 업데이트 완료 메시지

---

## Action: assign

**담당자를 배정합니다.**

```bash
/tracker assign <page-id>
```

### Workflow

1. **사용자 검색**: Notion workspace 사용자 목록 조회
   ```bash
   mcp__notion-company__notion-get-users
   ```

2. **담당자 선택 (AskUserQuestion)**:
   - question: "담당자를 선택하세요"
   - options: 사용자 목록

3. **Assignee 업데이트**:
   ```bash
   mcp__notion-company__notion-update-page \
     --data '{"page_id": "'"$page_id"'", "command": "update_properties", "properties": {"Assignee": "[\"'"$user_id"'\"]"}}'
   ```

---

## Action: close

**프로젝트를 완료 처리합니다.**

```bash
/tracker close <page-id>
```

### Workflow

1. **페이지 확인**: Notion에서 페이지 존재 확인
2. **상태 및 종료일 업데이트**:
   ```bash
   end_date=$(TZ=Asia/Seoul date +%Y-%m-%d)

   mcp__notion-company__notion-update-page \
     --data '{"page_id": "'"$page_id"'", "command": "update_properties", "properties": {"Status": "Done", "date:End date:start": "'"$end_date"'"}}'
   ```
3. **결과 출력**: 완료 메시지

---

## Views

| View | 설명 | URL |
|------|------|-----|
| By Status | 칸반 보드 | `view://2ad47c08-6985-80e2-8dbe-000c0076918e` |
| All Projects | 전체 테이블 | `view://2ad47c08-6985-80c5-8631-000ceb2987bf` |
| Gantt | 타임라인 | `view://2ad47c08-6985-8077-9ca7-000c39871a05` |
| My Projects | 내 프로젝트 | `view://2ad47c08-6985-8076-a0ce-000c2c7ffee7` |

---

## Output Language

모든 사용자 출력은 **한글**로 작성합니다.

---

**문서 버전**: 1.0.0
**최종 수정**: 2025-11-21
