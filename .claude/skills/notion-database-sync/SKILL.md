---
name: notion-database-sync
description: Notion 데이터베이스와 프로젝트 데이터 동기화 패턴을 제공합니다. 페이지 생성, 속성 업데이트, 쿼리 패턴을 안내합니다. documenter-unified에서 활용됩니다.
allowed-tools: Read, mcp__notion-personal__*, mcp__notion-company__*
---

# Notion Database Sync Skill

Notion 데이터베이스와 프로젝트 데이터를 동기화하는 패턴을 제공합니다.

## 사용 시점

다음과 같은 상황에서 활성화됩니다:

- 프로젝트 데이터를 Notion에 기록
- 변경 이력 자동 문서화
- 작업 진행 상황 추적
- Notion 기반 대시보드 업데이트

## 핵심 동기화 패턴

### 1. 데이터베이스 조회 및 페이지 생성

**데이터베이스 스키마 확인:**
```markdown
## 1단계: 데이터베이스 fetch로 스키마 확인

mcp__notion-personal__notion-fetch 또는 mcp__notion-company__notion-fetch 사용:
- id: 데이터베이스 URL 또는 ID

결과에서 확인:
- data-source URL (collection://...)
- 속성 이름과 타입
- 뷰 정보
```

**페이지 생성 패턴:**
```markdown
## 페이지 생성 시 필수 확인사항

1. 데이터베이스가 단일 data source인 경우:
   - database_id 사용 가능

2. 다중 data source인 경우:
   - 반드시 data_source_id 사용
   - fetch 결과의 collection:// URL에서 ID 추출

3. 속성 형식:
   - 일반 텍스트: "속성명": "값"
   - 숫자: "속성명": 123
   - 체크박스: "속성명": "__YES__" 또는 "__NO__"
   - 날짜: "date:속성명:start": "YYYY-MM-DD"
   - 날짜(datetime): "date:속성명:is_datetime": 1
```

### 2. 변경 이력 동기화 패턴

**일일 변경 이력:**
```markdown
## 일일 Changelog 생성 워크플로우

1. Git 커밋 수집
   - git log --since="YYYY-MM-DD" --until="YYYY-MM-DD"
   - 변경된 파일 수, 추가/삭제 라인 수

2. 형제 페이지 형식 분석
   - 기존 changelog 페이지 fetch
   - 제목 형식, 섹션 구조 파악

3. 새 페이지 생성
   - 동일한 형식으로 내용 구성
   - 날짜별 정렬 유지
```

**주간 요약:**
```markdown
## 주간 요약 패턴

내용 구조:
# YYYY년 MM월 W주차 요약

## 📊 통계
- 총 커밋: N개
- 변경 파일: N개
- 추가: +NNN 라인
- 삭제: -NNN 라인

## 🎯 완료된 작업
- [ ] 작업 1
- [ ] 작업 2

## 🔄 진행 중
- 작업 A (진행률)

## 📋 다음 주 계획
- 계획 항목
```

### 3. 작업 추적 동기화

**Task 상태 업데이트:**
```markdown
## Task 데이터베이스 업데이트 패턴

1. 작업 시작 시:
   - Status: "진행중" 또는 "In Progress"
   - date:Started:start: 시작 날짜

2. 작업 완료 시:
   - Status: "완료" 또는 "Done"
   - date:Completed:start: 완료 날짜

3. 블로커 발생 시:
   - Status: "차단됨" 또는 "Blocked"
   - Blocker 속성에 이유 기록
```

### 4. 프로젝트 메트릭 동기화

**메트릭 대시보드 업데이트:**
```markdown
## 메트릭 페이지 업데이트 패턴

수집 메트릭:
- 코드 라인 수
- 테스트 커버리지
- 빌드 성공률
- 에러 발생 횟수

업데이트 주기:
- 일일: 커밋 통계
- 주간: 종합 메트릭
- 월간: 트렌드 분석
```

### 5. 릴리즈 노트 동기화

**릴리즈 페이지 생성:**
```markdown
## 릴리즈 노트 형식

# v{버전} 릴리즈 노트

## 📅 릴리즈 일자
YYYY-MM-DD

## ✨ 새 기능
- 기능 1 설명
- 기능 2 설명

## 🐛 버그 수정
- 수정 1 설명
- 수정 2 설명

## 🔧 개선사항
- 개선 1 설명

## 💥 Breaking Changes
- 변경사항 및 마이그레이션 가이드

## 📦 의존성 업데이트
- 패키지 A: v1 → v2
```

## MCP 도구 사용 가이드

### notion-search
```markdown
용도: 페이지/데이터베이스 검색
파라미터:
- query: 검색어
- query_type: "internal" (기본) 또는 "user"
- filters: 날짜 범위, 생성자 필터
```

### notion-fetch
```markdown
용도: 페이지/데이터베이스 상세 조회
파라미터:
- id: 페이지 URL 또는 UUID
결과: Notion-flavored Markdown 형식
```

### notion-create-pages
```markdown
용도: 새 페이지 생성
필수 확인:
1. 부모 타입 (page_id, database_id, data_source_id)
2. 속성 이름과 타입 정확히 일치
3. 날짜/체크박스 등 특수 형식 준수
```

### notion-update-page
```markdown
용도: 기존 페이지 수정
명령 유형:
- update_properties: 속성만 수정
- replace_content: 전체 내용 교체
- replace_content_range: 부분 교체
- insert_content_after: 내용 삽입
```

## 동기화 워크플로우

### 자동 동기화 트리거

```markdown
1. 커밋 후 자동 실행
   - pre-commit hook 또는 post-commit hook
   - 변경 사항 자동 기록

2. PR 머지 시
   - 릴리즈 노트 자동 생성
   - 변경 이력 업데이트

3. 일일 크론
   - 당일 변경 사항 요약
   - 다음 날 아침 Notion에 기록

4. 수동 실행
   - /changelog 명령어
   - 특정 기간 지정 가능
```

## 에러 처리

```markdown
## 일반적인 에러와 해결책

1. "Property not found"
   - fetch로 스키마 재확인
   - 속성 이름 대소문자 확인

2. "Invalid parent"
   - 다중 data source인 경우 data_source_id 사용
   - database_id 대신 정확한 collection:// URL 사용

3. "Permission denied"
   - 워크스페이스 접근 권한 확인
   - 공유 설정 확인
```

## 검토 체크리스트

- [ ] 데이터베이스 스키마 확인
- [ ] 속성 형식 올바르게 적용
- [ ] 기존 페이지 형식과 일관성 유지
- [ ] 에러 처리 구현
- [ ] 중복 생성 방지 로직

## 연동 Agent/Skill

- **documenter-unified**: 변경사항 문서화
- **daily-changelog-notion**: 일일 변경 이력
- **commit-guard**: 커밋 메시지 연동

## 사용 예시

```
사용자: "오늘 작업 내용을 Notion에 기록해줘"

1. Git 커밋 수집
2. 기존 changelog 형식 확인
3. notion-database-sync 패턴 적용
4. 새 페이지 생성
5. 결과 보고
```
