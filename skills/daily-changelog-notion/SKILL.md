---
name: daily-changelog-notion
description: Git 변경사항을 Notion 페이지로 자동 문서화합니다. 특정 날짜/기간의 커밋을 수집하고 형제 페이지 포맷에 맞춰 새 페이지를 생성합니다. "오늘 변경사항 정리", "이번 주 changelog" 등의 요청에 자동 활성화됩니다.
allowed-tools: Bash(git log*), Bash(git diff*), mcp__notion-personal__*
---

# Daily Changelog Notion Skill

Git 변경사항을 Notion에 자동으로 문서화하는 Skill입니다.

**changelog-writer 에이전트와 함께 사용됩니다.**

## 사용 시점

다음과 같은 요청에 자동으로 활성화됩니다:

- "오늘 변경사항을 Notion에 정리해줘"
- "이번 주 changelog 작성해줘"
- "어제 작업 내용 Notion에 올려줘"
- "2025-01-15 변경사항 문서화해줘"

## 작업 흐름

### 1. 날짜 범위 파싱

사용자 요청에서 날짜 범위를 추출합니다.

**지원 형식**:
- "오늘" → 오늘 00:00 ~ 현재
- "어제" → 어제 전체
- "이번 주" → 이번 주 월요일 ~ 현재
- "2025-01-15" → 특정 날짜
- "2025-01-01~2025-01-15" → 범위

상세 로직: [`reference/date-parsing.md`](reference/date-parsing.md)

### 2. Git 커밋 수집

```bash
# 커밋 목록
git log --since="날짜" --until="날짜" \
  --pretty=format:"%h|%an|%s|%ad" --date=format:"%Y-%m-%d %H:%M"

# 변경 통계
git diff --stat 시작..끝

# 파일 목록
git diff --name-status 시작..끝
```

### 3. 커밋 분류

Commit message prefix 기반:
- `feat:` → ✨ Features
- `fix:` → 🐛 Bug Fixes
- `refactor:` → ♻️ Refactoring
- `test:` → ✅ Tests
- `docs:` → 📝 Documentation

상세 규칙: [`reference/commit-classification.md`](reference/commit-classification.md)

### 4. Notion 페이지 검색

```javascript
// 부모 페이지 검색
const parent = await notion-search({
  query: "변경 이력",
  query_type: "internal"
});
```

### 5. 형제 페이지 포맷 파싱

```javascript
// 최근 형제 페이지 조회
const siblings = await notion-fetch({ id: parent.id });
const latest = siblings.children[0];

// 포맷 분석
const format = await notion-fetch({ id: latest.id });
```

### 6. 마크다운 생성

파싱한 포맷에 맞춰 변경사항을 마크다운으로 변환합니다.

템플릿: [`templates/changelog-format.md`](templates/changelog-format.md)

### 7. Notion 페이지 생성

```javascript
await notion-create-pages({
  parent: { page_id: parent.id },
  pages: [{
    properties: { title: "2025-11-06 변경사항" },
    content: markdown
  }]
});
```

## 포맷 예시

기본 템플릿:

```markdown
## 📅 2025-11-06 (수)

### 👥 Contributors
- 홍길동 (3 commits)
- 김철수 (2 commits)

### ✨ Features (2)
- 차량 정보 입력 화면 추가 ([abc1234](URL))
  - 변경 파일: 5개 (+120/-0)
- 운송 일정 선택 기능 구현 ([def5678](URL))

### 🐛 Bug Fixes (3)
- 주소 검색 null 에러 수정 ([ghi9012](URL))
- 모바일 레이아웃 오류 수정 ([jkl3456](URL))
- 타입 에러 수정 ([mno7890](URL))

### 📊 Statistics
- Total Commits: 5
- Files Changed: 12
- Lines: +150 / -40
```

## 주간 요약

`weekly` 모드 활성화 시 주간 요약을 생성합니다.

템플릿: [`templates/weekly-summary-format.md`](templates/weekly-summary-format.md)

**추가 정보**:
- 🎯 Highlights: Major 커밋만 추출
- 👥 Contributor Ranking: 커밋 수 기준 순위
- 📈 Trend: 전주 대비 변화

## 사용 예시

[`examples/daily-example.md`](examples/daily-example.md) 참조

```
사용자: "오늘 변경사항을 Notion에 정리해줘"

Step 1: 날짜 범위
→ 2025-11-06 00:00 ~ 23:59

Step 2: 커밋 수집
→ 5개 커밋 발견

Step 3: Notion 검색
→ "변경 이력" 페이지 발견

Step 4: 포맷 파싱
→ 형제 페이지 포맷 적용

Step 5: 페이지 생성
→ ✅ 완료
```

## 참조 파일

- [날짜 파싱 로직](reference/date-parsing.md): 날짜 범위 추출 방법
- [커밋 분류 규칙](reference/commit-classification.md): 타입별 분류 상세
- [Notion API 가이드](reference/notion-api-guide.md): MCP 사용법
- [일일 포맷 템플릿](templates/changelog-format.md): 기본 구조
- [주간 포맷 템플릿](templates/weekly-summary-format.md): 주간 요약 구조
- [일일 예시](examples/daily-example.md): 실행 예시
- [주간 예시](examples/weekly-example.md): 주간 요약 예시

## 제한 사항

- Notion 페이지 생성만 가능 (수정 불가)
- 코드 변경 불가
- Git 히스토리 변경 불가
