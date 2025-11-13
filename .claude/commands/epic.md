---
name: epic
description: 복잡도 10+ 대형 작업을 3-5개 Feature로 분해하여 체계적으로 관리합니다.
---

# 🏔️ Epic - 대형 작업 관리 워크플로우

복잡도 10점 이상의 대규모 작업을 3-5개의 Feature로 분해하여 단계적으로 구현합니다.
각 Feature는 독립적인 Major 워크플로우로 진행되며, 전체 진행 상황은 자동으로 추적됩니다.

## 사용법

```bash
/epic "Epic 설명"

# 예시
/epic "사용자 인증 시스템 구축"
/epic "결제 플랫폼 통합"
```

## Epic vs Major 차이점

| 구분 | Major | Epic |
|------|-------|------|
| 복잡도 | 5-9점 | 10+ 점 |
| 소요 시간 | 2-5일 | 2-3주 |
| 분해 | 없음 (단일 Feature) | 3-5개 Feature로 분해 |
| 진행 추적 | tasks.md | progress.md + roadmap.md |
| 구조 | spec/ 하나 | spec/epic/ + features/ |

## 실행 순서

### Step 0: 사전 조건 확인

1. `.specify/` 디렉토리 존재 확인
   - 없으면 → `/start` 실행 안내
2. Constitution.md 존재 확인
   - 없으면 → `/start` 실행 안내
3. Git 저장소 확인
   - 없으면 → `git init` 실행 안내

**Bash 도구로 디렉토리 확인**:
```
Bash:
- command: "test -d .specify && echo 'EXISTS' || echo 'MISSING'"
- description: "Check .specify directory"
```

**MISSING인 경우**:
```markdown
⚠️ .specify 디렉토리가 없습니다.

먼저 프로젝트를 초기화하세요:
/start
```

워크플로우를 중단하고 사용자에게 /start 실행을 요청하세요.

**EXISTS인 경우**: 다음 단계 계속 진행

✅ **Step 0 완료** - 사전 조건 확인 완료

### Step 1: Epic 번호 및 이름 준비

사용자가 제공한 Epic name을 `{epicName}` 변수에 저장하세요.

**Bash 도구로 다음 번호 찾기**:
```
Bash:
- command: "ls -d .specify/specs/*/ 2>/dev/null | sed 's/.*\\/\\([0-9]\\{3\\}\\)-.*/\\1/' | sort -n | tail -1"
- description: "Get latest Epic/Feature number"
```

결과를 기반으로 다음 번호 계산: `{nextNumber} = result + 1` (또는 001 if empty)

Epic 디렉토리 경로를 `{epicDir}` 변수에 저장: `.specify/specs/{nextNumber}-epic-{epicName}`

✅ **Step 1 완료** - Epic 번호 및 경로 준비 완료

### Step 2: Epic 핵심 질문

**🔴 필수**: 이 단계에서는 **반드시 AskUserQuestion 도구를 사용**해야 합니다.

**AskUserQuestion 도구 사용 - Block 1**:
```
질문 1: "이 Epic의 핵심 목표는 무엇인가요?"
헤더: "Epic 목표"
multiSelect: false
옵션:
  1. label: "새로운 시스템 구축"
     description: "완전히 새로운 기능 시스템을 처음부터 구축합니다"
  2. label: "기존 시스템 확장"
     description: "기존 기능에 대규모 확장을 추가합니다"
  3. label: "시스템 통합"
     description: "여러 시스템 또는 서비스를 통합합니다"
  4. label: "아키텍처 리팩토링"
     description: "대규모 코드 구조 개선 또는 재설계"

질문 2: "Epic을 어떻게 분해하시겠습니까?"
헤더: "분해 방식"
multiSelect: false
옵션:
  1. label: "기능 단위로 분해"
     description: "각 기능을 독립적인 Feature로 (예: OAuth, JWT, 권한)"
  2. label: "레이어 단위로 분해"
     description: "아키텍처 레이어별로 (예: Backend, Frontend, Integration)"
  3. label: "우선순위 단위로 분해"
     description: "출시 단계별로 (예: MVP, V1, V2)"
  4. label: "AI에게 자동 분해 제안 받기"
     description: "AI가 Epic을 분석하여 최적의 Feature 분해안을 제안합니다"

질문 3: "이 Epic의 우선순위는?"
헤더: "우선순위"
multiSelect: false
옵션:
  1. label: "P1 (긴급)"
     description: "높은 우선순위, 즉시 진행 필요"
  2. label: "P2 (일반)"
     description: "중간 우선순위, 계획대로 진행"
  3. label: "P3+ (낮음)"
     description: "낮은 우선순위, 여유 있을 때 진행"
```

