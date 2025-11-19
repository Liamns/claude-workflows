# /minor - Minor 워크플로 (Incremental Updates)

## Overview

Streamlined workflow for bug fixes, refactoring, and incremental improvements with 75% token savings through focused analysis and minimal overhead.

## Output Language

**IMPORTANT**: 사용자나 동료가 확인하는 모든 문서와 출력은 반드시 **한글로 작성**해야 합니다.

**한글 작성 대상:**
- fix-analysis.md - 문제 분석 및 솔루션 문서 전체
- 진행 상황 메시지
- 에러 메시지 및 경고
- 분석 결과 및 권장사항

**영어 유지:**
- 코드, 변수명, 함수명, 파일 경로
- 기술 용어
- 명령어

**예시 문서 구조:**
```markdown
# Fix Analysis: 로그인 널 포인터 에러

## Issue
**설명**: 사용자 로그인 시 널 포인터 에러 발생
**심각도**: High
**복잡도**: 5/15

## Root Cause
**원인**: LoginForm.tsx 45번 줄에서 user.credentials 널 체크 누락
**영향 범위**: 로그인 기능 전체
...
```

This command:
1. **Analyzes Issue**: Identifies root cause and affected components
2. **Searches Reusable Patterns**: Finds similar fixes and existing utilities
3. **Generates Solution**: Creates minimal, focused implementation plan
4. **Validates Quality**: Ensures related tests pass and no regressions
5. **Maintains Consistency**: Verifies coding standards and architecture compliance

**Key Features:**
- 75% token savings through smart-cache and focused scope
- Automatic reusability pattern detection
- Minimal quality gates (related tests only)
- Fast turnaround (< 1 day implementation)
- No breaking changes allowed
- Constitution compliance validation

## Usage

```bash
/minor
```

The command will:
- Gather issue description interactively
- **Ask if you want to create a new branch** (optional)
- **Ask for merge target branch** (e.g., main, develop)
- Analyze root cause
- Search for reusable solutions
- Generate fix-analysis.md with implementation plan
- Validate against project rules

### Branch Strategy

- **Branch Creation**: 실행 시 생성 여부 물어봄
- **Branch Name**: `NNN-issue-name` (예: `042-login-null-pointer`)
- **Merge Target**: 실행 시 물어봄 (main, develop 등)

### Prerequisites

- Git repository initialized
- Architecture configured (run `/start` first)
- Constitution file: `.specify/memory/constitution.md`
- Quality gates: `.claude/workflow-gates.json`

## 사용 시나리오

### 버그 수정

```bash
/minor

# 적합한 버그:
- 널 포인터 에러
- 타입 에러
- 로직 오류
- UI 버그
- 성능 이슈 (국소적)

# 부적합한 버그:
- 아키텍처 문제 → /major 사용
- 여러 파일에 걸친 복잡한 버그 → /major
- 신규 기능 필요한 경우 → /major
```

### 리팩토링

```bash
/minor

# 적합한 리팩토링:
- 중복 코드 제거
- 함수 추출
- 변수명 개선
- 타입 개선
- 파일 구조 정리 (소규모)

# 부적합한 리팩토링:
- 전체 아키텍처 변경 → /major
- 여러 레이어에 걸친 리팩토링 → /major
- API 변경 → /major
```

### 소규모 기능 추가

```bash
/minor

# 적합한 기능:
- 체크박스 추가
- 버튼 추가
- 간단한 필터
- 정렬 기능
- UI 개선 (기존 기능 범위 내)

# 부적합한 기능:
- 새로운 페이지 → /major
- 새로운 Entity → /major
- API 엔드포인트 추가 → /major
```

## Implementation

### Architecture

The Minor workflow uses 4 unified agents:
- **architect-unified**: Root cause analysis
- **reusability-enforcer**: Pattern detection (auto-runs)
- **implementer-unified**: Solution generation
- **reviewer-unified**: Constitution validation

### Dependencies

**Required:**
- Unified agents (architect, reusability-enforcer, implementer, reviewer)
- Constitution file: `.specify/memory/constitution.md`
- Quality gates: `.claude/workflow-gates.json`

