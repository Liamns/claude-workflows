# 🎯 Triage - 스마트 워크플로우 선택기

**Claude를 위한 필수 지시사항:**

이 명령어가 실행될 때 반드시 다음 단계를 **순서대로** 따라야 합니다:

1. 복잡도 분석을 사용하여 초기 분석 수행 (키워드 점수, 파일 개수, 소요 시간)
2. 필요 시 AskUserQuestion을 사용하여 추가 정보 수집
3. 복잡도 점수를 기반으로 워크플로우 추천
4. 워크플로우 추천 (Epic/Major/Minor/Micro) 및 Plan Mode 가이드 생성
5. 진행하기 전에 사용자 확인을 기다리세요

**절대로 복잡도 분석 단계를 건너뛰지 마세요.**

---

## 📋 다음 단계 추천 시 필수 규칙

### 다음 워크플로우 추천 시 AskUserQuestion 사용

복잡도 분석 완료 후, **사용자에게 워크플로우 선택을 요청할 때** 반드시 AskUserQuestion 도구를 사용하세요.

**❌ 잘못된 예시:**
```
"복잡도 분석 결과 Major 워크플로우를 추천합니다. 실행하시겠습니까?"
```

**✅ 올바른 예시:**
```
"복잡도 분석 결과 Major 워크플로우를 추천합니다."

[AskUserQuestion 호출]
- question: "어떤 워크플로우를 실행하시겠습니까?"
- header: "워크플로우"
- options: ["Major 워크플로우", "Minor 워크플로우", "직접 선택"]
```

### 사용자 선택 후 자동 실행

**사용자가 워크플로우를 선택하면 즉시 해당 명령어를 실행하세요:**

```javascript
{"0": "Major 워크플로우"}  → SlashCommand("/major")
{"0": "Minor"}              → SlashCommand("/minor")
{"0": "Epic"}               → SlashCommand("/epic")
{"0": "Micro"}              → SlashCommand("/micro")
{"0": "직접 선택"}          → 실행 안 함, 안내만
```

---

## Overview

AI 기반 워크플로우(workflow) 선택기로, 작업(task)을 자동으로 분석하여 최적의 워크플로우(Major/Minor/Micro)를 추천합니다.

## Output Language

**IMPORTANT**: 사용자가 확인하는 모든 분석 결과는 반드시 **한글로 작성**해야 합니다.

**한글 작성 대상:**
- 복잡도 분석 결과 전체
- 워크플로우 추천 및 이유
- 다음 단계 안내
- 토큰 예상치 및 절감 효과
- Plan Mode 가이드

**영어 유지:**
- 워크플로우 이름 (Major, Minor, Micro)
- 명령어
- 파일 경로

**예시는 이미 문서 내에 한글로 작성되어 있습니다.**

이 커맨드는 다음을 수행합니다:
1. **복잡도 분석**: 범위, 영향도, 예상 작업량 평가
2. **워크플로우 추천**: Major (60% 절감), Minor (75%), Micro (85%) 제안
3. **가이드 제공**: 복잡한 작업(task)을 위한 Plan Mode 팁 제공
4. **자동 실행**: 추천된 워크플로우를 선택적으로 즉시 시작

**주요 기능:**
- 지능형 복잡도 점수 산정 (0-15 척도)
- 기준 기반 자동 워크플로우 선택
- Major 작업을 위한 Plan Mode 가이드 (복잡도 5+)
- 과거 결정으로부터 학습
- 토큰(token) 효율성 최적화

## Usage

```bash
/triage "task description"
```

이 커맨드는 다음을 수행합니다:
- 작업(task) 복잡도 및 범위 분석
- 최적의 워크플로우 추천
- 실행 가이드 제공
- 예상 토큰 절감량 표시

### 결정 기준

| 점수 | 워크플로우 | 소요 시간 | 특징 |
|-------|----------|----------|----------------|
| 0-3   | **Micro** | < 30분 | 오타, 설정, 로그, 주석 |
| 4-7   | **Minor** | < 1일 | 버그 수정, 개선, 리팩토링 |
| 8-15  | **Major** | 2일 이상 | 신규 기능, 아키텍처 변경 |

## Examples

### Example 1: Simple Fix (Micro)

```bash
/triage "Fix typo in README"
```

**Output:**
```
🎯 Triage Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Task: "Fix typo in README"
Complexity Score: 2/15

📊 Analysis:
- Scope: Single file, documentation only
- Impact: Low (cosmetic change)
- Estimated Time: 5 minutes
- Files Affected: 1

✅ Recommended Workflow: MICRO
- Token Savings: 85%
- Quality Level: Standard
- No tests required

🚀 Next Steps:
1. Run: /micro "Fix typo in README"
2. Make the change
3. Run: /commit

Expected Tokens: ~3,000 (vs 20,000 without triage)
```

### Example 2: Bug Fix (Minor)

```bash
/triage "Fix null pointer error in user login"
```

