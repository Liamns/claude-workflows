# 🚀 Major - 통합 워크플로우 v3.0

## Overview

신규 기능 구현을 위한 완전한 워크플로우로, 60% 토큰 절감과 함께 품질을 보장합니다.

## Output Language

**IMPORTANT**: 사용자나 동료가 확인하는 모든 계획 문서와 출력은 반드시 **한글로 작성**해야 합니다.

**한글 작성 대상:**
- spec.md - 요구사항 명세서 전체
- plan.md - 구현 계획 전체 (재사용성 분석 포함)
- tasks.md - 작업 목록 전체
- research.md - 연구 결과 전체
- data-model.md - 데이터 모델 설명
- 진행 상황 메시지
- 에러 메시지 및 경고

**영어 유지:**
- 코드, 변수명, 함수명, 파일 경로
- 기술 스택 이름 (React, TypeScript 등)
- 명령어

**예시 문서 구조:**
```markdown
# Spec: 사용자 인증 시스템

## Metadata
- Feature ID: AUTH-001
- Complexity: 12/15 (Major)
- Estimated: 3-5일
- Created: 2025-11-18

## Overview
JWT 기반 사용자 인증 시스템 구현. 로그인, 회원가입, 비밀번호 재설정 기능 포함.

## User Scenarios
### [US1] 이메일로 로그인
**Actor**: 등록된 사용자
...
```

**핵심 기능:**
1. **요구사항 수집**: 대화형 Q&A로 상세 명세 작성
2. **재사용성 분석**: 기존 패턴 자동 검색 및 재사용 권장
3. **아키텍처 설계**: 기술 설계 및 구현 계획 생성
4. **작업 분해**: 실행 가능한 테스트 가능한 작업 목록 생성
5. **품질 검증**: workflow-gates.json 기반 자동 품질 게이트 적용

**최적화:**
- 60% 토큰 절감 (smart-cache 시스템)
- 재사용성 강제 (reusability-enforcer)
- 아키텍처 준수 검증
- 80%+ 테스트 커버리지 요구

## Usage

```bash
/major
```

대화형으로 다음을 진행합니다:
- 요구사항 수집
- Feature 디렉토리 및 브랜치 생성
- **병합 대상 브랜치 선택** (main, develop 등)
- 재사용 가능 컴포넌트 검색
- spec.md, plan.md, tasks.md, research.md 생성
- Constitution 규칙 검증

### Branch Strategy

- **Branch Creation**: 자동 생성
- **Branch Name**: `NNN-feature-name` (예: `010-auth-system`)
- **Merge Target**: 실행 시 물어봄 (main, develop 등)

### Prerequisites

- Git 저장소 초기화
- 아키텍처 설정 완료 (`/start`)
- Constitution 파일: `.specify/memory/constitution.md`
- Quality gates: `.claude/workflow-gates.json`

## 생성되는 문서

Major 워크플로우가 생성하는 디렉토리 및 파일 구조:

### 디렉토리 구조

```
.specify/features/010-auth-system/
├── spec.md          # 요구사항 명세서
├── plan.md          # 구현 계획 (재사용성 분석 포함)
├── tasks.md         # 작업 목록 (체크박스로 진행도 추적)
├── research.md      # 연구 결과
└── data-model.md    # 데이터 모델 (필요시)
```

**Major 워크플로우가 생성:**
1. Feature 디렉토리 ID 결정 (`.specify/features/` 내 다음 번호)
2. `.specify/features/NNN-feature-name/` 디렉토리 생성
3. `NNN-feature-name` 브랜치 생성 및 체크아웃
4. 디렉토리 내에 계획 문서 생성

### 각 파일의 역할

**spec.md** - 요구사항 명세서
- Metadata: 작업 ID, 날짜, 복잡도
- User Scenarios: 사용자 시나리오
- Functional Requirements: 기능 요구사항
- Key Entities: 핵심 엔티티
- Success Criteria: 성공 기준

**plan.md** - 구현 계획
- Reusability Analysis: 재사용 가능 컴포넌트 분석
- Constitution Check: 아키텍처 규칙 확인
- Source Code Structure: 소스 코드 구조
- Implementation Phases: 구현 단계

**tasks.md** - 작업 목록
- Phase별 작업 분류
- User Story별 그룹화
- Verification Steps: 검증 단계
- Dependencies: 작업 간 의존성

**research.md** - 연구 결과
- 기술 조사 내용
- 라이브러리 비교
- 성능 벤치마크

