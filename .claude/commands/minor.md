# /minor - Minor 워크플로 (Incremental Updates)

## Overview

버그 수정, 리팩토링, 점진적 개선을 위한 간소화된 워크플로우(workflow)로, 집중된 분석과 최소한의 오버헤드를 통해 75%의 토큰 절감을 달성합니다.

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

이 커맨드는 다음을 수행합니다:
1. **이슈 분석**: 근본 원인과 영향받는 컴포넌트 식별
2. **재사용 가능 패턴 검색**: 유사한 수정사항과 기존 유틸리티 찾기
3. **솔루션 생성**: 최소한의 집중된 구현 계획 작성
4. **품질 검증**: 관련 테스트 통과 및 회귀 방지 확인
5. **일관성 유지**: 코딩 표준 및 아키텍처(architecture) 준수 검증

**주요 기능:**
- Smart-cache와 집중된 범위를 통한 75% 토큰 절감
- 자동 재사용성(reusability) 패턴 감지
- 최소한의 품질 게이트(quality gate) (관련 테스트만)
- 빠른 처리 시간 (< 1일 구현)
- Breaking change 금지
- Constitution 준수 검증

## Usage

```bash
/minor
```

이 커맨드는 다음을 수행합니다:
- 대화형으로 이슈 설명 수집
- **새 브랜치 생성 여부 물어봄** (선택)
- **병합 대상 브랜치 물어봄** (예: main, develop)
- 근본 원인 분석
- 재사용 가능한 솔루션 검색
- 구현 계획이 포함된 fix-analysis.md 생성
- 프로젝트 규칙에 대한 검증

### Branch Strategy

- **Branch Creation**: 실행 시 생성 여부 물어봄
- **Branch Name**: `NNN-issue-name` (예: `042-login-null-pointer`)
- **Merge Target**: 실행 시 물어봄 (main, develop 등)

### Prerequisites

- Git 저장소 초기화
- 아키텍처(architecture) 설정 완료 (먼저 `/start` 실행)
- Constitution 파일: `.specify/memory/constitution.md`
- 품질 게이트(quality gate): `.claude/workflow-gates.json`

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

Minor 워크플로우(workflow)는 4개의 통합 에이전트(agent)를 사용합니다:
- **architect-unified**: 근본 원인 분석
- **reusability-enforcer**: 패턴 감지 (자동 실행)
- **implementer-unified**: 솔루션 생성
- **reviewer-unified**: Constitution 검증

### Dependencies

**필수:**
- 통합 에이전트(unified agent) (architect, reusability-enforcer, implementer, reviewer)
- Constitution 파일: `.specify/memory/constitution.md`
- 품질 게이트(quality gate): `.claude/workflow-gates.json`

**선택:**
- Diff 분석을 위한 Git 저장소
- 검증을 위한 테스트 스위트

### Workflow Steps

**단계 1: 이슈 수집 (2-3분)**
- 이슈 설명 수집
- 증상 및 에러 메시지 식별
- 영향받는 컴포넌트 확인
- 출력: 이슈 요약

**단계 2: 근본 원인 분석 (3-5분)**
- 코드 분석하여 이슈 원인 찾기
- 영향받는 파일 및 라인 식별
- 변경 범위 결정
- 출력: 근본 원인 식별됨

**단계 3: 재사용성(Reusability) 검색 (자동)**
- 코드베이스에서 유사한 수정사항 검색
- 재사용 가능한 기존 유틸리티 찾기
- 따를 패턴 식별
- 출력: 재사용성(reusability) 권장사항

**단계 4: 솔루션 생성 (5-7분)**
- 최소한의 수정 전략 작성
- 수정할 파일 목록 작성
- 관련 테스트 식별
- 출력: fix-analysis.md

**단계 5: 검증 (자동)**
- Constitution 준수 확인
- Breaking change 없음 검증
- 최소 범위 보장
- 출력: 검증 보고서

### Token Optimization

**Smart-Cache 시스템:**
- 파일 캐싱: 75% 적중률
- 테스트 캐싱: 80% 적중률
- 분석 캐싱: 70% 적중률
- 총 절감: 평균 75%

**최소 범위:**
- 영향받는 파일만 집중: -20,000 토큰
- 불필요한 문서화 생략: -15,000 토큰
- 타겟 테스팅: -10,000 토큰

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