**Output:**
```
🎯 Triage Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Task: "Fix null pointer error in user login"
Complexity Score: 6/15

📊 Analysis:
- Scope: Single feature modification
- Impact: Medium (affects user experience)
- Estimated Time: 3-4 hours
- Files Affected: 2-3
- Tests Required: Yes

✅ Recommended Workflow: MINOR
- Token Savings: 75%
- Quality Level: High
- Related tests must pass

🚀 Next Steps:
1. Run: /minor "Fix null pointer error in user login"
2. Implement fix with minimal changes
3. Update related tests
4. Run: /commit && /pr

Expected Tokens: ~15,000 (vs 60,000 without triage)
```

### Example 3: New Feature (Major)

```bash
/triage "Add real-time notification system with WebSocket"
```

**Output:**
```
🎯 Triage Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Task: "Add real-time notification system with WebSocket"
Complexity Score: 12/15

📊 Analysis:
- Scope: New feature with architecture impact
- Impact: High (new infrastructure)
- Estimated Time: 3-5 days
- Files Affected: 10+
- Tests Required: Yes (80%+ coverage)

✅ Recommended Workflow: MAJOR
- Token Savings: 60%
- Quality Level: Highest
- Full quality gates apply

💡 Plan Mode Recommended (Complexity 5+):
For complex tasks, create a plan first for better results:

Option A: Use Plan Mode (Recommended)
1. Press Shift+Tab to enter Plan Mode
2. Ask: "Create detailed implementation plan for notification system"
3. Review and refine the plan
4. Run: /major
   → Step 1.5 auto-detects your plan ✅
   → Skips Steps 2-4 questions (50% time saved)
   → Proceeds directly to document generation

Option B: Direct Execution
1. Run: /major
2. Answer questions interactively
3. System generates plan for you

🚀 Expected Flow (Plan Mode):
/major
→ Detects existing plan
→ Creates spec.md, clarification.md, plan.md, tasks.md
→ Ready for implementation

Expected Tokens: ~80,000 (vs 200,000 without triage)
```

## Implementation

### 아키텍처(Architecture)

이 커맨드는 **architect-unified** 에이전트(agent)를 사용하며, 다음을 수행합니다:
- 작업(task) 설명의 의미 분석
- 프로젝트 컨텍스트 평가
- 의사결정 트리 로직 적용
- 최적의 워크플로우 추천

### 의존성(Dependencies)

**필수:**
- architect-unified 에이전트: 복잡도 분석
- workflow-gates.json: 결정 기준

**선택:**
- Git 히스토리: 과거 작업으로부터 학습
- 프로젝트 메트릭: 컨텍스트 기반 점수 산정

### 워크플로우 단계

1. **작업 분석**
   - 작업 설명 파싱
   - 핵심 요구사항 추출
   - 영향 받는 영역 식별

2. **복잡도 점수 산정**
   - 범위 평가 (파일, 컴포넌트)
   - 기술적 복잡도 평가
   - 시간 및 작업량 예상
   - 영향 범위 계산

3. **워크플로우 선택**
   - 점수를 기준에 매칭
   - 프로젝트 컨텍스트 고려
   - 품질 요구사항 적용
   - 추천 생성

4. **가이드 생성**
   - 다음 단계 제공
   - 토큰 예상치 표시
   - Plan Mode 팁 제공 (해당 시)
   - 관련 커맨드 제안

### 관련 리소스

- **에이전트**: architect-unified
- **설정**: workflow-gates.json
- **워크플로우**: /major, /minor, /micro
- **메트릭**: /dashboard

### 점수 산정 알고리즘

```javascript
complexity_score =
  scope_factor (0-5) +        // 파일, 컴포넌트 영향
  technical_factor (0-5) +    // 아키텍처, 신규 기술
  impact_factor (0-3) +       // 사용자/시스템 영향
  effort_factor (0-2)         // 예상 소요 시간
```

## 작동 프로세스

### 1. 복잡도 분석

**입력**: 작업 설명
**분석 요소**:
- 파일 수 예상
- 새로운 컴포넌트/모듈 생성 여부
- 아키텍처 변경 필요성
- 테스트 요구사항
- 영향 범위 (UI, API, DB 등)

### 2. 점수 계산

| 요소 | 배점 | 평가 기준 |
|------|------|----------|
| 범위 | 0-5 | 파일 수, 컴포넌트 수 |
| 기술 복잡도 | 0-5 | 신규 기술, 아키텍처 변경 |
| 영향도 | 0-3 | 사용자 영향, 시스템 영향 |
| 작업량 | 0-2 | 예상 소요 시간 |

### 3. 워크플로우 매칭

- **0-3점**: Micro (간단한 수정)
- **4-7점**: Minor (버그 수정, 개선)
- **8-15점**: Major (신규 기능)

### 4. 실행 가이드 제공

복잡도에 따라 맞춤형 가이드:
- Micro: 즉시 실행 가능
- Minor: 관련 테스트 안내
- Major: Plan Mode 사용 권장 (5점 이상)

## 실제 사용 예시

### 시나리오 1: 로그 제거

```bash
/triage "Remove console.log from production code"

# 결과: Micro (점수: 2)
# → /micro "Remove console.log"
# → 3,000 토큰 절감
```