**data-model.md** - 데이터 모델 (필요시)
- Entity 정의
- 관계도 (ERD)
- 스키마 설계

**상세 템플릿**: [major-document-templates.md](examples/major-document-templates.md) 참고

## Epic과의 관계

### 단독 실행 (Major)

일반적인 기능 개발:

```
.specify/features/010-auth-system/
├── spec.md
├── plan.md
├── tasks.md
├── research.md
└── data-model.md

Branch: 010-auth-system
```

### Epic 내부 Feature

Epic의 일부로 실행되는 경우:

```
.specify/epics/009-ecommerce-platform/
├── epic.md          # Epic 정의
├── progress.md      # 진행 상황
├── roadmap.md       # 로드맵
└── features/
    ├── 001-auth-system/
    │   ├── spec.md
    │   ├── plan.md
    │   └── tasks.md
    └── 002-payment-integration/
        ├── spec.md
        ├── plan.md
        └── tasks.md

Branch: 009-ecommerce-platform (모든 Feature가 이 브랜치에서 작업)
```

**차이점**:
- Epic: 복잡도 10+ 작업을 여러 Feature로 분해
- Major: 단일 Feature 구현 (Epic의 Feature로도 사용 가능)
- Epic 브랜치 내에서 모든 Feature 작업 수행

## Implementation

### 아키텍처

6개 통합 에이전트 오케스트레이션:
- **architect-unified**: 요구사항 수집, 아키텍처 설계
- **reusability-enforcer**: 기존 패턴 검색 (자동 실행)
- **implementer-unified**: 계획 및 작업 생성
- **reviewer-unified**: Constitution 검증
- **smart-cache**: 토큰 최적화 (70% 캐시 히트율)
- **documenter-unified**: 문서 생성

### 의존성

**필수:**
- 통합 에이전트 전체 (architect, reusability-enforcer, implementer, reviewer, documenter)
- Constitution: `.specify/memory/constitution.md`
- Quality gates: `.claude/workflow-gates.json`
- Architecture config: `.specify/config/architecture.json`

**선택:**
- Git 저장소 (커밋 추적)
- Notion MCP (변경 로그 연동)

### 워크플로우 단계

**Step 1: 디렉토리 및 브랜치 생성** (1-2분)
- 사용자로부터 기능 설명 입력
- 요약하여 디렉토리명 생성 (예: 010-auth-system)
- `.specify/features/NNN-feature-name/` 디렉토리 생성
- `NNN-feature-name` 브랜치 생성 및 체크아웃
- 병합 대상 브랜치 선택 (main, develop 등)
- Output: Feature 디렉토리 및 브랜치 준비 완료

**Step 2: 요구사항 수집** (5-10분)
- 대화형 Q&A로 요구사항 수집
- 사용자 시나리오, 제약사항 입력
- Output: 초기 요구사항 초안

**Step 3: 재사용성 분석** (자동)
- reusability-enforcer가 코드베이스 검색
- 기존 패턴, 컴포넌트, 유틸리티 식별
- 재사용 기회 제안
- Output: plan.md에 재사용 권장사항 포함

**Step 4: 설계 & 계획** (10-15분)
- 기술 명세 생성 (spec.md)
- 구현 계획 작성 (plan.md)
- 품질 게이트 및 수용 기준 정의
- Constitution 검증
- Output: 완전한 설계 문서

**Step 5: 작업 분해** (5-10분)
- 구현을 User Story로 분해
- 순차적, 테스트 가능한 작업 생성
- 검증 단계 추가
- 재사용성 체크 포함
- Output: tasks.md

**Step 6: 검증** (자동)
- Constitution 준수 확인
- Quality gate 정의 검증
- 아키텍처 제약사항 확인
- 재사용성 강제 검토
- Output: 검증 리포트

### 토큰 최적화

**Smart-Cache 시스템:**
- 파일 캐싱: 70% 히트율
- 테스트 캐싱: 85% 히트율
- 분석 캐싱: 60% 히트율
- 총 절감: 평균 60%

**재사용성 효과:**
- 패턴 검색: -15,000 토큰
- 컴포넌트 재사용: -20,000 토큰
- 아키텍처 검증: -10,000 토큰

## Quality Gates

### Major 워크플로우 게이트 (workflow-gates.json)