답변을 `{epicGoal}`, `{decompositionMethod}`, `{priority}` 변수에 저장하세요.

✅ **Step 2 완료** - Epic 핵심 질문 완료

### Step 3: AI Feature 분해 (조건부)

**조건**: `{decompositionMethod}` = "AI에게 자동 분해 제안 받기"인 경우에만 실행

Epic 설명과 목표를 분석하여 3-5개의 Feature로 자동 분해합니다.

**AI Feature 분해 프롬프트 엔지니어링**:
```markdown
📦 AI Feature 분해 분석

Epic: {epicName}
목표: {epicGoal}

다음 기준으로 3-5개 Feature로 분해하세요:

**분해 기준**:
1. 각 Feature는 독립적으로 완료/테스트 가능해야 함
2. Feature 복잡도는 5-9점 (Major 수준) 유지
3. 의존성은 최소화 (병렬 실행 가능하도록)
4. Feature 간 순서는 의존성 순서대로
5. 각 Feature는 명확한 비즈니스 가치 제공

**출력 형식**:
Feature 1: {Feature 이름}
- 설명: {1-2 문장}
- 예상 소요 시간: {N}일
- 의존성: None
- 우선순위: P1

Feature 2: {Feature 이름}
- 설명: {1-2 문장}
- 예상 소요 시간: {N}일
- 의존성: None (또는 Feature 1)
- 우선순위: P1/P2

...
```

AI 분해 결과를 `{proposedFeatures}` 변수에 저장하세요.

**사용자에게 AI 제안 표시**:
```markdown
📦 AI가 제안하는 Feature 분해:

{proposedFeatures의 각 Feature를 포맷팅하여 표시}

1. **{Feature 1 이름}** ({예상 소요 시간})
   - {설명}
   - 의존성: {의존성}

2. **{Feature 2 이름}** ({예상 소요 시간})
   - {설명}
   - 의존성: {의존성}

...

이 분해안을 수락하시겠습니까?
```

**AskUserQuestion 도구 사용 - Block 2**:
```
질문: "AI 제안을 수락하시겠습니까?"
헤더: "Feature 검토"
multiSelect: false
옵션:
  1. label: "수락"
     description: "제안대로 Feature 생성"
  2. label: "수정 후 수락"
     description: "Feature 추가/제거/병합 후 진행"
  3. label: "거부 및 수동 입력"
     description: "AI 제안 없이 직접 Feature 정의"
```

**Option 2 선택 시**: 수정 지시 받기
"어떻게 수정하시겠습니까? (예: 'Feature 1과 2 병합', 'Feature 4 추가: Admin Panel')"

수정 사항을 `{proposedFeatures}`에 반영하세요.

**Option 3 선택 시**: 수동 입력 모드
"Feature 목록을 입력하세요 (한 줄에 하나씩, 형식: 001-feature-name: 설명)"

최종 Feature 목록을 `{finalFeatures}` 변수에 저장하세요.

✅ **Step 3 완료** - Feature 분해 완료 (3-5개)

### Step 4: Feature 개수 검증

`{finalFeatures}`의 개수를 확인:

**2개 이하인 경우**:
```markdown
⚠️ Feature 수가 2개 이하입니다.

Epic으로 분해하기엔 작은 작업일 수 있습니다.
Major 워크플로우를 사용하는 것을 고려하세요.

그래도 Epic으로 진행하시겠습니까? (y/n)
```

**6개 이상인 경우**:
```markdown
⚠️ Feature 수가 6개 이상입니다.

Epic이 너무 커서 관리가 어려울 수 있습니다.
Epic을 더 작은 단위로 나누는 것을 고려하세요.

그래도 Epic으로 진행하시겠습니까? (y/n)
```

사용자 응답에 따라 진행 또는 중단

✅ **Step 4 완료** - Feature 개수 검증 완료

### Step 5: Epic 구조 생성 (create-epic.sh 실행)

**Bash 도구로 create-epic.sh 실행**:
```
Bash:
- command: "bash .specify/scripts/bash/create-epic.sh '{epicName}' '{nextNumber}' '{finalFeatures}'"
- description: "Create Epic directory structure"
```

**create-epic.sh가 없는 경우**:
수동으로 디렉토리 구조 생성:

```
Bash:
- command: "mkdir -p {epicDir} && mkdir -p {epicDir}/features"
- description: "Create Epic directories"
```