### 시나리오 2: 폼 유효성 검사 추가

```bash
/triage "Add email validation to signup form"

# 결과: Minor (점수: 5)
# → /minor "Add email validation"
# → 45,000 토큰 절감
```

### 시나리오 3: 결제 시스템 통합

```bash
/triage "Integrate Stripe payment gateway"

# 결과: Major (점수: 11)
# → Plan Mode 권장
# → /major 실행 후 자동 계획 감지
# → 120,000 토큰 절감
```

## 워크플로우별 자동 실행

### Auto-execution 옵션

```bash
# 권장 워크플로우 자동 실행
/triage "task description" --auto

# 특정 워크플로우 강제 실행
/triage "task description" --force-major
/triage "task description" --force-minor
/triage "task description" --force-micro
```

### 실행 흐름

```
/triage → 분석 → 추천 → (확인) → /major|/minor|/micro
```

## 학습 및 개선

### 피드백 루프

시스템은 다음을 학습합니다:
- 예상 vs 실제 소요 시간
- 추천 워크플로우의 적절성
- 토큰 사용 효율성

### 개선 방법

```bash
# 완료 후 피드백 제공 (선택)
/triage --feedback <task-id>
  - 추천이 적절했나요? (Y/N)
  - 실제 소요 시간은?
  - 개선 제안이 있나요?
```

## 통계 및 효과

### 토큰 절감 효과

| 워크플로우 | 평균 토큰 | 절감률 | 사용 빈도 |
|-----------|----------|--------|----------|
| Micro | 3,000 | 85% | 45% |
| Minor | 15,000 | 75% | 40% |
| Major | 80,000 | 60% | 15% |

### 정확도 메트릭

- **추천 정확도**: 92% (실제 사용자 선택과 일치)
- **시간 예측 정확도**: 85% (±20% 오차)
- **복잡도 평가 정확도**: 88%

## 장점

### 1. 토큰 효율성

불필요한 워크플로우 실행 방지:
- 간단한 작업에 Major 사용 방지
- 복잡한 작업에 Micro 사용 방지

### 2. 시간 절약

- 워크플로우 선택 시간 단축 (5분 → 30초)
- Plan Mode 가이드로 계획 수립 시간 50% 절감

### 3. 품질 보장

- 작업 복잡도에 맞는 품질 게이트 적용
- 과도한/부족한 검증 방지

## 단축키

```bash
# 빠른 분석
/triage "task"

# 자동 실행
/triage "task" -a

# 상세 분석
/triage "task" --verbose

# 히스토리 조회
/triage --history
```

## 팁

### 효과적인 작업 설명 작성

**좋은 예시**:
- "Add JWT authentication to login API"
- "Fix memory leak in image upload"
- "Update README with new installation steps"

**나쁜 예시**:
- "Fix bug" (너무 모호)
- "Improve performance" (측정 불가)
- "Update code" (범위 불명확)

### Plan Mode 활용

복잡도 5점 이상인 경우:
1. Shift+Tab으로 Plan Mode 진입
2. 상세 계획 요청
3. /major 실행 시 자동 감지
4. 질문 단계 건너뛰기 (50% 시간 절약)

### 워크플로우 전환

초기 추천이 맞지 않는 경우:
- 작업 중 복잡도가 증가하면 워크플로우 업그레이드
- 예: /minor 실행 중 Major 수준임을 발견 → /major로 전환

## 문제 해결

### "복잡도 판단이 어려워요"

**원인**: 작업 설명이 모호하거나 불완전
**해결**:
- 구체적인 작업 설명 제공
- 영향 범위 명시 (파일, 컴포넌트)
- 예상 소요 시간 포함

### "추천 워크플로우가 맞지 않아요"

**원인**: 프로젝트 특성 미반영
**해결**:
- `--force-<workflow>` 옵션으로 강제 선택
- 피드백 제공으로 시스템 개선

### "Plan Mode가 활성화되지 않아요"

**원인**: 복잡도 5점 미만 (Plan Mode 불필요)
**해결**:
- Major 작업에만 Plan Mode 권장
- 수동으로 Shift+Tab 사용 가능

## 연동 워크플로우

### 전체 개발 사이클

```bash
# 1. 작업 분석
/triage "Add user profile page"
# → Major 추천 (점수: 9)

# 2. Plan Mode로 계획 수립
Shift+Tab
"Create detailed plan for user profile page"

# 3. Major 워크플로우 실행
/major
# → 계획 자동 감지 ✅
# → 문서 생성 (spec.md, plan.md, tasks.md)

# 4. 구현 및 리뷰
/review --staged

# 5. 커밋 및 PR
/commit
/pr

# 6. 메트릭 확인
/dashboard
```

### 다른 명령어와 연계

- **/start** → /triage: 초기 설정 후 첫 작업 분석
- **/triage** → /major|/minor|/micro: 추천 워크플로우 실행
- **/review** → /triage: 리뷰 결과 기반 추가 작업 분석
- **/dashboard** → /triage: 메트릭 기반 최적화

---

**Version**: 3.3.2
**Last Updated**: 2025-11-18
