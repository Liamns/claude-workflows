# AI 프롬프트 템플릿: 문서 요약 생성

이 템플릿은 계획 문서(spec.md, plan.md, tasks.md)를 300자 이내로 요약하기 위한 AI 프롬프트입니다.

## 사용 방법

```bash
# summary-generator.sh에서 사용 예시
local content=$(cat "$file_path")
local prompt=$(cat .claude/lib/document-preview/prompts/summarize.md)
prompt="${prompt//\$\{content\}/$content}"
```

## 프롬프트 템플릿

---

다음 계획 문서를 300자 이내로 요약하세요:

**요구사항:**
1. **Overview 섹션의 핵심 내용 포함**: 문서의 목적과 배경을 1-2 문장으로 표현
2. **상위 3개 Functional Requirements 포함**: FR-001, FR-002, FR-003 중심으로 핵심 기능 나열
3. **완전한 문장으로 끝내기**: 중간에 잘린 문장 금지 (마침표, 물음표, 느낌표로 끝내기)
4. **언어 자동 감지**: 한글 문서는 한글로, 영어 문서는 영어로 요약
5. **정확히 300자 이내**: 공백 포함 300자 초과 금지

**출력 형식:**
- 간결하고 명확한 문장
- 기술 용어는 원어 그대로 사용 (예: UX, AI, FR)
- 불필요한 수식어 제거

**문서 내용:**
```
${content}
```

**요약:**

---

## 예시

### 예시 1: 한글 문서 (spec.md)

**입력:**
```markdown
# Planning Document UX Improvement

## Overview
이 기능은 계획 문서 생성 시 AI 기반 요약과 사용자 동의 요청을 추가하여 UX를 개선합니다.

## Functional Requirements
- FR-001: 문서 요약 생성 (최대 300자)
- FR-002: 요약과 전문을 구분하여 표시
- FR-003: 파일 생성 전 사용자 권한 요청
- FR-004: 사용자 수정 요청 허용
- FR-005: 문서별 독립적 확인
```

**예상 출력:**
```
계획 문서 생성 시 AI 기반 요약과 사용자 동의 요청을 추가하여 UX를 개선하는 기능입니다. 주요 기능: (1) 문서 요약 생성(최대 300자), (2) 요약과 전문 구분 표시, (3) 파일 생성 전 사용자 권한 요청. 사용자는 수정을 요청할 수 있으며 문서별로 독립적으로 확인합니다.
```
**글자 수:** 148자 (✅ 300자 이내)

### 예시 2: 영어 문서 (spec.md)

**입력:**
```markdown
# API Performance Optimization

## Overview
This feature optimizes API response time by implementing caching and query optimization.

## Functional Requirements
- FR-001: Implement Redis caching layer
- FR-002: Optimize database queries with indexing
- FR-003: Add request batching for multiple API calls
- FR-004: Monitor performance metrics
```

**예상 출력:**
```
This feature optimizes API response time through caching and query optimization. Key features: (1) Redis caching layer, (2) database query optimization with indexing, (3) request batching for multiple API calls, (4) performance metrics monitoring.
```
**글자 수:** 238자 (✅ 300자 이내)

### 예시 3: 엣지 케이스 - 매우 짧은 문서

**입력:**
```markdown
# Quick Fix

## Overview
Bug fix for login error.

## Functional Requirements
- FR-001: Fix authentication token validation
```

**예상 출력:**
```
Bug fix for login error. Main feature: Fix authentication token validation.
```
**글자 수:** 77자 (✅ 300자 이내, 그대로 반환)

## 검증 규칙

1. **길이 체크**: `${#summary} -le 300`
2. **문장 완성도**: 마지막 문자는 `[.!?]` 또는 `...`로 끝나야 함
3. **빈 출력 금지**: 최소 1자 이상
4. **포맷 유지**: 요약에서는 마크다운 구문이 제거될 수 있음

## 에러 처리

- **내용 < 300자**: 그대로 반환 (요약 불필요)
- **AI 실패**: 처음 300자 + "..."로 폴백
- **빈 내용**: 에러 코드 11 반환 (ERR_EMPTY_CONTENT)
- **잘못된 형식**: 에러 코드 10 반환 (ERR_SUMMARY_GENERATION)

## 통합 정보

**사용처:**
- `summary-generator.sh` - 메인 요약 생성 함수
- `major.md` - Step 6 (spec.md), Step 12 (plan.md), Step 13 (tasks.md)
- `epic.md` - Epic/roadmap 문서 생성

**의존성:**
- Claude API (내부 컨텍스트)
- `truncate_to_sentence()` 함수 (문장 경계 감지)

**토큰 사용량:**
- 예상: 요약 생성당 500-800 토큰
- 최적화: 단일 패스 생성 (반복 개선 없음)
