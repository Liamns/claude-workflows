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

# 속성명 (실제 Notion 스키마)
PROP_TITLE="작업 설명"
PROP_STATUS="진행 상황"
PROP_PRIORITY="우선순위"
PROP_TAG="작업 분류"
PROP_ASSIGNEE="참여자"
PROP_START_DATE="시작일"
PROP_END_DATE="종료일"
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
| `--today` | 오늘 Git 커밋 기반 이슈 일괄 생성 |

---

## Database Schema

| 필드 | 타입 | 값 |
|------|------|-----|
| 작업 설명 | title | 프로젝트/이슈 제목 |
| 진행 상황 | status | `Not started`, `In progress`, `Done` |
| 우선순위 | select | `High`, `Medium`, `Low` |
| 작업 분류 | multi_select | `Issue`, `Bug`, `Feature`, `Refatoring` |
| 참여자 | person | 담당자 |
| 시작일 | date | 시작일 |
| 종료일 | date | 종료일 |
| Team | multi_select | 팀 |
| Progress | formula | 진행률 (자동 계산) |

---

## Action: add

**새 프로젝트/이슈를 추가합니다.**

```bash
/tracker add [제목]
/tracker add "로그인 버그 수정"
/tracker add --author-홍길동 "버그 수정"    # 담당자 자동 설정
/tracker add --author-kim "새 기능"          # 이름 일부로 검색
```

### Options

| 옵션 | 설명 |
|------|------|
| `--author-{name}` | Assignee를 자동 설정. {name}으로 Notion 사용자 검색 후 매칭 |

### Workflow

1. **--author-xxx 옵션 처리** (옵션 있을 경우):
   ```bash
   # 사용자 검색
   mcp__notion-company__notion-get-users --query "$author_name"
   ```

   **매칭 결과 처리**:
   - **1명 매칭**: 자동으로 해당 사용자 선택
   - **다수 매칭**: AskUserQuestion으로 선택
     ```
     AskUserQuestion:
     - question: "'{author_name}'에 해당하는 사용자가 여러 명입니다. 선택하세요."
     - header: "담당자"
     - options: [매칭된 사용자 목록]
     ```
   - **0명 매칭**: 경고 출력 후 담당자 없이 진행
     ```
     ⚠️ '{author_name}'에 해당하는 사용자를 찾을 수 없습니다. 담당자 없이 생성합니다.
     ```

2. **정보 수집 (AskUserQuestion)**:

   **Tag 선택**:
   - question: "유형을 선택하세요"
   - options: ["Issue", "Bug", "Feature", "Refatoring"]

   **Priority 선택**:
   - question: "우선순위를 선택하세요"
   - options: ["High", "Medium", "Low"]

3. **Notion 페이지 생성**:
   ```bash
   source .claude/lib/notion-utils.sh

   # KST 날짜
   start_date=$(TZ=Asia/Seoul date +%Y-%m-%d)

   # 페이지 생성 (Assignee 포함 여부에 따라 properties 구성)
   # --author-xxx로 user_id가 확보된 경우:
   mcp__notion-company__notion-create-pages \
     --parent '{"data_source_id": "2ad47c08-6985-8016-b033-000bdcffaec7"}' \
     --pages '[{
       "properties": {
         "작업 설명": "'"$title"'",
         "진행 상황": "Not started",
         "우선순위": "'"$priority"'",
         "작업 분류": "[\"'"$tag"'\"]",
         "참여자": "[\"'"$user_id"'\"]",
         "date:시작일:start": "'"$start_date"'"
       }
     }]'

   # --author-xxx 없거나 매칭 실패 시:
   mcp__notion-company__notion-create-pages \
     --parent '{"data_source_id": "2ad47c08-6985-8016-b033-000bdcffaec7"}' \
     --pages '[{
       "properties": {
         "작업 설명": "'"$title"'",
         "진행 상황": "Not started",
         "우선순위": "'"$priority"'",
         "작업 분류": "[\"'"$tag"'\"]",
         "date:시작일:start": "'"$start_date"'"
       }
     }]'
   ```

4. **결과 반환**: 생성된 페이지 URL

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
     --data '{"page_id": "'"$page_id"'", "command": "update_properties", "properties": {"진행 상황": "'"$status"'"}}'
   ```
3. **결과 출력**: 업데이트 완료 메시지
4. **완료 제안** (상태가 `Done`이 아닌 경우에도 완료 키워드 감지 시):

   ```bash
   # 완료 키워드 패턴
   COMPLETE_PATTERNS="완료|Done|마무리|close|fix|resolve|finished"
   ```

   **완료 키워드 감지 시 AskUserQuestion:**
   ```
   AskUserQuestion 도구 호출:
   - question: "이 이슈가 완료된 것으로 보입니다. 완료 처리하시겠습니까?"
   - header: "완료 확인"
   - options:
     - label: "예, 완료 처리"
       description: "Status를 Done으로 변경하고 종료일 설정"
     - label: "아니오, 계속 진행"
       description: "현재 상태 유지"
     - label: "나중에 결정"
       description: "이번에는 건너뛰기"
   ```

   **"예, 완료 처리" 선택 시:**
   ```bash
   end_date=$(TZ=Asia/Seoul date +%Y-%m-%d)

   mcp__notion-company__notion-update-page \
     --data '{
       "page_id": "'"$page_id"'",
       "command": "update_properties",
       "properties": {
         "진행 상황": "Done",
         "date:종료일:start": "'"$end_date"'"
       }
     }'
   ```

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
     --data '{"page_id": "'"$page_id"'", "command": "update_properties", "properties": {"참여자": "[\"'"$user_id"'\"]"}}'
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
     --data '{"page_id": "'"$page_id"'", "command": "update_properties", "properties": {"진행 상황": "Done", "date:종료일:start": "'"$end_date"'"}}'
   ```
