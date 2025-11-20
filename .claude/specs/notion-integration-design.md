# Notion 통합 기능 설계 문서

**버전**: 1.0.1
**작성일**: 2025-11-20
**작성자**: Claude Workflow System

---

## 📋 목차

1. [개요](#개요)
2. [기능 1: /notion-start - 작업 시작](#기능-1-notion-start---작업-시작)
3. [기능 2: /notion-add - 기능정의서 추가](#기능-2-notion-add---기능정의서-추가)
4. [공통 인프라](#공통-인프라)
5. [상태 관리](#상태-관리)
6. [작업내역 자동 기록](#작업내역-자동-기록)
7. [구현 우선순위](#구현-우선순위)

---

## 개요

### 목적

Notion MCP를 활용하여 기존 Claude Workflow 시스템과 Notion 기능정의서를 통합합니다:

1. **Notion → Workflow**: 기능정의서 기반으로 개발 작업 자동 시작
2. **Workflow → Notion**: 작업 진행 상태를 실시간으로 Notion에 반영
3. **커밋 단위 추적**: 모든 커밋마다 작업내역을 Notion에 자동 기록

### 대상 Notion 구조

**워크스페이스**: HK (notion-company)
**데이터베이스**: 프로젝트 스펙 및 어드민 WEB 기능정의서 보기
**데이터베이스 ID**: `2ac47c086985805185c3e48f0b7ce853`

**데이터 소스**:
- **프로젝트 스펙** (화주 앱): `collection://2ac47c08-6985-811b-a177-000b9ea43547`
- **어드민 WEB 기능정의서**: `collection://35d8c49c-a343-4bb4-a62a-8a418b8abca5`

**주요 컬럼**:
- `기능 설명` (title): 기능명
- `진행현황` (status): 대기/개발중/작업완료/배포완료 등
- `우선순위` (select): P0/P1/P2/P3
- `기능 그룹` (select): 도메인 분류
- `담당자` (person): 작업자
- `시작일` (date): 작업 시작일
- `마감일` (date): 작업 완료일 (PR 생성 시)

---

## 기능 1: /notion-start - 작업 시작

### 사용 시나리오

```bash
# 케이스 1: 키워드로 검색
/notion-start "화주 회원 관리"

# 케이스 2: 우선순위 필터
/notion-start --priority P0

# 케이스 3: 기능 그룹 필터
/notion-start --group "인증 및 계정 관리"

# 케이스 4: 대화형 선택
/notion-start
```

### 워크플로우

```
1. 사용자 입력
   ↓
2. Notion 검색
   - 키워드 매칭 (기능 설명, 기능 그룹)
   - 필터 적용 (우선순위, 담당자, 진행현황)
   ↓
3. 검색 결과 표시
   - AskUserQuestion으로 선택
   ↓
4. 선택된 기능 페이지 fetch
   - 템플릿 내용 파싱
   - 기능 목적, 비즈니스 로직 추출
   ↓
5. 프로젝트 환경 감지
   - /start 문서들 참조
   - 프론트엔드/백엔드/풀스택 판단
   ↓
6. 업데이트 확인
   - AskUserQuestion으로 사용자 확인
   - 업데이트 승인 또는 세션만 저장 선택
   ↓
7. Notion 업데이트 (사용자 확인 시에만)
   - 시작일: 현재 한국 시간 (KST)
   - 진행현황: "리서치중" → "개발중"
   - 담당자: MCP 사용자 (notion-company bot owner)
   ↓
8. /triage 호출
   - 파라미터: 기능 설명 + 상세 내용
   - 워크플로우 추천 및 실행
   ↓
9. 워크플로우 실행 추적
   - 상태 변경 시 Notion 자동 업데이트
   - 커밋 시마다 작업내역 자동 기록
```

### 상세 설계

#### 1.1. Notion 검색 로직

```bash
# lib/notion-search.sh

search_notion_features() {
  local keyword="$1"
  local priority="$2"
  local group="$3"
  local data_source="$4"  # admin 또는 app

  # 데이터 소스 선택
  local collection_url
  if [ "$data_source" = "admin" ]; then
    collection_url="collection://35d8c49c-a343-4bb4-a62a-8a418b8abca5"
  else
    collection_url="collection://2ac47c08-6985-811b-a177-000b9ea43547"
  fi

  # Notion MCP 검색
  mcp__notion-company__notion-search \
    --query "$keyword" \
    --data_source_url "$collection_url"
}
```

#### 1.2. 페이지 내용 파싱

```bash
# lib/notion-parser.sh

parse_feature_template() {
  local page_url="$1"

  # Notion fetch로 페이지 내용 가져오기
  local content=$(mcp__notion-company__notion-fetch --id "$page_url")

  # 템플릿 섹션별 추출
  local purpose=$(extract_section "$content" "🎯 기능 목적")
  local business_logic=$(extract_section "$content" "🔄 비즈니스 로직")
  local related_features=$(extract_section "$content" "🔗 연관 기능")

  # JSON으로 반환
  cat <<EOF
{
  "purpose": "$purpose",
  "business_logic": "$business_logic",
  "related_features": "$related_features"
}
EOF
}
```

#### 1.3. 프로젝트 환경 감지

```bash
# lib/project-detector.sh

detect_project_environment() {
  local project_root="$1"

  # /start 생성 문서 확인
  if [ -f ".specify/project-overview.md" ]; then
    local stack=$(grep "Tech Stack" .specify/project-overview.md)

    # React/Vue/Angular → 프론트엔드
    if echo "$stack" | grep -E "React|Vue|Angular"; then
      echo "frontend"
    # Express/NestJS/FastAPI → 백엔드
    elif echo "$stack" | grep -E "Express|NestJS|FastAPI|Django"; then
      echo "backend"
    # 둘 다 → 풀스택
    else
      echo "fullstack"
    fi
  fi
}
```

#### 1.4. Notion 업데이트 - 작업 시작

```bash
# lib/notion-update.sh

update_notion_start() {
  local page_id="$1"
  local user_id="$2"  # MCP 사용자 ID

  # 한국 시간 (KST) 계산
  local kst_date=$(TZ='Asia/Seoul' date +%Y-%m-%d)

  # Notion 업데이트
  mcp__notion-company__notion-update-page \
    --page_id "$page_id" \
    --command "update_properties" \
    --properties '{
      "date:시작일:start": "'"$kst_date"'",
      "date:시작일:is_datetime": 0,
      "진행현황": "개발중",
      "담당자": "[\"'"$user_id"'\"]"
    }'

  # 현재 작업 페이지 ID 저장 (세션 유지)
  echo "$page_id" > .claude/cache/current-notion-page.txt
}
```

#### 1.5. /triage 호출

```bash
# lib/triage-caller.sh

call_triage_from_notion() {
  local feature_data="$1"
  local project_env="$2"

  # 기능 정보 추출
  local title=$(echo "$feature_data" | jq -r '.title')
  local purpose=$(echo "$feature_data" | jq -r '.purpose')
  local business_logic=$(echo "$feature_data" | jq -r '.business_logic')

  # /triage 파라미터 구성
  local triage_input=$(cat <<EOF
[$project_env] $title

기능 목적:
$purpose

비즈니스 로직:
$business_logic
EOF
)

  # /triage 실행
  SlashCommand "/triage \"$triage_input\""
}
```

---

## 기능 2: /notion-add - 기능정의서 추가

### 사용 시나리오

```bash
# 케이스 1: 간단한 기능 추가
/notion-add "사용자 프로필 이미지 업로드 기능"

# 케이스 2: 상세 정보 포함
/notion-add --interactive

# 케이스 3: 기존 기능 수정
/notion-add --update "회원 가입 기능"
```

### 워크플로우

```
1. 사용자 입력
   ↓
2. 유사 기능 검색
   - Notion semantic search
   - 기능 설명 유사도 분석
   ↓
3. 분기 판단
   - 유사 기능 발견 → 병합 프로세스
   - 신규 기능 → 생성 프로세스
   ↓
4a. [병합] 기존 기능 수정
   - 사용자 확인 (AskUserQuestion)
   - 기존 내용 + 신규 내용 병합
   - Notion 페이지 업데이트
   ↓
4b. [신규] 템플릿 기반 생성
   - 필수 필드 검증
   - 부족한 정보 수집 (AskUserQuestion)
   - Notion 페이지 생성
   ↓
5. 생성/수정 완료
   - 페이지 URL 반환
```

### 상세 설계

#### 2.1. 유사 기능 검색

```bash
# lib/notion-similarity.sh

find_similar_features() {
  local feature_desc="$1"
  local data_source="$2"

  # Notion semantic search
  local results=$(mcp__notion-company__notion-search \
    --query "$feature_desc" \
    --query_type "internal" \
    --data_source_url "$data_source")

  # 결과 파싱 (상위 3개)
  echo "$results" | jq -r '.results[:3]'
}
```

#### 2.2. 템플릿 검증

```bash
# lib/notion-template-validator.sh

REQUIRED_FIELDS=(
  "도메인"
  "채널"
  "우선순위"
  "기능 목적"
)

validate_template_data() {
  local data="$1"

  local missing_fields=()

  for field in "${REQUIRED_FIELDS[@]}"; do
    if ! echo "$data" | jq -e ".$field" > /dev/null; then
      missing_fields+=("$field")
    fi
  done

  if [ ${#missing_fields[@]} -gt 0 ]; then
    echo "MISSING: ${missing_fields[*]}"
    return 1
  fi

  return 0
}
```

#### 2.3. 대화형 정보 수집

```bash
# lib/notion-interactive.sh

collect_feature_info() {
  local initial_desc="$1"

  # 1. 기본 정보
  AskUserQuestion \
    --question "어떤 채널의 기능인가요?" \
    --header "채널" \
    --options '["어드민 WEB", "화주 앱", "공통"]'

  local channel="$answer"

  # 2. 우선순위
  AskUserQuestion \
    --question "우선순위는 어떻게 되나요?" \
    --header "우선순위" \
    --options '[
      {"label": "P0", "description": "론칭 필수"},
      {"label": "P1", "description": "중요함"},
      {"label": "P2", "description": "여유 있으면"},
      {"label": "P3", "description": "이번 버전 제외"}
    ]'

  local priority="$answer"

  # 3. 기능 그룹
  local groups=$(get_feature_groups "$channel")
  AskUserQuestion \
    --question "어떤 기능 그룹에 속하나요?" \
    --header "기능 그룹" \
    --options "$groups"

  local group="$answer"

  # 4. 기능 목적
  echo "기능의 목적을 설명해주세요:"
  read -r purpose

  # 5. 비즈니스 로직
  echo "주요 비즈니스 로직을 설명해주세요 (선택):"
  read -r business_logic

  # JSON 구성
  cat <<EOF
{
  "기능 설명": "$initial_desc",
  "채널": "$channel",
  "우선순위": "$priority",
  "기능 그룹": "$group",
  "기능 목적": "$purpose",
  "비즈니스 로직": "$business_logic"
}
EOF
}
```

#### 2.4. Notion 페이지 생성

```bash
# lib/notion-page-creator.sh

create_notion_feature_page() {
  local feature_data="$1"
  local data_source_id="$2"

  # 데이터 추출
  local title=$(echo "$feature_data" | jq -r '.기능_설명')
  local channel=$(echo "$feature_data" | jq -r '.채널')
  local priority=$(echo "$feature_data" | jq -r '.우선순위')
  local group=$(echo "$feature_data" | jq -r '.기능_그룹')
  local purpose=$(echo "$feature_data" | jq -r '.기능_목적')

  # 템플릿 기반 내용 생성
  local content=$(generate_template_content \
    "$channel" "$priority" "$group" "$purpose")

  # Notion 페이지 생성
  mcp__notion-company__notion-create-pages \
    --parent '{"type": "data_source_id", "data_source_id": "'"$data_source_id"'"}' \
    --pages '[{
      "properties": {
        "기능 설명": "'"$title"'",
        "우선순위": "'"$priority"'",
        "기능 그룹": "'"$group"'",
        "진행현황": "대기"
      },
      "content": "'"$content"'"
    }]'
}
```

---

## 공통 인프라

### 설정 파일

```bash
# .claude/config/notion.json

{
  "workspace": "HK",
  "mcp_server": "notion-company",
  "databases": {
    "feature_specs": {
      "id": "2ac47c086985805185c3e48f0b7ce853",
      "data_sources": {
        "admin": "collection://35d8c49c-a343-4bb4-a62a-8a418b8abca5",
        "app": "collection://2ac47c08-6985-811b-a177-000b9ea43547"
      }
    }
  },
  "default_data_source": "admin",
  "timezone": "Asia/Seoul"
}
```

### 유틸리티 함수

```bash
# lib/notion-utils.sh

# 현재 사용자 가져오기
get_current_notion_user() {
  mcp__notion-company__notion-get-self | jq -r '.id'
}

# 데이터 소스 선택
select_data_source() {
  local channel="$1"

  case "$channel" in
    "어드민 WEB")
      echo "collection://35d8c49c-a343-4bb4-a62a-8a418b8abca5"
      ;;
    "화주 앱")
      echo "collection://2ac47c08-6985-811b-a177-000b9ea43547"
      ;;
    *)
      # 기본값: 어드민
      echo "collection://35d8c49c-a343-4bb4-a62a-8a418b8abca5"
      ;;
  esac
}

# 한국 시간 가져오기
get_kst_date() {
  TZ='Asia/Seoul' date +%Y-%m-%d
}

get_kst_datetime() {
  TZ='Asia/Seoul' date +%Y-%m-%dT%H:%M:%S
}

# 현재 작업 중인 Notion 페이지 ID 조회
get_current_notion_page() {
  if [ -f ".claude/cache/current-notion-page.txt" ]; then
    cat .claude/cache/current-notion-page.txt
  fi
}

# 현재 작업 페이지 ID 설정
set_current_notion_page() {
  local page_id="$1"
  echo "$page_id" > .claude/cache/current-notion-page.txt
}

# 작업 완료 후 페이지 ID 클리어
clear_current_notion_page() {
  rm -f .claude/cache/current-notion-page.txt
}
```

---

## 상태 관리

### 워크플로우 상태 매핑

| Claude Workflow 단계 | Notion 진행현황 | 자동 업데이트 시점 |
|---------------------|----------------|------------------|
| /notion-start 실행 | "리서치중" | 기능 선택 후 |
| /triage 완료 | "기획/디자인" | 워크플로우 추천 후 |
| /major\|/minor\|/micro 시작 | "개발중" | Step 1 완료 후 |
| 코드 작성 중 | "작업중" | 첫 commit 후 |
| 테스트 작성 중 | "테스트중" | test 파일 생성 후 |
| /commit 실행 | "작업완료" | commit 성공 후 |
| /pr 실행 | "테스트완료" | PR 생성 후 |
| PR merge | "배포완료" | merge 감지 후 |
| 작업 종료 | "종료" | 수동 설정 |

### 상태 변경 Hook

```bash
# .claude/hooks/notion-state-tracker.sh

#!/bin/bash

# 상태 변경 함수
update_notion_state() {
  local new_state="$1"
  local page_id=$(get_current_notion_page)

  if [ -n "$page_id" ]; then
    mcp__notion-company__notion-update-page \
      --page_id "$page_id" \
      --command "update_properties" \
      --properties "{\"진행현황\": \"$new_state\"}"

    echo "✅ Notion 상태 업데이트: $new_state"
  fi
}

# Hook 등록
register_workflow_hooks() {
  # /triage 완료 시
  on_triage_complete() {
    update_notion_state "기획/디자인"
  }

  # 워크플로우 시작 시
  on_workflow_start() {
    update_notion_state "개발중"
  }

  # 첫 커밋 시
  on_first_commit() {
    update_notion_state "작업중"
  }

  # 테스트 파일 생성 시
  on_test_created() {
    update_notion_state "테스트중"
  }

  # /commit 시
  on_commit() {
    update_notion_state "작업완료"
  }

  # PR 생성 시
  on_pr_created() {
    local pr_url="$1"
    update_notion_state "테스트완료"

    # 마감일 기록
    local kst_date=$(get_kst_date)
    local page_id=$(get_current_notion_page)

    if [ -n "$page_id" ]; then
      mcp__notion-company__notion-update-page \
        --page_id "$page_id" \
        --command "update_properties" \
        --properties "{
          \"date:마감일:start\": \"$kst_date\",
          \"date:마감일:is_datetime\": 0
        }"
    fi
  }
}
```

---

## 작업내역 자동 기록

### 핵심 변경사항

**기록 시점**: ~~작업 완료 시~~ → **커밋 시마다**

**효과**:
- 여러 명이 협업하거나 한 명이 여러 세션에서 작업해도 모든 작업내역 추적 가능
- 커밋 단위로 작업내역이 누적되어 상세한 이력 관리

### 핵심 작업내용 결정 로직

```bash
# lib/notion-work-history.sh

# 핵심 작업내용 추출
extract_work_summary() {
  local commit_message="$1"

  # 1. Epic/Major/Minor 워크플로우에서 생성된 디렉토리 확인
  local workflow_dir=""

  if [ -d ".specify/epics" ]; then
    # Epic: 가장 최근에 생성된 epic 디렉토리
    workflow_dir=$(ls -t .specify/epics/ | head -1)
    if [ -n "$workflow_dir" ]; then
      echo "$workflow_dir"
      return 0
    fi
  fi

  if [ -d ".specify/features" ]; then
    # Major: 가장 최근에 생성된 feature 디렉토리
    workflow_dir=$(ls -t .specify/features/ | head -1)
    if [ -n "$workflow_dir" ]; then
      echo "$workflow_dir"
      return 0
    fi
  fi

  # 2. 워크플로우 디렉토리가 없는 경우 → 커밋 메시지 분석
  # 커밋 메시지에서 핵심 내용 추출
  local summary=$(echo "$commit_message" | head -1 | sed 's/^[a-z]*: //')
  echo "$summary"
}

# 작업내역 추가 (커밋 시마다 호출)
add_work_history_on_commit() {
  local page_id="$1"
  local commit_message="$2"

  # 커밋 날짜 (한국 시간)
  local commit_date=$(get_kst_date)

  # 핵심 작업내용 추출
  local work_summary=$(extract_work_summary "$commit_message")

  # Notion row의 '시작일' 컬럼 값 조회
  local start_date=$(get_notion_start_date "$page_id")

  # 작업내역 항목 생성 (기능 시작일 - 커밋 날짜)
  local new_history="- $work_summary : $start_date - $commit_date"

  # 기존 페이지 내용 fetch
  local page_content=$(mcp__notion-company__notion-fetch --id "$page_id")

  # 작업내역 섹션 확인
  if echo "$page_content" | grep -q "## **📄** 작업내역"; then
    # 기존 작업내역 섹션에 추가
    mcp__notion-company__notion-update-page \
      --page_id "$page_id" \
      --command "insert_content_after" \
      --selection_with_ellipsis "## **📄** 작업내역..." \
      --new_str "\n$new_history"
  else
    # 작업내역 섹션이 없으면 생성
    mcp__notion-company__notion-update-page \
      --page_id "$page_id" \
      --command "insert_content_after" \
      --selection_with_ellipsis "## 📝 추가 참고사항..." \
      --new_str "\n\n---\n\n## **📄** 작업내역\n\n$new_history"
  fi

  echo "✅ Notion 작업내역 추가: $work_summary ($start_date - $commit_date)"
}

# Notion row의 '시작일' 컬럼 값 조회
get_notion_start_date() {
  local page_id="$1"

  local page_data=$(mcp__notion-company__notion-fetch --id "$page_id")

  # 페이지 속성(properties)에서 '시작일' 컬럼 값 추출
  echo "$page_data" | jq -r '.properties."시작일".date.start // "미정"'
}
```

### 커밋 Hook 통합

```bash
# hooks/post-commit.sh

#!/bin/bash

# 커밋 후 자동 실행되는 Hook

# 현재 작업 중인 Notion 페이지 ID 조회
NOTION_PAGE_ID=$(get_current_notion_page)

if [ -z "$NOTION_PAGE_ID" ]; then
  # Notion 페이지가 연결되어 있지 않으면 종료
  exit 0
fi

# 최신 커밋 메시지 조회
COMMIT_MESSAGE=$(git log -1 --pretty=%B)

# 작업내역 추가
add_work_history_on_commit "$NOTION_PAGE_ID" "$COMMIT_MESSAGE"

# 상태 업데이트
update_notion_state "작업중"
```

### 예시: 작업내역 누적

```markdown
## **📄** 작업내역

- 001-user-authentication-system : 2025-11-18 - 2025-11-18
- 로그인 API 엔드포인트 구현 : 2025-11-18 - 2025-11-19
- JWT 토큰 발급 로직 추가 : 2025-11-18 - 2025-11-19
- 로그인 테스트 케이스 작성 : 2025-11-18 - 2025-11-20
- 토큰 만료 시간 설정 오류 수정 : 2025-11-18 - 2025-11-20
```

**설명**:
- 첫 번째 항목: `/major` 실행으로 생성된 `001-user-authentication-system` 디렉토리명
- 이후 항목들: 각 커밋의 핵심 작업내용 (커밋 메시지 분석)
- 날짜: **'기능 설명' row의 '시작일' 컬럼 값 (고정)** - **해당 커밋 날짜**

---

## 구현 우선순위

### Phase 1: 핵심 기능 (Week 1-2)

1. **Notion 검색 및 선택**
   - `/notion-start` 기본 구현
   - 키워드 검색
   - AskUserQuestion 통합

2. **Notion → /triage 연동**
   - 페이지 내용 파싱
   - /triage 파라미터 구성
   - 워크플로우 실행

3. **시작일 자동 기록**
   - 작업 시작 시 Notion 업데이트
   - KST 시간대 처리
   - 세션 관리 (current-notion-page.txt)

### Phase 2: 상태 추적 및 작업내역 (Week 3)

4. **진행현황 자동 업데이트**
   - Hook 시스템 구축
   - 워크플로우 단계별 상태 매핑
   - 실시간 Notion 업데이트

5. **커밋 시 작업내역 자동 기록**
   - post-commit hook 구현
   - 핵심 작업내용 추출 로직
   - 작업내역 누적

6. **PR 생성 시 마감일 기록**
   - PR hook 구현
   - 마감일 자동 기록

### Phase 3: 역방향 통합 (Week 4)

7. **/notion-add 구현**
   - 유사 기능 검색
   - 템플릿 검증
   - 대화형 정보 수집
   - Notion 페이지 생성

### Phase 4: 고도화 (Week 5+)

8. **대시보드 통합**
   - `/dashboard`에 Notion 통계 표시
   - 진행 중인 작업 목록

9. **일괄 작업 관리**
   - 여러 기능 동시 추적
   - 우선순위 기반 작업 추천

---

## 파일 구조

```
.claude/
├── commands/
│   ├── notion-start.md          # Notion 기반 작업 시작
│   ├── notion-add.md            # 기능정의서 추가
│   └── notion-status.md         # 상태 수동 업데이트
│
├── lib/
│   ├── notion-search.sh         # Notion 검색
│   ├── notion-parser.sh         # 페이지 파싱
│   ├── notion-update.sh         # 페이지 업데이트
│   ├── notion-utils.sh          # 유틸리티 함수
│   ├── notion-template.sh       # 템플릿 검증/생성
│   ├── notion-work-history.sh   # 작업내역 기록 (커밋 시)
│   ├── project-detector.sh      # 프로젝트 환경 감지
│   └── triage-caller.sh         # /triage 호출
│
├── hooks/
│   ├── notion-state-tracker.sh  # 상태 변경 추적
│   ├── post-commit.sh           # 커밋 후 작업내역 기록
│   ├── pr-created.sh            # PR 생성 시
│   └── workflow-completed.sh    # 워크플로우 완료 시
│
├── config/
│   └── notion.json              # Notion 설정
│
├── cache/
│   └── current-notion-page.txt  # 현재 작업 페이지 ID
│
└── specs/
    └── notion-integration-design.md  # 이 문서
```

---

## 테스트 시나리오

### 시나리오 1: 전체 워크플로우 (여러 커밋)

```bash
# 1. 작업 시작
/notion-start "화주 회원 가입 기능"

# 예상 동작:
# - Notion 검색 → "화주 회원 가입" 기능 발견
# - 페이지 내용 파싱
# - 시작일 기록 (2025-11-18)
# - 진행현황: "개발중"
# - /triage 호출 → Major 추천

# 2. 워크플로우 시작
/major
# - 진행현황: "개발중"
# - 디렉토리 생성: .specify/features/001-user-signup

# 3. 첫 번째 커밋
git commit -m "feat: 회원가입 폼 UI 구현"
# - 작업내역 추가: "001-user-signup : 2025-11-18 - 2025-11-18"
# - 진행현황: "작업중"

# 4. 두 번째 커밋
git commit -m "feat: 회원가입 API 연동"
# - 작업내역 추가: "회원가입 API 연동 : 2025-11-18 - 2025-11-19"

# 5. 세 번째 커밋
git commit -m "test: 회원가입 테스트 케이스 추가"
# - 작업내역 추가: "회원가입 테스트 케이스 추가 : 2025-11-18 - 2025-11-19"

# 6. 네 번째 커밋
git commit -m "fix: 이메일 중복 검증 로직 수정"
# - 작업내역 추가: "이메일 중복 검증 로직 수정 : 2025-11-18 - 2025-11-19"

# 7. PR 생성
/pr
# - 마감일 기록 (2025-11-19)
# - 진행현황: "테스트완료"

# 최종 Notion 작업내역:
# - 001-user-signup : 2025-11-18 - 2025-11-18
# - 회원가입 API 연동 : 2025-11-18 - 2025-11-19
# - 회원가입 테스트 케이스 추가 : 2025-11-18 - 2025-11-19
# - 이메일 중복 검증 로직 수정 : 2025-11-18 - 2025-11-20
```

### 시나리오 2: 워크플로우 없이 직접 커밋

```bash
# 1. 작업 시작 (Notion 연결)
/notion-start "로그 레벨 조정"
# - 시작일: 2025-11-20
# - 진행현황: "개발중"

# 2. 직접 코드 수정 및 커밋 (워크플로우 없음)
git commit -m "chore: 프로덕션 로그 레벨을 ERROR로 변경"
# - 작업내역 추가: "프로덕션 로그 레벨을 ERROR로 변경 : 2025-11-20 - 2025-11-20"

# 3. PR 생성
/pr
# - 마감일: 2025-11-20
# - 진행현황: "테스트완료"

# 최종 Notion 작업내역:
# - 프로덕션 로그 레벨을 ERROR로 변경 : 2025-11-20 - 2025-11-20
```

### 시나리오 3: 여러 명이 협업

```bash
# 개발자 A - 세션 1
/notion-start "결제 시스템 구축"
# - Notion 페이지 ID: abc123
# - .claude/cache/current-notion-page.txt 에 저장

git commit -m "feat: 결제 요청 API 구현"
# - 작업내역 추가

# 개발자 B - 세션 2 (같은 기능)
# 수동으로 Notion 페이지 연결
echo "abc123" > .claude/cache/current-notion-page.txt

git commit -m "feat: 결제 결과 처리 로직 추가"
# - 같은 Notion 페이지에 작업내역 추가

# 개발자 A - 세션 3
git commit -m "test: 결제 통합 테스트 작성"
# - 같은 Notion 페이지에 작업내역 추가

# 최종 Notion 작업내역:
# - 결제 요청 API 구현 : 2025-11-18 - 2025-11-18
# - 결제 결과 처리 로직 추가 : 2025-11-18 - 2025-11-19
# - 결제 통합 테스트 작성 : 2025-11-18 - 2025-11-20
```

---

## 향후 확장 가능성

1. **Slack 알림 통합**
   - 작업 시작/완료 시 Slack 알림
   - 마감일 임박 알림

2. **자동 스프린트 관리**
   - 진행 중인 작업을 스프린트에 자동 할당
   - 스프린트별 진행률 계산

3. **메트릭 수집**
   - 평균 작업 소요 시간
   - 우선순위별 완료율
   - 기능 그룹별 작업량
   - 커밋 빈도 분석

4. **AI 기반 기능 추천**
   - 연관 기능 자동 제안
   - 비슷한 과거 작업 참조

5. **작업내역 분석**
   - 가장 많이 수정된 기능
   - 작업 패턴 분석 (시간대, 요일)

---

## 주의사항

### 보안

1. **Notion API 토큰 관리**
   - MCP 서버 설정에서 관리
   - 절대 코드에 하드코딩하지 않음

2. **권한 확인**
   - 페이지 수정 권한 사전 확인
   - 에러 처리 필수

### 성능

1. **캐싱**
   - 자주 조회하는 데이터 로컬 캐싱
   - 검색 결과 임시 저장
   - 현재 작업 페이지 ID 캐싱

2. **Rate Limiting**
   - Notion API 호출 제한 고려
   - 커밋마다 API 호출하므로 주의
   - 필요 시 배치 처리

### 에러 처리

1. **Notion API 장애**
   - 재시도 로직 구현
   - 로컬 상태 백업

2. **데이터 정합성**
   - 업데이트 실패 시 롤백
   - 로그 기록

3. **커밋 Hook 실패**
   - Hook 실패 시에도 커밋은 성공
   - 실패 로그 기록 및 재시도 옵션

---

## 변경 이력

### v1.0.1 (2025-11-20)
- **작업내역 기록 시점 변경**: 작업 완료 시 → 커밋 시마다
- **작업내역 날짜 형식 확정**:
  - 시작일: '기능 설명' row의 '시작일' 컬럼 값 (고정)
  - 마감일: 해당 커밋 날짜
- **핵심 작업내용 결정 로직 추가**:
  - Epic/Major/Minor 워크플로우: 디렉토리명 사용
  - 직접 커밋: 커밋 메시지 분석
- **post-commit hook 추가**: 자동 작업내역 기록
- **시나리오 업데이트**: 여러 커밋, 협업 사례 추가

### v1.0.0 (2025-11-20)
- 초기 설계 문서 작성

---

**문서 버전**: 1.0.1
**최종 수정**: 2025-11-20
**다음 단계**: Phase 1 구현 시작
