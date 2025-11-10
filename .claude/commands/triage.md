---
name: triage
description: 작업 복잡도를 자동 분류하여 최적 워크플로우(Major/Minor/Micro) 선택
---

# 🎯 Triage - 스마트 워크플로우 선택기

작업의 복잡도를 자동으로 분석하여 Major/Minor/Micro 중 최적의 워크플로우를 선택합니다.
토큰 낭비를 방지하고 작업 효율을 극대화합니다.

## 사용법

```bash
/triage "작업 설명"
```

## 작동 프로세스

### 1️⃣ 초기 분석

사용자의 요청을 분석하여 작업 유형과 복잡도를 파악합니다.

### 2️⃣ 재사용 가능 모듈 검색 (신규)

**[자동 실행] reusability-enforcer skill 활성화**

작업에 필요한 기존 모듈을 미리 검색하여 제공합니다:

```markdown
🔍 재사용 가능 모듈 검색 중...

✅ 발견된 재사용 가능 모듈:
• shared/ui/Button - 버튼 컴포넌트
• shared/ui/Input - 입력 필드
• shared/lib/dates/formatDate - 날짜 포맷팅
• entities/vehicle/ui/VehicleCard - 차량 정보 카드

💡 위 모듈들을 우선 사용하여 개발하세요.
```

### 3️⃣ 복잡도 점수 계산

```typescript
function calculateComplexity(request: string): {
  score: number;
  confidence: number;
  factors: string[];
} {
  let score = 0;
  let factors = [];

  // === MICRO 신호 (낮은 복잡도) ===
  if (/오타|typo|주석|comment/i.test(request)) {
    score -= 3;
    factors.push("단순 텍스트 수정");
  }
  if (/console\.log|로그|debug/i.test(request)) {
    score -= 2;
    factors.push("로그 정리");
  }
  if (/스타일|style|css|색상|color/i.test(request)) {
    score -= 2;
    factors.push("스타일 수정");
  }

  // === MINOR 신호 (중간 복잡도) ===
  if (/버그|bug|에러|error|수정|fix/i.test(request)) {
    score += 2;
    factors.push("버그 수정");
  }
  if (/개선|improve|리팩토링|refactor/i.test(request)) {
    score += 3;
    factors.push("코드 개선");
  }
  if (/타입|type|null|undefined/i.test(request)) {
    score += 1;
    factors.push("타입 관련 이슈");
  }

  // === MAJOR 신호 (높은 복잡도) ===
  if (/새\s*기능|new\s*feature|추가|add|생성|create/i.test(request)) {
    score += 5;
    factors.push("새 기능 추가");
  }
  if (/API|엔드포인트|endpoint|통합|integration/i.test(request)) {
    score += 5;
    factors.push("API 통합 필요");
  }
  if (/아키텍처|architecture|설계|design|구조/i.test(request)) {
    score += 6;
    factors.push("아키텍처 변경");
  }
  if (/전체|entire|모든|all|여러|multiple/i.test(request)) {
    score += 3;
    factors.push("다중 파일 영향");
  }
  if (/테스트|test|TDD|커버리지|coverage/i.test(request)) {
    score += 2;
    factors.push("테스트 작성 필요");
  }

  // 신뢰도 계산 (얼마나 확실한지)
  const confidence = Math.min(0.9, 0.5 + (factors.length * 0.1));

  return { score, confidence, factors };
}
```

### 3️⃣ 워크플로우 결정 매트릭스

```yaml
score < 0:
  → Micro 워크플로우
  → 30분 미만 작업
  → 토큰 절약: 85%

score 0-4:
  → Minor 워크플로우
  → 30분-4시간 작업
  → 토큰 절약: 75%

score > 4:
  → Major 워크플로우
  → 4시간 이상 작업
  → 토큰 절약: 60% (품질 최우선)
```

### 4️⃣ 추가 질문 (필요시)

신뢰도가 낮거나 애매한 경우 추가 질문:

```markdown
❓ 좀 더 정확한 분류를 위해 답변해주세요:

1. 이 작업의 영향 범위는?
   [A] 단일 파일
   [B] 2-3개 파일
   [C] 여러 파일/전체 모듈

2. 예상 작업 시간은?
   [A] 30분 미만
   [B] 30분-4시간
   [C] 4시간 이상

3. 테스트 작성이 필요한가요?
   [A] 불필요
   [B] 기존 테스트 수정
   [C] 새 테스트 작성
```

### 5️⃣ 최종 확인 및 실행

