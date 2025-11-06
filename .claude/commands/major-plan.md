# /major-plan - Implementation Plan 생성 (Step 3/4)

spec.md를 기반으로 기술적 구현 계획을 수립합니다.

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