3. **결과 출력**: 완료 메시지

---

## Action: --today

**오늘 Git 커밋을 분석하여 이슈를 일괄 생성합니다.**

```bash
/tracker --today
```

### Workflow

#### Step 1: 커밋 없음 확인

```bash
commit_count=$(git log --since="today 00:00" --oneline | wc -l)
```

**커밋이 0개인 경우:**
```
AskUserQuestion 도구 호출:
- question: "오늘 커밋이 없습니다. 다른 날짜 범위를 선택하시겠습니까?"
- header: "날짜"
- options:
  - label: "어제 커밋"
    description: "--since='yesterday 00:00'"
  - label: "이번 주"
    description: "--since='1 week ago'"
  - label: "취소"
    description: "명령어 종료"
```

#### Step 2: 작업자 확인

```bash
git log --since="today 00:00" --format="%an" | sort -u
```

**작업자가 2명 이상인 경우:**
```
AskUserQuestion 도구 호출:
- question: "오늘 여러 작업자의 커밋이 있습니다. 어떤 작업자의 내용을 정리하시겠습니까?"
- header: "작업자"
- options:
  - label: "{작업자1}"
    description: "{N}개 커밋"
  - label: "{작업자2}"
    description: "{M}개 커밋"
  - label: "전체"
    description: "모든 작업자 ({총합}개 커밋)"
```

#### Step 3: Git 커밋 수집

```bash
git log --since="today 00:00" --author="$author" --format="%h|%s|%ad" --date=short
```

#### Step 4: 커밋 타입별 Tag 매핑

| 커밋 타입 | Tag |
|----------|-----|
| `fix:` | Bug |
| `feat:` | Feature |
| `refactor:` | Refatoring |
| 기타 | Issue |

#### Step 5: 이슈 일괄 생성

각 커밋에 대해:

```bash
# KST 날짜
start_date=$(TZ=Asia/Seoul date +%Y-%m-%d)

# 커밋 메시지에서 타입 제거하여 제목 추출
# 예: "feat(login): 버튼 추가" → "버튼 추가"
title=$(echo "$commit_msg" | sed 's/^[^:]*: //')

# Notion 페이지 생성
mcp__notion-company__notion-create-pages \
  --parent '{"data_source_id": "2ad47c08-6985-8016-b033-000bdcffaec7"}' \
  --pages '[{
    "properties": {
      "작업 설명": "'"$title"'",
      "진행 상황": "Not started",
      "우선순위": "Medium",
      "작업 분류": "[\"'"$tag"'\"]",
      "date:시작일:start": "'"$start_date"'"
    }
  }]'
```

#### Step 6: 결과 출력

```
✅ 오늘 이슈 일괄 생성 완료!

📊 처리 결과
- 분석된 커밋: {N}개
- 생성된 이슈: {M}개

📝 생성된 이슈:
- 🐛 [Bug] 로그인 버튼 오류 수정
- ✨ [Feature] 회원가입 UI 추가
- 🔧 [Refatoring] API 클라이언트 정리

💡 '/tracker list'로 전체 목록을 확인하세요.
```

#### Step 7: 완료 커밋 감지 및 자동 완료 제안

커밋 메시지에 완료 키워드가 포함된 경우 해당 이슈의 완료 처리를 제안:

```bash
# 완료 키워드 패턴
COMPLETE_PATTERNS="완료|Done|마무리|close|fix|resolve|finished"

# 커밋 메시지 분석
for commit in $commits; do
  if [[ "$commit_msg" =~ $COMPLETE_PATTERNS ]]; then
    completed_issues+=("$commit_msg")
  fi
done
```

**완료 키워드가 감지된 커밋이 있는 경우:**
```
AskUserQuestion 도구 호출:
- question: "완료로 보이는 작업이 있습니다. 해당 이슈를 Done으로 처리하시겠습니까?"
- header: "완료 확인"
- options:
  - label: "예, 완료 처리"
    description: "완료 키워드가 포함된 이슈를 Done으로 변경"
  - label: "선택적 처리"
    description: "각 이슈별로 완료 여부 확인"
  - label: "아니오"
    description: "모두 Not started 상태 유지"
```

**"예, 완료 처리" 또는 "선택적 처리" 선택 시:**
```bash
end_date=$(TZ=Asia/Seoul date +%Y-%m-%d)

mcp__notion-company__notion-update-page \
  --data '{
    "page_id": "'"$created_page_id"'",
    "command": "update_properties",
    "properties": {
      "진행 상황": "Done",
      "date:종료일:start": "'"$end_date"'"
    }
  }'
```

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

**문서 버전**: 1.2.0
**최종 수정**: 2025-11-27
**업데이트**:
- 1.2.0: Notion 스키마 속성명을 실제 한글 이름으로 수정
- 1.1.0: --author-xxx 옵션 추가, 이슈 완료 자동 제안 기능 추가