**Optional:**
- Git repository for diff analysis
- Test suite for validation

### Workflow Steps

**Step 1: Issue Gathering (2-3 min)**
- Collect issue description
- Identify symptoms and error messages
- Determine affected components
- Output: Issue summary

**Step 2: Root Cause Analysis (3-5 min)**
- Analyze code to find source of issue
- Identify files and lines affected
- Determine scope of change
- Output: Root cause identified

**Step 3: Reusability Search (automatic)**
- Search for similar fixes in codebase
- Find existing utilities that can be reused
- Identify patterns to follow
- Output: Reusability recommendations

**Step 4: Solution Generation (5-7 min)**
- Create minimal fix strategy
- List files to modify
- Identify related tests
- Output: fix-analysis.md

**Step 5: Validation (automatic)**
- Check constitution compliance
- Verify no breaking changes
- Ensure minimal scope
- Output: Validation report

### Token Optimization

**Smart-Cache System:**
- File caching: 75% hit rate
- Test caching: 80% hit rate
- Analysis caching: 70% hit rate
- Total savings: 75% on average

**Minimal Scope:**
- Focus on affected files only: -20,000 tokens
- Skip unnecessary documentation: -15,000 tokens
- Targeted testing: -10,000 tokens

## 실행 순서

### 단계별 흐름

```
1. /minor 실행
   ↓
2. 이슈 설명 입력
   ├─ 문제 설명
   ├─ 증상/에러 메시지
   └─ 영향 받는 부분
   ↓
3. 근본 원인 분석 (자동)
   ├─ 코드 분석
   ├─ 파일/라인 식별
   └─ 변경 범위 결정
   ↓
4. 재사용성 검색 (자동)
   ├─ 유사 수정 사례 검색
   ├─ 재사용 가능 유틸리티 발견
   └─ 권장 패턴 제시
   ↓
5. 솔루션 생성
   ├─ fix-analysis.md 생성
   ├─ 수정 파일 목록
   ├─ 관련 테스트 식별
   └─ 검증 단계 정의
   ↓
6. 검증
   ├─ Constitution 준수 확인
   ├─ Breaking changes 체크
   └─ 최소 범위 확인
   ↓
7. 완료
   └─ 문서 위치 안내
   └─ 구현 가이드 제공
```

## 생성되는 문서

### fix-analysis.md

**생성 위치**: `.specify/fixes/<NNN-issue-name>/fix-analysis.md`

**번호 체계**: 순차 번호 (001, 002, 003, ...) 자동 부여

**포함 내용:**
- Issue: 문제 요약, 심각도, 복잡도, 예상 시간
- Root Cause: 원인 분석, 파일/라인 식별
- Solution: 권장 접근법, 재사용 컴포넌트
- **Tasks**: 체크박스로 수행 항목 추적 (진행도 관리)
- Files to Change: 수정할 파일 목록
- Related Tests: 관련 테스트, 추가할 테스트
- Verification Steps: 검증 단계
- Consistency Check: 일관성 확인
- Quality Metrics: 품질 메트릭
- Constitution Compliance: 아키텍처 준수
- Recommendations: 추가 권장사항

**상세 템플릿**: [minor-document-templates.md](examples/minor-document-templates.md) 참고

## Quality Gates (workflow-gates.json 기준)

### Minor 워크플로우 게이트

**From workflow-gates.json:**
```json
{
  "minor": {
    "minTestCoverage": null,
    "requiresArchitectureReview": false,
    "requiresConstitutionCheck": true,
    "relatedTestsMustPass": true,
    "preventBreakingChanges": true,
    "reusabilityEnforcement": true
  }
}
```

**Major와의 차이:**
- ✗ 전체 테스트 커버리지 요구 없음 (관련 테스트만)
- ✗ 아키텍처 리뷰 불필요
- ✓ Constitution 준수 필수
- ✓ Breaking changes 금지
- ✓ 재사용성 강제

