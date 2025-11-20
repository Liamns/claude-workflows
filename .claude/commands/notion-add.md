# /notion-add - Notion 기능정의서 추가

**Claude를 위한 필수 지시사항:**

이 명령어가 실행될 때 반드시 다음 단계를 **순서대로** 따라야 합니다:

1. Notion 데이터베이스에서 유사 기능 검색
2. 중복 확인 및 사용자 선택 (AskUserQuestion)
3. 필수 정보 수집 (AskUserQuestion)
   - 채널 선택 → 해당 데이터 소스에서 **실제 사용 중인 기능 그룹 조회**
   - 조회한 기능 그룹으로 선택지 제공
4. 템플릿 기반 페이지 생성
5. 생성된 페이지 URL 반환

**절대로 사용자 확인 없이 페이지를 생성하지 마세요.**

**중요: 기능 그룹은 반드시 선택된 채널의 데이터 소스에서 조회한 실제 값만 제안하세요.**

---

## Overview

Notion 데이터베이스에 새로운 기능정의서를 추가합니다. 유사 기능 검색을 통해 중복을 방지하고, 대화형 인터페이스로 필수 정보를 수집합니다.

## Output Language

**IMPORTANT**: 사용자와의 모든 대화는 반드시 **한글로 작성**해야 합니다.

## Usage

```bash
/notion-add [기능명]
/notion-add --interactive  # 대화형 모드
```

### 옵션

| 옵션 | 설명 | 기본값 |
|------|------|--------|
| `기능명` | 추가할 기능의 이름 | 필수 |
| `--interactive` | 기능명 없이 대화형으로 입력 | `false` |

## Workflow

### Step 1: 유사 기능 검색

**목적**: 중복 기능 방지 및 기존 기능 활용

```python
# Notion semantic search 실행 (기본 데이터 소스: 화주)
results = mcp__notion-company__notion-search({
  "query": feature_name,
  "query_type": "internal",
  "data_source_url": "collection://2ac47c08-6985-811b-a177-000b9ea43547"
})

# 상위 3개 결과 표시
similar_features = results[:3]
```

### Step 2: 중복 확인 (AskUserQuestion)

**목적**: 유사 기능 발견 시 사용자 선택

유사 기능이 발견된 경우:

```json
{
  "questions": [
    {
      "question": "다음 유사 기능이 발견되었습니다. 어떻게 하시겠습니까?\n\n1. [기존 기능 1]\n2. [기존 기능 2]\n3. [기존 기능 3]",
      "header": "유사 기능",
      "multiSelect": false,
      "options": [
        {
          "label": "기존 기능 수정",
          "description": "위 기능 중 하나를 선택하여 수정"
        },
        {
          "label": "새로운 기능 추가",
          "description": "유사하지만 다른 기능이므로 새로 추가"
        }
      ]
    }
  ]
}
```

**분기 처리**:
- "기존 기능 수정" 선택 시 → 해당 페이지 URL 반환 및 `/notion-start` 제안
- "새로운 기능 추가" 선택 시 → Step 3으로 진행

### Step 3: 필수 정보 수집 (AskUserQuestion)

**목적**: 템플릿 생성에 필요한 정보 수집

**3.1. 채널 선택**
```json
{
  "questions": [
    {
      "question": "어떤 채널의 기능인가요?",
      "header": "채널",
      "multiSelect": false,
      "options": [
        {
          "label": "화주",
          "description": "화주용 애플리케이션"
        },
        {
          "label": "어드민",
          "description": "관리자용 애플리케이션"
        }
      ]
    }
  ]
}
```

**데이터 소스 매핑**:
- **화주** → `collection://2ac47c08-6985-811b-a177-000b9ea43547`
- **어드민** → `collection://35d8c49c-a343-4bb4-a62a-8a418b8abca5`

**3.2. 우선순위 선택**
```json
{
  "questions": [
    {
      "question": "우선순위는 어떻게 되나요?",
      "header": "우선순위",
      "multiSelect": false,
      "options": [
        {
          "label": "P0",
          "description": "론칭 필수 기능"
        },
        {
          "label": "P1",
          "description": "중요하지만 필수는 아님"
        },
        {
          "label": "P2",
          "description": "여유 있으면 추가"
        },
        {
          "label": "P3",
          "description": "이번 버전에서 제외"
        }
      ]
    }
  ]
}
```

**3.3. 기능 그룹 조회 및 선택**

**CRITICAL**: 기능 그룹은 반드시 다음 순서로 진행:

1. 선택된 채널의 데이터 소스에서 기존 페이지들을 검색
2. "기능 그룹" 필드의 고유 값들을 추출
3. 추출한 값들을 AskUserQuestion의 옵션으로 제공