```markdown
📊 작업 분류 완료

작업: "{사용자 요청}"

🔍 분석 결과:
• 복잡도 점수: {score}점
• 신뢰도: {confidence}%
• 주요 요인:
  - {factor1}
  - {factor2}
  - {factor3}

📦 재사용 가능 모듈:
• 즉시 사용: {reusable_count}개
• 확장 가능: {extendable_count}개
• 새로 작성: {new_count}개

🎯 선택된 워크플로우: **{workflow}**
• 예상 시간: {time}
• 토큰 절약: {savings}%
• 품질 수준: {quality}

✅ 자동 활성화될 도구:
{tools_list}
• reusability-enforcer (재사용 모듈 검색)
• reusability-metrics (메트릭 추적)

AskUserQuestion 도구를 사용하여 워크플로우 선택:

질문: "어떤 워크플로우로 진행하시겠습니까?"
옵션:
  1. 추천된 {workflow} 워크플로우로 진행
  2. Major 워크플로우 강제 실행
  3. Minor 워크플로우 강제 실행
  4. Micro 워크플로우 강제 실행
```

## 실제 사용 예시

### 예시 1: Micro 작업
```bash
/triage "console.log 제거하고 주석 정리"

🔍 분석 중...
• 복잡도: -5점 (매우 낮음)
• 요인: 로그 정리, 단순 텍스트 수정
→ Micro 워크플로우 (85% 토큰 절약)
```

### 예시 2: Minor 작업
```bash
/triage "VehicleInfo.tsx에서 타입 에러 수정"

🔍 분석 중...
• 복잡도: 3점 (중간)
• 요인: 버그 수정, 타입 관련 이슈
→ Minor 워크플로우 (75% 토큰 절약)
→ quick-fixer 자동 실행
```

### 예시 3: Major 작업
```bash
/triage "주문 생성 API 연동하고 테스트 작성"

🔍 분석 중...
• 복잡도: 12점 (높음)
• 요인: API 통합, 새 기능 추가, 테스트 필요
→ Major 워크플로우 (60% 토큰 절약)
→ /major 실행
```

### 예시 4: 애매한 경우
```bash
/triage "성능 개선"

🔍 분석 중...
• 복잡도: 3점
• 신뢰도: 60% (낮음)

❓ 구체적인 정보가 필요합니다:

1. 어떤 부분의 성능 개선인가요?
   [A] 렌더링 최적화 (컴포넌트)
   [B] API 응답 속도
   [C] 번들 사이즈 최적화
   [D] 전체적인 앱 성능

사용자: A

→ Minor 워크플로우 선택
→ 컴포넌트 최적화 작업 시작
```

## 워크플로우별 자동 실행

### Micro 선택 시
- 최소 검증만 실행
- `yarn lint` 정도만 체크
- 빠른 수정 후 완료

### Minor 선택 시
- `quick-fixer` sub-agent 활성화
- `bug-fix-pattern` skill 자동 로드
- 타입 체크 및 관련 테스트 실행

### Major 선택 시
- /major 워크플로우 시작 (통합 프로세스)
- spec.md → plan.md → tasks.md 자동 생성
- 전체 품질 게이트 적용

## 학습 및 개선

시간이 지나면서 패턴을 학습하여 더 정확한 분류:

```yaml
# .claude/triage-history.yaml
history:
  - request: "타입 에러 수정"
    selected: minor
    actual_time: 15min
    success: true

  - request: "새 결제 모듈 추가"
    selected: major
    actual_time: 6hours
    success: true
```

## 통계 및 효과

```markdown
📈 Triage 사용 통계 (최근 100회)

워크플로우 분포:
• Micro: 35회 (35%)
• Minor: 45회 (45%)
• Major: 20회 (20%)

정확도:
• 초기 선택 정확도: 82%
• 사용자 수정 비율: 18%

토큰 절약:
• 평균 토큰 절약: 71%
• 총 절약된 토큰: 284,000

시간 효율:
• 평균 의사결정 시간: 5초
• 수동 선택 대비: 2분 절약
```

## 장점

✅ **자동화**: Major/Minor/Micro 고민 불필요
✅ **정확성**: 객관적 기준으로 분류
✅ **효율성**: 토큰 낭비 방지
✅ **투명성**: 선택 이유 명확히 설명
✅ **유연성**: 사용자가 최종 결정 가능

## 단축키

- `/t` - triage의 짧은 버전
- M - Major로 강제 변경
- N - Minor로 강제 변경
- C - Micro로 강제 변경

## 팁

1. 요청을 구체적으로 작성할수록 정확도 향상
2. 여러 작업이 있다면 개별로 triage 실행
3. 학습 데이터가 쌓일수록 더 정확해짐

---

이제 작업을 시작할 때 `/triage`만 입력하면 자동으로 최적의 워크플로우가 선택됩니다!

---

## 🔧 Implementation

이제 위의 프로세스를 실제로 실행하세요.

### Step 1: 사용자 요청 분석