**적용 시점:**
1. **솔루션 생성** (Step 4):
   - Constitution check
   - Reusability 검색
   - Breaking changes 분석

2. **구현 후**:
   - 관련 테스트 실행
   - 수동 검증
   - 회귀 테스트 확인

## 예상 토큰 절감

### 최적화 효과

| 항목 | 기존 | 최적화 | 절감 |
|------|------|--------|------|
| 이슈 분석 | 20,000 | 5,000 | 75% |
| 재사용 검색 | 15,000 | 3,000 | 80% |
| 솔루션 생성 | 20,000 | 5,000 | 75% |
| 문서화 | 5,000 | 2,000 | 60% |
| **Total** | **60,000** | **15,000** | **75%** |

### 재사용성 효과

- 기존 솔루션 활용: -10,000 토큰
- 패턴 재사용: -8,000 토큰
- 유틸리티 재사용: -7,000 토큰
- **재사용 절감: -25,000 토큰**

## 통합 워크플로우

### 전체 흐름

```bash
# 1. 작업 분석
/triage "Fix login null pointer"
# → Minor 추천 (복잡도: 5/15)

# 2. Minor 실행
/minor
# → fix-analysis.md 생성

# 3. 문서 리뷰
cat .specify/fixes/042-login-null-pointer/fix-analysis.md

# 4. 구현
# ... 코드 수정 ...

# 5. 관련 테스트 실행
npm test LoginForm

# 6. 리뷰
/review --staged

# 7. 커밋
/commit

# 8. PR (선택)
/pr
```

### 다른 명령어와 연계

- **/triage** → /minor: 복잡도 분석 후 선택
- **/minor** → 구현 → /review: 수정 후 검증
- **/review** → /minor: 리팩토링 제안 구현
- **/minor** → /commit: 자동 커밋 메시지

## 모범 사례

### 1. 최소 범위 유지

**좋은 예:**
```
수정: src/features/auth/ui/LoginForm.tsx (1 파일)
이유: 널 체크 추가
```

**나쁜 예:**
```
수정: 5개 파일 (auth, profile, settings, ...)
이유: 전체 폼 검증 로직 리팩토링
→ /major 사용해야 함
```

### 2. 재사용 우선

fix-analysis.md의 재사용 권장사항 따르기:
- 기존 유틸리티 활용
- 패턴 일관성 유지
- 중복 코드 방지

### 3. 테스트 집중

관련 테스트만 작성/실행:
- 수정된 함수의 테스트
- 영향 받는 컴포넌트 테스트
- 회귀 테스트 (기존 기능)

### 4. Breaking Changes 금지

하위 호환성 유지:
- API 시그니처 변경 금지
- Public API 변경 금지
- 인터페이스 변경 금지

## 사용 예시

자세한 시나리오와 출력 예시는 별도 문서 참고:
- **사용 예시**: [minor-examples.md](examples/minor-examples.md)
- **문서 템플릿**: [minor-document-templates.md](examples/minor-document-templates.md)
- **문제 해결**: [minor-troubleshooting.md](examples/minor-troubleshooting.md)

## 빠른 참조

### 자주 사용하는 명령어

```bash
# 기본 실행
/minor

# 복잡도 먼저 확인
/triage "버그 설명"

# 문서 확인
cat .specify/fixes/<NNN-issue-name>/fix-analysis.md

# 관련 테스트 실행
npm test <ComponentName>
```

### 생성되는 파일

- ✅ fix-analysis.md (`.specify/fixes/<NNN-issue-name>/`)

### 일반적인 에러 해결

**"Scope too large"**
```bash
/major  # Major 워크플로우 사용
```

**"Breaking changes detected"**
```
하위 호환성 유지 또는 /major 사용
```

**"Reusability check failed"**
```
fix-analysis.md의 재사용 권장사항 확인
```

**"Related tests not found"**
```
테스트 추가 또는 /micro 사용
```

---

**Version**: 3.3.1
**Last Updated**: 2025-11-18
**See Also**: [major.md](major.md), [micro.md](micro.md), [epic.md](epic.md)