각 Feature에 대해 디렉토리 생성:
```
Bash:
- command: "for i in {finalFeatures}; do mkdir -p {epicDir}/features/$i; done"
- description: "Create Feature directories"
```

✅ **Step 5 완료** - Epic 구조 생성 완료

### Step 6: epic.md 생성

**Read 템플릿**:
```
Read:
- file_path: ".specify/templates/epic-template.md"
```

템플릿을 기반으로 변수 치환:

**Write 도구로 epic.md 생성**:
```
Write:
- file_path: "{epicDir}/epic.md"
- content: """
# {epicName}

## Metadata
- Epic ID: {nextNumber}
- Created: {오늘 날짜 YYYY-MM-DD}
- Status: draft
- Priority: {priority}
- Estimated Duration: {자동 계산: Feature 소요 시간 합계}
- Completion Rate: 0%

## Overview

{epicGoal를 기반으로 Epic 비기술적 설명 작성}

**핵심 목표:**
- {epicGoal}

**배경:**
{decompositionMethod를 기반으로 배경 설명}

**기대 효과:**
{finalFeatures를 기반으로 기대 효과 나열}

## Features

{finalFeatures의 각 Feature에 대해:}
- [001-{feature-name}](./features/001-{feature-name}/spec.md) - {설명}
- [002-{feature-name}](./features/002-{feature-name}/spec.md) - {설명}
- [003-{feature-name}](./features/003-{feature-name}/spec.md) - {설명}

## Success Criteria

**기능적 기준:**
- [ ] 모든 Feature 완료 및 통합
- [ ] {Feature 1} 동작 확인
- [ ] {Feature 2} 동작 확인
- [ ] {Feature 3} 동작 확인

**품질 기준:**
- [ ] 모든 Feature의 테스트 통과
- [ ] 빌드 성공
- [ ] 코드 리뷰 완료

## Integration Plan

### Phase 1: Foundation
{의존성이 없는 Feature 나열}
- Feature {N} 완료 후 검증

### Phase 2: Integration
{의존성이 있는 Feature 나열}
- Feature {N}, {M} 완료 후 통합 테스트

### Phase 3: Validation
- 전체 시스템 통합 테스트
- 성능 테스트
- 사용자 수용 테스트

## Risks & Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Feature 간 통합 복잡도 | High | Medium | 명확한 인터페이스 정의, 통합 테스트 우선 |
| 예상 소요 시간 초과 | Medium | Medium | 주간 진행 상황 점검, 리스크 조기 식별 |

## Timeline

- **Started:** {오늘 날짜}
- **Estimated Completion:** {오늘 + 예상 소요 시간}
- **Actual Completion:** TBD

## Notes

{추가 메모}
"""
```

✅ **Step 6 완료** - epic.md 생성 완료

### Step 7: roadmap.md 생성

**Read 템플릿**:
```
Read:
- file_path: ".specify/templates/roadmap-template.md"
```

**Write 도구로 roadmap.md 생성**:
```
Write:
- file_path: "{epicDir}/roadmap.md"
- content: """
# Roadmap: {epicName}

## Feature Execution Order

{finalFeatures를 Phase별로 그룹핑}

### Phase 1: {Phase 이름}

- **[001-{feature-name}](./features/001-{feature-name}/spec.md)**
  - **Description:** {Feature 설명}
  - **Dependencies:** None
  - **Parallelizable:** {의존성 없으면 Yes, 있으면 No}
  - **Estimated:** {예상 소요 시간}
  - **Priority:** {priority}
  - **Status:** ⬜ Pending

...

## Dependency Graph

```mermaid
graph TD
    {finalFeatures의 의존성 관계를 Mermaid 형식으로 변환}
    A[001-{feature-1}] --> C[003-{feature-3}]
    B[002-{feature-2}] --> C
```

**Dependency 설명:**
- {의존성 관계 설명}

## Milestones

### M1: {Milestone 이름}
- **Features:** {첫 번째 Phase의 Feature 목록}
- **Target:** Week 2
- **Success Criteria:**
  - [ ] Feature {N} 완료 및 테스트 통과
  - [ ] 기본 통합 동작 확인
- **Status:** ⬜ Pending

### M2: Full Epic Completion
- **Features:** {모든 Feature}
- **Target:** Week 4
- **Success Criteria:**
  - [ ] 모든 Feature 완료
  - [ ] 전체 Epic 통합 테스트 통과
- **Status:** ⬜ Pending

## Execution Strategy

### 병렬 실행 가능 Features
{의존성 없는 Feature 목록}
- 병렬 실행 시 예상 소요 시간: {N}일 절감

### 순차 실행 필수 Features
{의존성 있는 Feature 목록}

### 리스크 관리
- **High Risk Features:** {복잡도가 높은 Feature}
  - 조기 착수 권장

## Notes

**의존성 변경 시:**
- roadmap.md 업데이트
- validate-epic.sh 실행하여 순환 의존성 체크
"""
```

