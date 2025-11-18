# /micro - Micro 워크플로 (Quick Fix)

## Overview

Ultra-fast workflow for trivial changes with 85% token savings through minimal overhead and direct execution.

This command:
1. **Identifies Change**: Quick analysis of trivial modification needed
2. **Validates Scope**: Ensures change is truly micro-level (< 30 min)
3. **Executes Directly**: Makes change without extensive planning
4. **Skips Tests**: No test requirements for cosmetic changes
5. **Quick Verification**: Manual verification only

**Key Features:**
- 85% token savings (minimal agent usage)
- No planning documents generated
- No test requirements
- Sub-30 minute execution
- Perfect for typos, logs, comments, config changes
- Auto-upgrades to /minor if scope too large

## Usage

```bash
/micro
```

The command will:
- Ask for brief description of change
- Validate it's micro-level scope
- Make the change directly
- Skip documentation and tests

### Prerequisites

- Git repository (recommended)
- Architecture configured (optional)
- No quality gates enforced

## Examples

### Example 1: Fix Typo

```bash
/micro
```

**Prompt:**
```
What trivial change are you making?
> Fix typo in README: "installtion" → "installation"
```

**Output:**
```
⚡ Micro Workflow - Quick Fix
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📝 Change Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Type: Documentation fix
Scope: Single file (README.md)
Complexity: 1/15 (Micro appropriate)
Estimated: < 5 minutes

✅ Micro Validation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Single file modification
✓ Cosmetic change only
✓ No code logic affected
✓ No tests needed

🔧 Executing Change
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

File: README.md
Change: "installtion" → "installation" (line 23)

✅ Complete!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Next steps:
1. Verify change looks correct
2. Run: /commit

Expected tokens: ~3,000 (vs 20,000 without Micro)
Token savings: 85%
Time saved: 10 minutes
```

### Example 2: Remove Console Logs

```bash
/micro
```

**Task:** "Remove console.log statements from production code"

**Output:**
```
⚡ Micro Workflow - Code Cleanup
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📝 Change Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Type: Debug code removal
Scope: 3 files
Complexity: 2/15 (Micro appropriate)
Estimated: 10-15 minutes

🔍 Found Console Logs
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

src/features/auth/ui/LoginForm.tsx (2 instances)
  - Line 42: console.log('User data:', user)
  - Line 87: console.log('Login success')

src/features/profile/ui/ProfilePage.tsx (1 instance)
  - Line 156: console.log('Profile loaded')

src/shared/lib/api/apiClient.ts (3 instances)
  - Line 23: console.log('Request:', config)
  - Line 45: console.log('Response:', data)
  - Line 67: console.error('API Error:', error)

🔧 Executing Removal
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Removed 6 console.log statements
✓ No logic changes
✓ Files remain valid

✅ Complete!

Next steps:
1. Quick smoke test
2. Run: /commit

Expected tokens: ~2,500
```

### Example 3: Update Config Value

```bash
/micro
```

**Task:** "Change API timeout from 5000ms to 10000ms"

**Output:**
```
⚡ Micro Workflow - Configuration Update
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📝 Change Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Type: Configuration change
Scope: 1 file (config.ts)
Complexity: 1/15 (Micro appropriate)
Estimated: 2 minutes

🔧 Executing Change
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

File: src/config/api.ts
Line: 12
Change: timeout: 5000 → timeout: 10000

✅ Complete!

Verification:
- Test a slow API call to confirm timeout
- Monitor for timeout errors

Expected tokens: ~2,000
```

### Example 4: Auto-Upgrade to Minor

```bash
/micro
```

**Task:** "Fix login validation logic"

**Output:**
```
⚠️ Scope Too Large for Micro
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Analysis:
- Type: Logic change (not cosmetic)
- Scope: Multiple files
- Complexity: 6/15
- Tests required: Yes

Reason:
Validation logic changes affect behavior and require:
- Root cause analysis
- Test coverage
- Regression prevention

💡 Recommendation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Use /minor instead:
- Proper issue analysis
- Related tests validation
- Documentation

Auto-upgrading to /minor workflow...
```

## Implementation

### Architecture

The Micro workflow uses minimal agent involvement:
- **smart-cache**: File reading only (cached)
- **No planning agents**: Direct execution
- **No quality gates**: Trust developer judgment

### Dependencies

**Required:**
- Basic file system access
- Smart-cache (for file reading)

**Optional:**
- Git (for commit)
- None of the quality gates or validation agents

### Workflow Steps

**Step 1: Change Description (30 seconds)**
- Get brief description of change
- Identify affected file(s)
- Output: Change summary

**Step 2: Scope Validation (30 seconds)**
- Check complexity score (must be ≤ 3/15)
- Verify single/few files
- Ensure cosmetic or trivial change
- Output: Validation decision

**Step 3: Auto-Upgrade Check**
- If complexity > 3: Upgrade to /minor
- If tests needed: Upgrade to /minor
- If logic change: Upgrade to /minor
- Output: Workflow recommendation

**Step 4: Execution (1-5 min)**
- Read affected files
- Make changes directly
- No documentation generated
- Output: Modified files