```json
{
  "major": {
    "minTestCoverage": 80,
    "requiresArchitectureReview": true,
    "requiresConstitutionCheck": true,
    "relatedTestsMustPass": true,
    "preventBreakingChanges": true,
    "reusabilityEnforcement": true
  }
}
```

**적용 시점:**

1. **설계 단계** (Step 4):
   - Constitution check 실행
   - Architecture compliance 검증
   - Reusability 강제

2. **구현 단계** (tasks.md 실행 중):
   - 테스트 커버리지 80% 이상
   - 관련 테스트 통과 확인
   - Breaking changes 방지

3. **완료 단계** (/commit 전):
   - 모든 quality gates 통과 확인
   - 문서 완성도 검증

## 예상 토큰 절감

| 항목 | 기존 | 최적화 | 절감 |
|------|------|--------|------|
| 요구사항 수집 | 50,000 | 20,000 | 60% |
| 재사용 분석 | 30,000 | 5,000 | 83% |
| 설계 문서 | 60,000 | 25,000 | 58% |
| 작업 목록 | 40,000 | 15,000 | 62% |
| 검증 | 20,000 | 15,000 | 25% |
| **Total** | **200,000** | **80,000** | **60%** |

**재사용성 추가 절감:**
- 기존 패턴 발견: -15,000 토큰
- 컴포넌트 재사용: -20,000 토큰
- 중복 제거: -10,000 토큰

## 통합 워크플로우

### 전체 개발 사이클

```bash
# 1. 아키텍처 설정 (최초 1회)
/start

# 2. 작업 복잡도 분석
/triage "사용자 인증 시스템 추가"
# → Major 추천 (복잡도: 12/15)

# 3. Major 실행
/major
# → Spec 디렉토리/브랜치 생성
# → 문서 생성 완료

# 4. 문서 리뷰
cat .specify/features/010-auth-system/spec.md
cat .specify/features/010-auth-system/tasks.md

# 5. 구현 (tasks.md 따라)
# ... 코딩 작업 ...

# 6. 리뷰
/review --staged

# 7. 커밋 & PR
/commit
/pr

# 8. 메트릭 확인
/dashboard
```

### 다른 워크플로우와 연계

- **/triage** → /major: 복잡도 분석 후 자동 선택
- **/major** → tasks.md: 계획 기반 구현
- **/review** → /major: 리뷰 결과 기반 리팩토링
- **/major** → /commit: 문서 기반 커밋 메시지

## 모범 사례

### 1. 재사용성 우선

reusability-enforcer가 제안하는 패턴 적극 활용:
- API 클라이언트 재사용
- 공통 컴포넌트 활용
- 유틸리티 함수 공유

### 2. Constitution 준수

아키텍처 규칙 엄격히 준수:
- Custom FSD: Domain-centric 구조, Widgets 제거
- Clean Architecture: 의존성 방향
- Hexagonal: Port/Adapter 패턴

### 3. 테스트 우선

tasks.md의 테스트 작업 먼저 완료:
- Unit tests: 80%+
- Integration tests: 주요 흐름
- E2E tests: 핵심 시나리오

### 4. 상세한 요구사항 제공

더 나은 문서 생성을 위해:
- 구체적인 사용자 시나리오
- 명확한 기술적 제약사항
- Edge cases 언급
- 성능 요구사항

## 사용 예시

자세한 시나리오와 출력 예시는 별도 문서 참고:
- **사용 예시**: [major-examples.md](examples/major-examples.md)
- **문서 템플릿**: [major-document-templates.md](examples/major-document-templates.md)
- **문제 해결**: [major-troubleshooting.md](examples/major-troubleshooting.md)

## 빠른 참조

### 자주 사용하는 명령어

```bash
# 기본 실행
/major

# 복잡도 먼저 확인
/triage "기능 설명"

# 문서 확인
cat .specify/features/NNN-feature-name/spec.md
cat .specify/features/NNN-feature-name/tasks.md

# Epic과 함께 사용
/epic "대규모 프로젝트"
# → Epic 생성 후 각 Feature를 /major로 구현
```

### 생성되는 파일 목록

- ✅ spec.md (필수)
- ✅ plan.md (필수, 재사용성 분석 포함)
- ✅ tasks.md (필수)
- ✅ research.md (선택)
- ✅ data-model.md (필요시)

---

**Version**: 3.3.1
**Last Updated**: 2025-11-18
**See Also**: [minor.md](minor.md), [micro.md](micro.md), [epic.md](epic.md)