✅ **Step 7 완료** - roadmap.md 생성 완료

### Step 8: progress.md 생성

**Read 템플릿**:
```
Read:
- file_path: ".specify/templates/progress-template.md"
```

**Write 도구로 progress.md 생성**:
```
Write:
- file_path: "{epicDir}/progress.md"
- content: """
# Progress: {epicName}

> Last Updated: {오늘 날짜 시간}

## Summary

- **Total Features:** {finalFeatures 개수}
- **Completed:** 0 ✅
- **In Progress:** 0 🔄
- **Pending:** {finalFeatures 개수} ⬜
- **Completion Rate:** 0%

## Progress Bar

```
[░░░░░░░░░░] 0%
```

## Feature Status

### ⬜ Pending

{finalFeatures의 각 Feature에 대해:}
- [ ] [001-{feature-name}](./features/001-{feature-name}/spec.md) - {Feature 이름}
  - **Estimated:** {예상 소요 시간}
  - **Dependencies:** {의존성}

## Timeline

- **Started:** {오늘 날짜}
- **Current Phase:** Phase 1 ({Phase 이름})
- **Estimated Completion:** {오늘 + 예상 소요 시간}
- **Actual Completion:** TBD

### Phase Progress

| Phase | Features | Status | Completion |
|-------|----------|--------|------------|
{각 Phase에 대해:}
| Phase 1: {Name} | {Feature 목록} | ⬜ Pending | 0% |

## Milestones

### M1: {Milestone 이름}
- **Target Date:** {목표 날짜}
- **Status:** ⬜ Pending
- **Features:** {Feature 목록}
- **Completion:** TBD

## Blockers

None

## Velocity

- **Average Days per Feature:** TBD
- **Estimated Remaining Time:** {총 예상 시간}
- **Projected Completion:** {오늘 + 예상 소요 시간}

## Notes

Epic이 시작되었습니다. 각 Feature를 `/major` 워크플로우로 구현하세요.

---

**자동 업데이트:**
이 파일은 Feature 완료 시 `update-epic-progress.sh`에 의해 자동 업데이트됩니다.
"""
```

✅ **Step 8 완료** - progress.md 생성 완료

### Step 9: Feature spec.md 템플릿 생성

각 Feature 디렉토리에 spec.md 템플릿 복사:

**Bash 도구로 템플릿 복사**:
```
Bash:
- command: "for feature in {epicDir}/features/*/; do cp .specify/templates/spec-template.md $feature/spec.md; done"
- description: "Copy spec template to each feature"
```

spec-template.md가 없는 경우, 기본 템플릿 생성:

각 Feature에 대해:
```
Write:
- file_path: "{epicDir}/features/{feature-id}/spec.md"
- content: """
# {Feature 이름}

## Metadata
- Feature ID: {feature-id}
- Epic ID: {nextNumber}
- Created: {오늘 날짜}
- Status: pending
- Priority: {priority}
- Estimated Duration: {예상 소요 시간}
- Dependencies: {의존성}

## Overview

{Feature 설명}

이 Feature는 **{epicName}** Epic의 일부입니다.

## User Scenarios & Testing

{Major 워크플로우와 동일 구조}

## Functional Requirements

- FR-001: {요구사항}

## Key Entities

{Feature 고유의 Entity}

## Success Criteria

{Feature 성공 기준}

## Notes

이 Feature는 Major 워크플로우로 구현하세요:
```bash
cd {epicDir}/features/{feature-id}
/major "{Feature 이름}"
```
"""
```

✅ **Step 9 완료** - Feature spec.md 템플릿 생성 완료

### Step 10: Git 브랜치 생성

**Bash 도구로 브랜치 생성**:
```
Bash:
- command: "git checkout -b {nextNumber}-epic-{epicName} 2>/dev/null || echo 'Branch already exists'"
- description: "Create Epic branch"
```

✅ **Step 10 완료** - Git 브랜치 생성 완료

### Step 11: 완료 보고

다음 형식으로 완료 보고를 출력하세요:

```markdown
✅ Epic 워크플로우 완료!

📁 생성된 구조:
.specify/specs/{nextNumber}-epic-{epicName}/
├── epic.md                     ✅ Epic 메타데이터 및 개요
├── roadmap.md                  ✅ Feature 순서 및 의존성
├── progress.md                 ✅ 진행 상황 (0%)
└── features/
    ├── 001-{feature-a}/
    │   └── spec.md             ✅ Feature 사양 (템플릿)
    ├── 002-{feature-b}/
    │   └── spec.md             ✅ Feature 사양 (템플릿)
    └── 003-{feature-c}/
        └── spec.md             ✅ Feature 사양 (템플릿)

📊 Epic 분석:
- Epic ID: {nextNumber}
- Branch: {nextNumber}-epic-{epicName}
- Priority: {priority}
- Total Features: {finalFeatures 개수}
- Estimated Duration: {총 예상 시간}

📋 다음 단계:

### 1. Epic 문서 검토 (권장)
```bash
# Epic 개요 확인
cat {epicDir}/epic.md

# Roadmap 및 의존성 확인
cat {epicDir}/roadmap.md

# 진행 상황 추적 확인
cat {epicDir}/progress.md
```

### 2. Feature 구현 시작
첫 번째 Feature부터 순차적으로 구현하세요:

```bash
cd {epicDir}/features/001-{first-feature}/
/major "{first-feature 이름}"
```

각 Feature는 독립적인 Major 워크플로우로 진행됩니다.

### 3. 진행 상황 자동 업데이트
Feature 완료 시 `progress.md`가 자동으로 업데이트됩니다:
```bash
bash .specify/scripts/bash/update-epic-progress.sh {epicDir}
```

### 4. Epic 검증
Epic 구조가 올바른지 검증:
```bash
bash .specify/scripts/bash/validate-epic.sh {epicDir}
```

💡 Tips:
- 각 Feature는 독립적으로 완료/테스트 가능해야 합니다
- roadmap.md의 의존성 순서를 따라 구현하세요
- Feature 완료 후 반드시 테스트(yarn test)와 빌드(yarn build)를 확인하세요
- 모든 Feature 완료 시 Epic 완료 확인:
  ```bash
  cat {epicDir}/progress.md
  # Completion Rate: 100% 확인
  ```

🎯 Epic 완료 기준:
- [ ] 모든 Feature 완료 (tasks.md 100%)
- [ ] 모든 Feature 테스트 통과
- [ ] 모든 Feature 빌드 성공
- [ ] 통합 테스트 통과
- [ ] progress.md 완료율 100%
```

---

## 🔧 Implementation

이제 위의 프로세스를 실제로 실행하세요.

---

**🚨 중요: 반드시 읽고 따르세요 🚨**

이 섹션은 **실행 명령어**입니다. 다음 규칙을 **반드시** 준수하세요:

1. **Step 0-11을 순차적으로 실행**하세요. 단 하나의 Step도 건너뛸 수 없습니다.
2. **각 Step 완료 시 명시적으로 보고**하세요: "✅ Step X 완료"
3. **AskUserQuestion 도구를 반드시 사용**하세요 (Step 2, 3)
4. **Write 도구로 3개 파일을 반드시 생성**하세요:
   - epic.md (Step 6)
   - roadmap.md (Step 7)
   - progress.md (Step 8)
5. **Feature 디렉토리 및 spec.md 템플릿 생성** (Step 9)
6. **파일 생성 후 검증**하세요: 파일이 실제로 생성되었는지 확인

**이 규칙을 위반하면 워크플로우가 실패합니다.**

---

### 에러 처리

- `.specify/` 없음 → `/start` 실행 안내
- Constitution 없음 → `/start` 실행 안내
- Epic name 중복 → 기존 Epic 덮어쓰기 여부 확인
- Git 브랜치 생성 실패 → 수동 브랜치 생성 안내
- Feature 수 0개 → 에러, 최소 1개 필요
- create-epic.sh 없음 → 수동으로 디렉토리 구조 생성

---

**중요 사항:**
- Step 0-11을 순차적으로 실행하세요
- AI Feature 분해 시 3-5개 권장하되 강제 아님 (2개 이하/6개 이상 경고)
- 사전 조건 확인에서 실패하면 즉시 중단하고 /start 실행 안내
- 3개 파일(epic.md, roadmap.md, progress.md)을 Write 도구로 반드시 생성하세요
- 각 Feature 디렉토리에 spec.md 템플릿 복사
- Epic 완료 기준은 모든 Feature 완료 + 테스트/빌드 성공