**Step 5: Quick Verify**
- Manual verification only
- No automated tests
- No quality gates
- Output: Change summary

### Related Resources

- **Cache**: Smart-cache for file reading
- **No documents generated**
- **No quality gates**

### Token Optimization

**Extreme Minimalism:**
- No planning phase: -30,000 tokens
- No documentation: -10,000 tokens
- No test generation: -15,000 tokens
- Cached file reads: -5,000 tokens
- **Total savings: 85%**

## 실행 순서

### 단계별 흐름

```
1. /micro 실행
   ↓
2. 변경 설명 (1줄)
   ↓
3. 범위 검증
   ├─ Micro 적합 → 계속
   └─ 범위 초과 → /minor로 자동 전환
   ↓
4. 직접 실행
   ├─ 파일 읽기 (캐시됨)
   ├─ 변경 적용
   └─ 저장
   ↓
5. 수동 검증
   └─ 변경 사항 확인
   ↓
6. 완료
   └─ /commit 권장
```

## Quality Gates (workflow-gates.json 기준)

### Micro 워크플로우 게이트

**From workflow-gates.json:**
```json
{
  "micro": {
    "minTestCoverage": null,
    "requiresArchitectureReview": false,
    "requiresConstitutionCheck": false,
    "relatedTestsMustPass": false,
    "preventBreakingChanges": true,
    "reusabilityEnforcement": false
  }
}
```

**특징:**
- ✗ 테스트 커버리지 불필요
- ✗ 아키텍처 리뷰 불필요
- ✗ Constitution 체크 불필요
- ✗ 테스트 실행 불필요
- ✓ Breaking changes 금지 (유일한 제약)
- ✗ 재사용성 강제 안 함

**철학:**
- 개발자 판단 신뢰
- 빠른 실행 우선
- 최소한의 검증만

## 예상 토큰 절감

### 최적화 효과

| 항목 | 기존 | Micro | 절감 |
|------|------|-------|------|
| 계획 단계 | 30,000 | 0 | 100% |
| 분석 | 10,000 | 1,000 | 90% |
| 문서화 | 10,000 | 0 | 100% |
| 테스트 | 15,000 | 0 | 100% |
| 실행 | 5,000 | 2,000 | 60% |
| **Total** | **70,000** | **3,000** | **85%** |

### 시간 절감

- 기존 Minor: 2-4 시간
- Micro: 5-30 분
- **시간 절감: 80-90%**

## 작업 타입별 처리

### 1. 문서 수정

**적합:**
- 오타 수정
- 링크 업데이트
- 형식 정리
- 예제 코드 업데이트

**예시:**
```bash
/micro
> "Fix typo in API documentation"
> "Update broken link in README"
> "Fix markdown formatting"
```

### 2. 로그/주석 제거

**적합:**
- console.log 제거
- 디버깅 코드 제거
- TODO 주석 제거
- 사용하지 않는 주석 정리

**예시:**
```bash
/micro
> "Remove console.log from production code"
> "Remove commented-out code"
> "Clean up debug statements"
```

### 3. 설정 변경

**적합:**
- 타임아웃 값 조정
- 환경 변수 업데이트
- 포트 번호 변경
- 간단한 플래그 토글

**예시:**
```bash
/micro
> "Change API timeout to 10s"
> "Update port from 3000 to 8080"
> "Enable feature flag"
```

### 4. 스타일링 (코스메틱)

**적합:**
- CSS 색상 변경
- 간격/마진 조정
- 폰트 크기 변경
- 간단한 레이아웃 조정

**예시:**
```bash
/micro
> "Change button color to blue"
> "Increase padding by 4px"
> "Update font size to 16px"
```

### 5. Import 정리

**적합:**
- 사용하지 않는 import 제거
- Import 순서 정리
- Alias 업데이트

**예시:**
```bash
/micro
> "Remove unused imports"
> "Organize imports alphabetically"
```

## 자동 워크플로 전환

### Minor로 자동 전환 조건

**복잡도 > 3/15:**
```
⚠️ Complexity too high (5/15)
→ Auto-upgrading to /minor
```

**로직 변경:**
```
⚠️ Logic change detected
→ Requires testing
→ Auto-upgrading to /minor
```

**여러 파일 (5개+):**
```
⚠️ Multiple files affected (7 files)
→ Needs analysis
→ Auto-upgrading to /minor
```

**테스트 필요:**
```
⚠️ Tests required for this change
→ Auto-upgrading to /minor
```

### Major로 자동 전환 조건

**복잡도 > 7/15:**
```
⚠️ Complexity too high (9/15)
→ Requires planning
→ Auto-upgrading to /major
```

**새 기능:**
```
⚠️ New feature detected
→ Auto-upgrading to /major
```

## 에러 처리

### "Change requires tests"

**원인**: 로직 변경이 감지됨
**해결**:
```bash
# 자동으로 /minor로 전환됨
# 또는 수동으로:
/minor
```

### "Scope too large"

