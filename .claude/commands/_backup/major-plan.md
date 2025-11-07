---
name: major-plan
model: sonnet
model_upgrade_conditions:
  - complexity_score: ">12"
  - architecture_change: true
  - breaking_changes: true
upgrade_model: opus
context7_enabled: conditional
context7_conditions:
  - complexity_score: ">10"
  - feature_type: "cross_cutting"
  - architecture_modification: true
  - user_flag: "--use-context7"
context7_max_tokens: 3000
---

# /major-plan - Implementation Plan 생성 (Step 3/4)

spec.md를 기반으로 기술적 구현 계획을 수립합니다.

## 모델 및 Context7 선택

### 복잡도 평가
계획 수립 전 복잡도를 평가하여 최적 모델을 선택합니다:

```yaml
복잡도 계산:
  기능_범위:
    단일 모듈: +2점
    2-3 모듈: +4점
    4개 이상: +6점

  아키텍처_영향:
    기존 패턴 준수: +1점
    새 패턴 도입: +4점
    아키텍처 변경: +6점

  통합_복잡도:
    외부 API 없음: +0점
    1-2개 API: +2점
    3개 이상 API: +4점

모델 선택:
  0-11점: Sonnet (기본)
  12점 이상: Opus 업그레이드

Context7 활성화:
  10점 이상: 자동 활성화
  --use-context7: 수동 활성화
```

### Context7 로딩 전략
Context7이 활성화되면 선택적으로 컨텍스트를 로드합니다:

```yaml
🔍 Context7 활성화 (복잡도: 14점)
로딩 구성 (최대 3000 토큰):
  ├─ 프로젝트 구조 (500 토큰)
  ├─ 관련 컴포넌트 (1500 토큰)
  │  └─ features/*/api/*
  │  └─ shared/hooks/*
  ├─ 기존 패턴 (1500 토큰)
  │  └─ 유사 기능 구현
  └─ 아키텍처 규칙 (500 토큰)
```

## 사용법

```
/major-plan [feature-number]
```

예시:
```
/major-plan 001
```

## 실행 내용

`/major`의 5단계를 독립적으로 실행:
1. Phase 0: Research
   - 기존 솔루션 분석
   - 라이브러리 옵션 평가
   - 기술적 실현 가능성 검토
   - 리스크 및 완화 방안

2. Phase 1: Design Artifacts
   - data-model.md (Entity, State, API Types)
   - contracts/openapi.yaml (API 계약)
   - quickstart.md (설정 가이드)

3. plan.md
   - Technical Foundation
   - Constitution Check
   - Source Code Structure

## 생성 파일

```
.specify/specs/NNN-feature-name/
├── spec.md         (기존)
├── plan.md         ✅
├── research.md     ✅
├── data-model.md   ✅
├── quickstart.md   ✅
└── contracts/
    └── openapi.yaml ✅
```

## Constitution Check

Constitution 위반 여부를 자동 검증하고 위반 시 justification을 요구합니다.

## 다음 단계

```
/major-tasks      # 실행 가능한 Task 생성
```
