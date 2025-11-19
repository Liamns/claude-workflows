# /micro - Micro 워크플로 (Quick Fix)

**Claude를 위한 필수 지시사항:**

이 명령어가 실행될 때 반드시 다음 단계를 **순서대로** 따라야 합니다:

1. **변경사항이 정말 micro 수준인지 확인하세요**
2. 대화 맥락에서 간단한 수정 내용을 수집하세요
3. 범위 검증: 30분 이내 완료 가능한지 확인하세요
4. 범위가 크면 즉시 /minor 또는 /major 사용을 권장하세요
5. 확인 후 바로 변경을 수행하세요 (문서 생성 없음)

**절대로 범위 검증 단계를 건너뛰지 마세요.**

---

## Overview

최소한의 오버헤드와 직접 실행을 통해 85%의 토큰 절감을 달성하는 간단한 변경을 위한 초고속 워크플로우(workflow)입니다.

## Output Language

**IMPORTANT**: 사용자나 동료가 확인하는 모든 출력은 반드시 **한글로 작성**해야 합니다.

**한글 작성 대상:**
- 변경 사항 설명 및 요약
- 진행 상황 메시지
- 검증 결과
- 에러 메시지 및 경고

**영어 유지:**
- 코드, 변수명, 함수명, 파일 경로
- 명령어

**예시 출력:**
```
✅ 변경 완료

📝 수정 내용:
- README.md: 오타 수정 (teh → the)

🔍 검증:
- 파일 저장 완료
- 문법 오류 없음

다음 단계: /commit으로 커밋 생성
```

이 커맨드는 다음을 수행합니다:
1. **변경 식별**: 필요한 간단한 수정 사항의 빠른 분석
2. **범위 검증**: 변경이 실제로 마이크로 수준인지 확인 (< 30분)
3. **직접 실행**: 광범위한 계획 없이 변경 수행
4. **테스트 생략**: 코스메틱 변경의 경우 테스트 불필요
5. **빠른 검증**: 수동 검증만 수행

**주요 기능:**
- 85% 토큰 절감 (최소한의 에이전트 사용)
- 계획 문서 생성 안 함
- 테스트 요구사항 없음
- 30분 이내 실행
- 오타, 로그, 주석, 설정 변경에 완벽
- 범위가 너무 크면 자동으로 /minor로 전환

## Usage

```bash
/micro
```

이 커맨드는 다음을 수행합니다:
- 변경 사항에 대한 간단한 설명 요청
- 마이크로 수준 범위인지 검증
- 변경 사항을 직접 적용
- 문서화 및 테스트 생략

### Prerequisites

- Git 저장소 (권장)
- 아키텍처(architecture) 설정 (선택)
- 품질 게이트(quality gate) 적용 안 함

### 흐름 중단 시 대처

명령어 실행 중 수정이 필요한 경우:

1. **자유롭게 수정 요청**
   - "이 부분을 먼저 수정해줘"
   - "다시 설명해줄래?"
   - "파일 X를 수정하고 올게"

2. **수정 완료 후 복귀**
   - 수정 완료 후 "계속" 또는 "진행" 입력
   - 저장된 컨텍스트에서 자동으로 재개

3. **컨텍스트 복귀 옵션**
   - **계속하기**: 중단된 위치에서 재개
   - **새로 시작**: 기존 진행 상황 삭제하고 처음부터

**예시 시나리오:**
```
사용자: /micro "README 타이포 수정"
Claude: [변경 파일 확인 중...]

사용자: "잠깐, 다른 타이포도 있는지 확인할게"
Claude: [작업 컨텍스트 저장]

[사용자가 확인 완료]

사용자: "계속"
Claude: [확인부터 재개]
```

## Implementation

### Architecture

Micro 워크플로우(workflow)는 최소한의 에이전트(agent) 개입을 사용합니다:
- **smart-cache**: 파일 읽기만 (캐시됨)
- **계획 에이전트 없음**: 직접 실행
- **품질 게이트 없음**: 개발자 판단 신뢰

### Dependencies

**필수:**
- 기본 파일 시스템 접근
- Smart-cache (파일 읽기용)

**선택:**
- Git (커밋용)
- 품질 게이트(quality gate) 또는 검증 에이전트(agent) 불필요

### Workflow Steps

**단계 1: 변경 설명 (30초)**
- 변경에 대한 간단한 설명 받기
- 영향받는 파일 식별
- 출력: 변경 요약

**단계 2: 범위 검증 (30초)**
- 복잡도(complexity) 점수 확인 (≤ 3/15여야 함)
- 단일/소수 파일 확인
- 코스메틱 또는 간단한 변경 확인
- 출력: 검증 결정

**단계 3: 자동 업그레이드 확인**
- 복잡도 > 3인 경우: /minor로 업그레이드
- 테스트 필요한 경우: /minor로 업그레이드
- 로직 변경인 경우: /minor로 업그레이드
- 출력: 워크플로우(workflow) 권장사항

**단계 4: 실행 (1-5분)**
- 영향받는 파일 읽기
- 변경 사항 직접 적용
- 문서 생성 안 함
- 출력: 수정된 파일

**단계 5: 빠른 검증**
- 수동 검증만
- 자동화된 테스트 없음
- 품질 게이트(quality gate) 없음
- 출력: 변경 요약

### Token Optimization

**극도의 최소화:**
- 계획 단계 없음: -30,000 토큰
- 문서화 없음: -10,000 토큰
- 테스트 생성 없음: -15,000 토큰
- 캐시된 파일 읽기: -5,000 토큰
- **총 절감: 85%**

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
- **사용 예시**: [micro-examples.md](../docs/command-examples/micro-examples.md)
- **문제 해결**: [micro-troubleshooting.md](../docs/command-examples/micro-troubleshooting.md)

관련 문서:
- [major.md](major.md) - 복잡한 기능(feature) 개발
- [minor.md](minor.md) - 중간 규모 변경
- [epic.md](epic.md) - 대규모 프로젝트

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

**Version**: 3.3.2
**Last Updated**: 2025-11-18
**See Also**: [major.md](major.md), [minor.md](minor.md), [epic.md](epic.md)
