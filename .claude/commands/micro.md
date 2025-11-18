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

## 사용 예시

자세한 시나리오와 실전 예시는 별도 문서 참고:
- **사용 예시**: [micro-examples.md](examples/micro-examples.md)
- **문제 해결**: [micro-troubleshooting.md](examples/micro-troubleshooting.md)

## 빠른 참조

### 자주 사용하는 명령어

```bash
# 기본 실행
/micro

# 복잡도 먼저 확인
/triage "작업 설명"

# 연속 실행
/micro
/micro
/micro
/commit
```

### Micro 적합성 체크

```
□ 코스메틱 변경인가?
□ 1-3개 파일만?
□ 테스트 불필요?
□ 5분 이내 완료?
□ 되돌리기 쉬운가?

모두 ✓ → Micro 사용
하나라도 ✗ → Minor/Major
```

### 일반적인 에러 해결

**"Auto-upgrading to /minor"**
```bash
# 변경이 복잡함
/minor  # Minor 사용
```

**"Breaking change detected"**
```bash
# API/인터페이스 변경
/major  # Major 사용
```

---

**Version**: 3.3.1
**Last Updated**: 2025-11-18
**See Also**: [major.md](major.md), [minor.md](minor.md), [epic.md](epic.md)