사용자가 제공한 작업 설명을 분석하세요:
- 작업 내용: {사용자가 입력한 내용}
- 키워드 추출
- 작업 유형 파악

### Step 2: 복잡도 점수 계산

위의 `calculateComplexity` 로직을 사용하여 점수를 계산하세요:

1. **MICRO 신호 확인** (점수 감소):
   - 오타/typo → -3점
   - console.log/로그 → -2점
   - 스타일/CSS → -2점

2. **MINOR 신호 확인** (점수 증가):
   - 버그/에러/수정 → +2점
   - 개선/리팩토링 → +3점
   - 타입 이슈 → +1점

3. **MAJOR 신호 확인** (점수 증가):
   - 새 기능/추가 → +5점
   - API/통합 → +5점
   - 아키텍처 → +6점
   - 다중 파일 → +3점
   - 테스트 작성 → +2점

4. **최종 점수 계산**:
   - score < 0 → Micro
   - score 0-4 → Minor
   - score > 4 → Major

5. 계산 결과를 다음 변수에 저장:
   - `{complexityScore}`: 계산된 점수
   - `{factors}`: 점수에 기여한 요인들 (배열)
   - `{recommendedWorkflow}`: 추천 워크플로우 (Micro/Minor/Major)

### Step 3: 재사용 가능 모듈 검색

Skill 도구를 사용하여 reusability-enforcer를 실행하세요:

```
Skill: reusability-enforcer
```

결과를 `{reusableModules}` 변수에 저장하세요.

### Step 4: 사용자에게 분석 결과 보고

다음 형식으로 분석 결과를 출력하세요:

```markdown
📊 작업 분류 완료

작업: "{사용자 요청}"

🔍 분석 결과:
• 복잡도 점수: {complexityScore}점
• 주요 요인:
{factors 목록}

📦 재사용 가능 모듈:
{reusableModules 목록}

🎯 추천 워크플로우: **{recommendedWorkflow}**
```

### Step 5: 워크플로우 선택

AskUserQuestion 도구를 사용하여 사용자에게 확인하세요:

질문: "어떤 워크플로우로 진행하시겠습니까?"
헤더: "워크플로우 선택"
multiSelect: false
옵션:
  1. label: "추천된 {recommendedWorkflow} 워크플로우로 진행"
     description: "AI가 분석한 최적의 워크플로우로 자동 진행합니다."
  2. label: "Major 워크플로우 강제 실행"
     description: "신규 기능 개발 프로세스 (통합 워크플로우)"
  3. label: "Minor 워크플로우 강제 실행"
     description: "버그 수정 및 개선 프로세스"
  4. label: "Micro 워크플로우 강제 실행"
     description: "빠른 수정 프로세스"

사용자의 선택을 `{selectedWorkflow}` 변수에 저장하세요.

### Step 6: 선택된 워크플로우 실행

**🚨 중요**: Major 워크플로우는 다단계 프로세스입니다:
1. 사용자에게 핵심 질문 3개를 반드시 물어봅니다
2. 선택적 컨텍스트를 수집합니다
3. spec.md, research.md, data-model.md, plan.md, tasks.md 등 7개 계획 문서를 생성합니다
4. 각 문서는 이전에 생성된 문서를 참조합니다

**절대 이 단계들을 건너뛰지 마세요!**

사용자가 선택한 워크플로우에 따라 SlashCommand 도구를 사용하여 해당 워크플로우를 실행하세요:

**Option 1을 선택한 경우:**
```
SlashCommand: /{recommendedWorkflow를 소문자로} "{사용자 요청}"
```

**Option 2를 선택한 경우:**
```
SlashCommand: /major "{사용자 요청}"
```

**Major 워크플로우 실행 후 확인사항:**
- AskUserQuestion으로 질문을 했는가?
- spec.md 파일이 생성되었는가?
- 나머지 계획 문서들이 생성되었는가?

하나라도 누락되었다면 워크플로우가 잘못 실행된 것입니다.

**Option 3을 선택한 경우:**
```
SlashCommand: /minor "{사용자 요청}"
```

**Option 4를 선택한 경우:**
```
SlashCommand: /micro "{사용자 요청}"
```

### Step 7: 완료

워크플로우가 성공적으로 시작되었음을 사용자에게 알립니다:

```markdown
✅ {selectedWorkflow} 워크플로우 시작됨

재사용 가능 모듈 {reusableModules.length}개가 자동으로 제공됩니다.
```

---

**중요 사항:**
- Step 1-7을 순차적으로 실행하세요
- 각 단계의 결과를 변수에 저장하여 다음 단계에서 사용하세요
- SlashCommand 실행 후에는 해당 워크플로우가 자동으로 진행됩니다