**원인**: 복잡도 4+ 또는 여러 파일
**해결**:
- 변경 범위 축소
- 또는 /minor 사용 (자동 전환됨)

### "Breaking change detected"

**원인**: API 변경 또는 인터페이스 수정
**해결**:
- 변경 취소
- /major 사용 (적절한 계획 필요)

## 사용 제한

### ✅ Micro 사용 가능

- 오타 수정
- 로그 제거
- 주석 정리
- 설정 값 변경 (단순)
- CSS/스타일 조정 (코스메틱)
- Import 정리
- 형식 정리

### ❌ Micro 사용 불가

- 로직 변경 → /minor
- 버그 수정 (테스트 필요) → /minor
- 리팩토링 → /minor
- 새 함수 추가 → /minor
- API 엔드포인트 변경 → /major
- 새 기능 → /major
- 아키텍처 변경 → /major

## 모범 사례

### 1. 정말 Trivial한 경우만

**좋은 예:**
```bash
/micro
> "Fix typo: teh → the"
```

**나쁜 예:**
```bash
/micro
> "Refactor authentication logic"
# → 이건 /minor 또는 /major!
```

### 2. 단일 관심사

**좋은 예:**
```bash
/micro
> "Remove console.log from LoginForm"
```

**나쁜 예:**
```bash
/micro
> "Remove logs, fix typos, update imports"
# → 여러 Micro로 나누거나 /minor 사용
```

### 3. 검증 가능

변경 후 쉽게 검증 가능한 것만:
- 육안으로 확인
- 간단한 수동 테스트
- 빌드 성공만 확인

### 4. 되돌리기 쉬움

잘못되었을 때 쉽게 되돌릴 수 있는 것만:
- git revert 한 번으로 복구
- 부작용 없음

## 통합 워크플로우

### Triage와 함께

```bash
# 1. 작업 분석
/triage "Fix typo in README"
# → Micro 추천 (복잡도: 1/15)

# 2. Micro 실행
/micro
> "Fix typo in README"

# 3. 커밋
/commit
```

### 빠른 수정 사이클

```bash
# 여러 Micro 작업 연속 실행
/micro
> "Remove console.log"

/micro
> "Fix typo in header"

/micro
> "Update timeout config"

# 일괄 커밋
/commit
```

### 리뷰 후 Micro

```bash
# 1. 리뷰 실행
/review --staged

# 2. 간단한 이슈 발견
# "Remove unused import on line 23"

# 3. 즉시 수정
/micro
> "Remove unused import"

# 4. 재검토 (선택)
/review --staged
```

## 성능 지표

### 평균 토큰 사용량

- **Typo 수정**: ~2,000 토큰
- **로그 제거**: ~2,500 토큰
- **설정 변경**: ~1,500 토큰
- **Import 정리**: ~3,000 토큰

### 평균 실행 시간

- **준비**: 30초 (설명 입력)
- **검증**: 30초 (자동)
- **실행**: 1-5분
- **총 시간**: < 10분

### 자동 전환 비율

- **Minor로 전환**: 15% (복잡도 과소평가)
- **그대로 진행**: 85%

## 문제 해결

### "자꾸 /minor로 전환돼요"

**원인**: 변경이 생각보다 복잡함
**해결**:
- 실제로 /minor가 적합한 경우일 수 있음
- 변경 범위 다시 확인
- 정말 trivial한지 재평가

### "문서가 생성 안 돼요"

**원인**: Micro는 문서 생성 안 함 (의도된 동작)
**해결**:
- 문서 필요하면 /minor 사용
- Micro는 즉시 실행만

### "테스트 실행이 안 돼요"

**원인**: Micro는 테스트 안 함 (의도된 동작)
**해결**:
- 테스트 필요하면 /minor 사용
- 수동으로 npm test 실행 가능

## 주의사항

### Breaking Changes

Micro에서도 breaking changes는 금지:
- Public API 변경 금지
- 인터페이스 수정 금지
- 의존성 변경 금지

### Production Safety

프로덕션 영향도 고려:
- 설정 값 변경 시 영향 범위 확인
- 로그 제거 시 디버깅 필요성 고려
- 스타일 변경 시 접근성 확인

### Git 관리

- 각 Micro 작업은 별도 커밋 권장
- 관련 있는 여러 Micro는 하나의 커밋 가능
- 커밋 메시지 명확히 작성

## 실전 예시

### 시나리오 1: 긴급 프로덕션 수정

```bash
# 프로덕션에서 오타 발견
/micro
> "Fix typo in error message: 'occured' → 'occurred'"

# 즉시 커밋 & 배포
/commit
git push origin main
```

### 시나리오 2: 코드 클린업

```bash
# PR 전 마지막 정리
/micro
> "Remove console.log statements"

/micro
> "Remove unused imports"

/commit
/pr
```

### 시나리오 3: 설정 조정

```bash
# 타임아웃 증가 필요
/micro
> "Increase API timeout to 30 seconds"

# 테스트
npm run dev

# 확인 후 커밋
/commit
```

---

**Version**: 3.3.1
**Last Updated**: 2025-11-18
