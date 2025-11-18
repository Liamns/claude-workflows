# /minor - Minor 워크플로 (Incremental Updates)

## Overview

Streamlined workflow for bug fixes, refactoring, and incremental improvements with 75% token savings through focused analysis and minimal overhead.

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
- Analyze root cause
- Search for reusable solutions
- Generate fix-analysis.md with implementation plan
- Validate against project rules

### Prerequisites

- Git repository initialized
- Architecture configured (run `/start` first)
- Constitution file: `.specify/memory/constitution.md`
- Quality gates: `.claude/workflow-gates.json`

## Examples

### Example 1: Bug Fix (Null Pointer)

```bash
/minor
```

**Prompt:**
```
What issue are you fixing?
> Null pointer error in user login when email is empty

Describe the symptoms/error:
> Users get "Cannot read property 'toLowerCase' of null" error
> Happens when submitting login form with empty email field
```

**Output:**
```
🔧 Minor Workflow - Bug Fix
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Issue Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Issue: Null pointer in login email validation
Severity: Medium (affects user experience)
Complexity: 5/15 (Minor workflow appropriate)

🔍 Root Cause Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

File: src/features/auth/ui/LoginForm.tsx
Line: 42
Problem: Email validation calls .toLowerCase() without null check

Root Cause:
- Missing input validation
- No guard clause for empty/null values
- Email validation assumes string input

📦 Reusability Search
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Found existing solutions:
✓ src/shared/lib/validation/emailValidator.ts
  → Already has null-safe email validation
  → Reuse this instead of inline validation

✓ src/features/register/ui/RegisterForm.tsx
  → Similar pattern with proper guard clause
  → Follow this validation approach

💡 Solution
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Recommended approach:
1. Import emailValidator from shared/lib
2. Replace inline validation with reusable function
3. Add early return for null/empty values

Files to modify:
- src/features/auth/ui/LoginForm.tsx (fix)
- src/features/auth/ui/LoginForm.test.tsx (update tests)

Related tests:
✓ LoginForm.test.tsx (2 existing tests)
  → Add test case for empty email
  → Verify error message display

🎯 Quality Gates
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

From workflow-gates.json:
✓ Related tests must pass
✓ No breaking changes
✓ Constitution compliance
✗ Full test coverage NOT required (Minor only)

📝 Next Steps
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Document created: .claude/docs/fixes/login-null-pointer/
1. Review fix-analysis.md
2. Implement solution (2-3 files)
3. Run related tests
4. Commit with /commit

Expected tokens: ~15,000 (vs 60,000 without optimization)
Token savings: 75%
```

### Example 2: Refactoring (Extract Utility)

```bash
/minor
```

**Task:** "Extract duplicate date formatting logic to shared utility"

**Output:**
```
🔧 Minor Workflow - Refactoring
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Found duplicate code:
- src/features/posts/ui/PostCard.tsx (3 instances)
- src/features/comments/ui/Comment.tsx (2 instances)
- src/features/notifications/ui/NotificationItem.tsx (1 instance)

Pattern detected:
new Date(timestamp).toLocaleDateString('en-US', options)

📦 Reusability Check
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Existing utilities:
✓ src/shared/lib/date/formatDate.ts (already exists!)
  → Use this instead of creating new utility
  → Update to include relative time format

💡 Solution
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Extend shared/lib/date/formatDate.ts
   - Add formatRelativeDate function
   - Maintain existing API (no breaking changes)

2. Replace duplicates (6 locations)
   - Import formatDate from shared/lib
   - Replace inline formatting

3. Update tests
   - Add tests for new formatRelativeDate
   - Update component tests to use utility

Files to modify:
- src/shared/lib/date/formatDate.ts (extend)
- src/shared/lib/date/formatDate.test.ts (add tests)
- 6 component files (replace duplicates)

Verification:
- All tests pass
- No visual changes
- Consistent date formatting across app

Expected tokens: ~12,000
Time estimate: 2-3 hours
```

### Example 3: Small Feature Addition

```bash
/minor
```

**Task:** "Add 'Remember Me' checkbox to login form"

