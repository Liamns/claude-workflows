# Notion Sync Commits

**Version**: 3.4.0
**Category**: Notion Integration
**Description**: Manually sync pending commits to Notion worklog subpages

---

## 🤖 Claude를 위한 실행 지시사항

**이 명령어가 호출되면 다음 단계를 정확히 수행하세요:**

### Step 1: 동기화 스크립트 로드
```bash
source .claude/lib/notion-sync-commits.sh
```

### Step 2: Pending 커밋 확인
```bash
cat .claude/cache/pending-commits.json | python3 -c "import json, sys; print(f'{len(json.load(sys.stdin))} pending commits')"
```

사용자에게 pending 커밋 개수를 알려주세요.

### Step 3: 동기화 실행

**중요**: 이 단계에서는 실제로 다음 작업을 수행해야 합니다:

1. `.claude/cache/pending-commits.json` 파일을 읽어서 page_id별로 그룹화
2. 각 page_id에 대해:
   - Notion MCP를 사용하여 parent 페이지 fetch
   - "작업로그" 제목의 서브페이지 검색 (📑 이모지 제외)
   - 없으면 새 서브페이지 생성:
     * 타이틀: "작업로그" (이모지 제외)
     * 아이콘: 📑 이모지 설정
     * 초기 컨텐츠: 테이블 템플릿 포함
     * 생성 후 parent 페이지에서 서브페이지 바로 위에 구분선(---) 추가
   - 있으면 기존 서브페이지 ID 사용
3. 각 커밋을 테이블 행으로 변환:
   - `format_worklog_table_entry()` 함수 사용
   - 날짜/시간, 커밋 해시(7자), 작업 유형, 주요 변경사항, 파일 수, 변경량, 파일 목록
4. Notion MCP `update-page`로 테이블에 행 추가
5. pending-commits.json 초기화

### Step 4: 결과 보고

동기화 완료 후 사용자에게 다음 정보를 제공:
- 동기화된 커밋 개수
- 업데이트된 Notion 페이지 URL
- 실패한 커밋이 있다면 `.claude/cache/failed-commits.json` 안내

---

## 📖 사용자 가이드

## Usage

```bash
/notion-sync-commits
```

## What it does

이 명령어는 pending 큐에 쌓인 커밋들을 Notion의 "작업로그" 서브페이지(📑 아이콘)로 동기화합니다:

1. `.claude/cache/pending-commits.json` 읽기
2. page_id별로 커밋 그룹화
3. 각 페이지의 "작업로그" 서브페이지 생성 또는 검색
   - 새 페이지 생성 시: 타이틀 "작업로그", 아이콘 📑, 위에 구분선 추가
4. 커밋 정보를 HTML 테이블 형식으로 변환
5. 테이블에 새 행 추가
6. Pending 큐 초기화

## When to use

- **자동 동기화**: Claude 시작 시 자동으로 실행됩니다
- **수동 동기화**: 다음과 같은 경우 수동으로 실행:
  - 이전 동기화 실패 시 재시도
  - 즉시 Notion에 반영하고 싶을 때
  - 동기화 상태 확인

## Example

```bash
# 1. 여러 커밋 생성
git commit -m "feat: Add login feature"
git commit -m "fix: Fix validation bug"
git commit -m "docs: Update README"

# 2. Pending 큐 확인
cat .claude/cache/pending-commits.json | jq 'length'
# → 3

# 3. 수동 동기화
/notion-sync-commits

# 4. 결과 확인
cat .claude/cache/pending-commits.json
# → []
```

## Worklog Table Format

동기화된 커밋은 다음 형식의 테이블로 기록됩니다:

| 날짜/시간 | 커밋 | 유형 | 주요 변경사항 | 파일 수 | 변경량 | 파일 목록 |
|----------|------|------|--------------|---------|--------|----------|
| 2025-11-20 14:30 | abc123d | 기능 추가 | Add login feature | 3 | +120/-15 | src/api/auth.ts<br>src/types/user.ts |

## Error Handling

- 동기화 실패 시 실패한 커밋은 `.claude/cache/failed-commits.json`에 저장됩니다
- 다음 동기화 시 자동으로 재시도됩니다
- 에러 로그는 stderr로 출력됩니다

## Related Commands

- `/notion-start` - 새 기능 개발 시작 (Notion 페이지 생성)
- `/notion-add` - 기존 기능정의서와 연결

## Notes

- Post-commit hook이 활성화되어 있어야 합니다
- Notion MCP 서버가 설정되어 있어야 합니다
- 서브페이지는 자동으로 생성되며 중복 생성되지 않습니다