```python
# 1. 선택된 채널의 데이터 소스에서 페이지 조회
pages = mcp__notion-company__notion-search({
  "query": "",  # 빈 쿼리로 전체 조회
  "query_type": "internal",
  "data_source_url": selected_data_source_url
})

# 2. 각 페이지에서 "기능 그룹" 값 추출
feature_groups = set()
for page in pages:
  page_data = mcp__notion-company__notion-fetch({"id": page.id})
  # properties에서 "기능 그룹" 값 추출
  group = extract_property(page_data, "기능 그룹")
  if group:
    feature_groups.add(group)

# 3. 고유 값들을 정렬하여 옵션 생성
options = [{"label": group, "description": ""} for group in sorted(feature_groups)]

# 4. AskUserQuestion으로 제공
AskUserQuestion({
  "questions": [{
    "question": "어떤 기능 그룹에 속하나요?",
    "header": "기능 그룹",
    "multiSelect": false,
    "options": options + [{"label": "새 그룹 생성", "description": "위 목록에 없는 새로운 그룹"}]
  }]
})
```

**새 그룹 생성 선택 시**:
- 추가 질문으로 새 그룹명 입력 받기

**3.4. 기능 목적 입력**

간단한 텍스트 입력으로 기능의 목적을 수집합니다.

```json
{
  "questions": [
    {
      "question": "기능의 목적을 간단히 설명해주세요 (1-2문장)",
      "header": "기능 목적",
      "multiSelect": false,
      "options": [
        {"label": "직접 입력", "description": ""}
      ]
    }
  ]
}
```

### Step 4: 페이지 생성

**목적**: 수집한 정보로 Notion 페이지 생성

```python
# 템플릿 내용 생성
content = f"""## 📌 기본 정보
- **도메인**: {domain}
- **채널**: {channel}
- **우선순위**: {priority}
- **수행자**:

---

## 🎯 기능 목적
{purpose}

---

## 📋 필수 정보
(상세 내용을 작성해주세요)

---

## 🔄 비즈니스 로직
1.

---

## 🔗 연관 기능
(관련된 다른 기능들을 나열해주세요)

---

## 📝 TODO
- [TODO-BIZ]
- [TODO-TECH]

---

## 📅 작업내역
"""

# Notion 페이지 생성
mcp__notion-company__notion-create-pages({
  "parent": {"data_source_id": data_source_id},
  "pages": [{
    "properties": {
      "기능 설명": feature_name,
      "우선순위": priority,
      "기능 그룹": feature_group,
      "\b진행현황": "대기"
    },
    "content": content
  }]
})
```

### Step 5: 결과 반환

**출력 메시지 예시**:
```
✅ Notion 페이지 생성 완료!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📄 기능명: 사용자 프로필 이미지 업로드
🔗 URL: https://www.notion.so/...
📊 우선순위: P0
🏷️ 기능 그룹: 회원 관리
📱 채널: 화주

다음 단계:
  - 페이지 내용을 상세히 작성
  - /notion-start로 작업 시작
```

---

## Examples

### Example 1: 기본 사용

```bash
/notion-add "사용자 프로필 이미지 업로드"
```

**Output:**
```
🔍 유사 기능 검색 중...

유사 기능이 발견되지 않았습니다.

📝 필수 정보를 입력해주세요:

[AskUserQuestion: 채널]
→ 선택: 화주

🔍 화주 채널의 기능 그룹을 조회 중...

[AskUserQuestion: 우선순위]
→ 선택: P0

[AskUserQuestion: 기능 그룹]
→ 옵션: 회원 관리, 주문 요청, 결제, 알림
→ 선택: 회원 관리

[AskUserQuestion: 기능 목적]
→ 입력: 사용자가 프로필 이미지를 업로드하고 변경할 수 있는 기능

✅ Notion 페이지 생성 완료!
🔗 URL: https://www.notion.so/...
```

### Example 2: 유사 기능 발견

```bash
/notion-add "회원 가입 개선"
```

**Output:**
```
🔍 유사 기능 검색 중...

⚠️ 유사 기능 발견:
1. 회원 가입 기능 (P0, 대기)
2. 회원 가입 유효성 검증 (P1, 개발중)

[AskUserQuestion: 중복 확인]
→ 선택: 기존 기능 수정

📄 기존 기능을 사용합니다:
🔗 URL: https://www.notion.so/...

💡 팁: /notion-start "회원 가입 기능"으로 작업을 시작하세요
```

---

## Error Handling

### "No Notion workspace found"
- **원인**: Notion MCP 서버가 연결되지 않음
- **해결**: MCP 설정 확인

### "Duplicate feature"
- **원인**: 완전히 동일한 이름의 기능이 이미 존재
- **해결**: 사용자에게 확인 후 기존 페이지 사용 또는 다른 이름 제안

### "Missing required fields"
- **원인**: 필수 정보가 수집되지 않음
- **해결**: 자동으로 AskUserQuestion 재시도

### "No feature groups found"
- **원인**: 데이터 소스에 기존 페이지가 없음
- **해결**: "새 그룹 생성" 옵션만 제공

---

## Related Commands

- `/notion-start` - 생성된 기능으로 작업 시작
- `/major` - 워크플로우와 통합하여 사용

---

**Version**: 3.4.0
**Last Updated**: 2025-11-20