**Output:**
```
🔧 Minor Workflow - Feature Addition
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Scope Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: Remember Me checkbox
Complexity: 4/15 (Minor appropriate)
Impact: Low (UI + storage only)

📦 Reusability
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Found reusable components:
✓ src/shared/ui/Checkbox.tsx
  → Use this for consistent styling

✓ src/shared/lib/storage/localStorage.ts
  → Use for storing preference

✓ src/features/auth/model/useAuth.ts
  → Extend this hook for remember me logic

💡 Implementation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Phase 1: UI Component
- Add Checkbox from shared/ui
- Connect to form state
- Add label and styling

Phase 2: Logic
- Extend useAuth hook
- Store preference in localStorage
- Adjust token expiration (7 days vs 24h)

Phase 3: Tests
- Test checkbox interaction
- Test preference persistence
- Test token expiration logic

Files to modify:
- src/features/auth/ui/LoginForm.tsx
- src/features/auth/model/useAuth.ts
- src/features/auth/ui/LoginForm.test.tsx
- src/features/auth/model/useAuth.test.ts

Quality gates:
✓ Related tests pass
✓ No breaking changes to existing auth
✓ FSD layer separation maintained

Expected tokens: ~18,000
Time estimate: 3-4 hours
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

### Related Resources

- **Document**: `.claude/docs/fixes/<issue-name>/fix-analysis.md`
- **Configuration**: `workflow-gates.json` (minor section)
- **Constitution**: `.specify/memory/constitution.md`
- **Agents**: 4 unified agents

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

**포함 내용:**
```markdown
# Fix Analysis: Login Null Pointer

## Issue
Null pointer error when submitting login with empty email

**Severity**: Medium
**Complexity**: 5/15
**Estimated**: 2-3 hours

## Root Cause
File: src/features/auth/ui/LoginForm.tsx
Line: 42

Problem:
- Email validation calls .toLowerCase() without null check
- Missing input validation guard clause
- Assumes string input always provided

## Solution
Recommended approach:
1. Import emailValidator from shared/lib/validation
2. Replace inline validation (line 42-45)
3. Add early return for null/empty values

**Reusable Components:**
- shared/lib/validation/emailValidator.ts ✓
- Pattern from features/register/ui/RegisterForm.tsx

## Files to Change
1. src/features/auth/ui/LoginForm.tsx
   - Import emailValidator
   - Replace inline validation
   - Add null check

2. src/features/auth/ui/LoginForm.test.tsx
   - Add test for empty email
   - Add test for null email
   - Verify error message

## Related Tests
- LoginForm.test.tsx (2 existing)
- emailValidator.test.tsx (reused utility)

Tests to add:
- [ ] Test empty email submission
- [ ] Test null email handling
- [ ] Test error message display

## Verification Steps
1. Run tests: npm test LoginForm
2. Manual test: Submit form with empty email
3. Verify error message: "Email is required"
4. No console errors
5. No regressions in existing flows

## Consistency Check
✓ Uses existing emailValidator
✓ Follows RegisterForm pattern
✓ Maintains FSD layer structure
✓ No breaking changes
✓ Error messages consistent

## Quality Metrics
- Files changed: 2
- Lines changed: ~10
- Tests added: 3
- Reusability: High (uses shared validator)

## Constitution Compliance
✓ FSD: Features layer only (no cross-feature imports)
✓ Public API: Uses shared/lib via index.ts
✓ No architecture violations detected

## Recommendations
- Consider adding client-side validation library (e.g., Zod)
- Add form-level validation for all required fields
- Document validation patterns in constitution
```

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

## 에러 처리

### "Scope too large for Minor"

**원인**: 복잡도 8+ (Major 수준)
**해결**:
```bash
/major  # Major 워크플로우 사용
```

### "Breaking changes detected"

**원인**: API 또는 인터페이스 변경
**해결**:
- 변경 최소화
- 하위 호환성 유지
- 또는 /major 사용

### "Reusability check failed"

**원인**: 기존 유틸리티 무시
**해결**:
- fix-analysis.md의 재사용 권장사항 확인
- 기존 패턴 활용
- 정당한 이유가 있다면 문서화

### "Related tests not found"

**원인**: 테스트 누락
**해결**:
- fix-analysis.md에 테스트 추가 계획
- 최소한의 테스트 작성
- 또는 /micro 사용 (테스트 불필요한 경우)

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
cat .claude/docs/fixes/login-null-pointer/fix-analysis.md

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

## 문제 해결

### "fix-analysis가 너무 간단해요"

**원인**: 이슈 설명 부족
**해결**:
- 더 상세한 증상 설명
- 에러 메시지 전체 제공
- 재현 단계 포함

### "재사용 제안이 없어요"

**원인**: 신규 패턴이거나 첫 사례
**해결**:
- 새 유틸리티 생성 고려
- 차후 재사용을 위한 설계
- shared/lib에 패턴 추가

### "관련 테스트가 너무 많아요"

**원인**: 변경 범위가 넓음
**해결**:
- 범위 축소
- 또는 /major 사용
- 핵심 테스트만 실행

### "Constitution 위반이 감지됐어요"

**원인**: 아키텍처 규칙 위반
**해결**:
- Layer 분리 확인
- Import 규칙 준수
- Public API 사용

---

**Version**: 3.3.1
**Last Updated**: 2025-11-18
