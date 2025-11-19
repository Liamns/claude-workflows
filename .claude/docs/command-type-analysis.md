# 슬래시 명령어 구조 분석 및 분류

## 📋 요약

현재 프로젝트의 슬래시 명령어는 **3가지 유형**으로 분류됩니다:

1. **워크플로우 명령어** - AI 주도형, .md 파일 기반
2. **유틸리티 명령어** - 스크립트 기반, YAML 설정 중심
3. **하이브리드 명령어** - 두 가지 특성을 혼합

---

## 1️⃣ 유형 1: 워크플로우 명령어

### 특징
- **AI가 주도적으로 사고하고 계획을 수립**
- **.md 파일을 매번 읽고 해석**하여 실행
- **대화형 프로세스**가 핵심
- Claude의 판단과 추론이 필요

### 해당 명령어
- `/epic` - Epic 단위 대규모 프로젝트
- `/major` - 주요 기능 추가 (2일 이상)
- `/minor` - 버그 수정, 개선 (1일 이내)
- `/micro` - 간단한 수정 (30분 이내)

### 실행 흐름
```
사용자 요청
  ↓
.md 파일 읽기 및 해석
  ↓
AI가 상황 분석 및 계획 수립
  ↓
대화형 질문 (현재: 텍스트 출력 방식)
  ↓
사용자 답변
  ↓
AI가 문서 생성 (.specify/ 디렉토리)
  ↓
구현 진행
  ↓
품질 게이트 검증
```

### YAML 설정 구조
```yaml
command: "major"
type: "workflow"
extends: "_base.yaml"

workflow:
  quality_level: "highest"
  gates:
    pre_implementation: [...]
    during_implementation: [...]
    post_implementation: [...]

agents:
  - "architect-unified"
  - "implementer-unified"
  - "reviewer-unified"

skills:
  - "reusability-enforcer"
```

### 개선 필요사항
✅ **AskUserQuestion 도구 활용** - 현재 텍스트 기반 질의응답을 선택형 UI로 전환
✅ **흐름 중단 방지** - 사용자 개입 후 컨텍스트 유지

---

## 2️⃣ 유형 2: 유틸리티 명령어

### 특징
- **약속된 기준으로 자동 실행**
- **.sh 스크립트가 핵심 로직 처리**
- **YAML 설정 파일로 동작 제어**
- AI는 스크립트 호출과 결과 처리만 수행

### 해당 명령어
- `/db-sync` - 데이터베이스 동기화
- `/prisma-migrate` - Prisma 마이그레이션
- `/dashboard` - 메트릭 대시보드

### 실행 흐름
```
사용자 요청
  ↓
YAML 설정 로드
  ↓
.sh 스크립트 실행
  ↓
결과 반환 및 출력
  ↓
(선택) 후속 작업 제안
```

### YAML 설정 구조
```yaml
command: "db-sync"
type: "utility"
extends: "_base.yaml"

script:
  path: ".claude/lib/db-sync.sh"
  status: "implemented"

supporting_scripts:
  - path: ".claude/lib/db-utils.sh"
```

### 개선 필요사항
✅ **결과 기반 추천** - 실행 후 다음 단계를 AskUserQuestion으로 제안
✅ **에러 처리** - 스크립트 실패 시 사용자 선택지 제공

---

## 3️⃣ 유형 3: 하이브리드 명령어

### 특징
- **AI 분석 + 스크립트 실행 혼합**
- **YAML 설정으로 복잡도 계산 규칙 정의**
- **.md 파일로 출력 형식 가이드 제공**
- **대화형 요소와 자동화의 균형**

### 해당 명령어
- `/triage` - 작업 복잡도 분석 및 워크플로우 추천
- `/commit` - Git 커밋 메시지 생성
- `/pr` - Pull Request 생성 및 검토
- `/pr-review` - PR 리뷰 자동화
- `/review` - 코드 리뷰
- `/start` - 프로젝트 초기 설정

### 실행 흐름 예시 (triage)
```
사용자: 작업 설명 제공
  ↓
YAML의 keyword_scores로 복잡도 계산
  ↓
.md 파일의 출력 형식에 맞춰 결과 표시
  ↓
워크플로우 추천 (Micro/Minor/Major/Epic)
  ↓
(현재) 텍스트로 다음 명령어 제안
  ↓
(개선안) AskUserQuestion으로 즉시 실행 옵션 제공
```

### YAML 설정 구조
```yaml
command: "triage"
type: "utility"
extends: "_base.yaml"

complexity_calculation:
  enabled: true
  keyword_scores:
    architecture: 8
    api: 5
    bugfix: 2
    typo: -1

  weights:
    keywords: 0.35
    file_count: 0.20
    duration: 0.25

classification:
  thresholds:
    epic: { min_score: 15 }
    major: { min_score: 8, max_score: 14 }
    minor: { min_score: 3, max_score: 7 }
    micro: { min_score: 0, max_score: 2 }

prompts:
  initial_questions: [...]
  confirmation:
    enabled: true
    allow_override: true
```

### 개선 필요사항
✅ **AskUserQuestion 통합** - 현재 YAML에 정의된 `prompts` 섹션을 AskUserQuestion으로 변환
✅ **자동 실행 옵션** - 추천 워크플로우를 선택하면 바로 실행

---

## 📊 명령어별 분류표

| 명령어 | 타입 | 주요 의존성 | AI 사고 필요 | 스크립트 실행 |
|--------|------|------------|------------|-------------|
| `/epic` | 워크플로우 | .md | ✅ 높음 | ❌ |
| `/major` | 워크플로우 | .md | ✅ 높음 | ❌ |
| `/minor` | 워크플로우 | .md | ✅ 높음 | ❌ |
| `/micro` | 워크플로우 | .md | ✅ 높음 | ❌ |
| `/db-sync` | 유틸리티 | .sh + YAML | ❌ 낮음 | ✅ |
| `/prisma-migrate` | 유틸리티 | .sh + YAML | ❌ 낮음 | ✅ |
| `/dashboard` | 유틸리티 | .sh + YAML | ⚠️ 중간 | ✅ |
| `/triage` | 하이브리드 | .md + YAML | ✅ 중간 | ⚠️ 부분적 |
| `/commit` | 하이브리드 | .md + YAML | ✅ 중간 | ✅ |
| `/pr` | 하이브리드 | .md + .sh | ✅ 중간 | ✅ |
| `/pr-review` | 하이브리드 | .md + .sh | ✅ 높음 | ✅ |
| `/review` | 하이브리드 | .md + YAML | ✅ 높음 | ⚠️ 부분적 |
| `/start` | 하이브리드 | .md + YAML | ✅ 중간 | ⚠️ 부분적 |

---

## 🎯 각 타입별 권장 실행 흐름

### 유형 1 (워크플로우) - 권장 흐름
1. **.md 파일 읽기** - 매번 최신 가이드라인 적용
2. **계획 단계** - Plan Mode 감지 및 활용
3. **AskUserQuestion 사용** - 선택형 질문으로 대화 효율화
4. **문서 생성** - .specify/ 디렉토리에 계획 문서 작성
5. **품질 게이트** - 단계별 검증
6. **결과 보고** - 다음 단계 추천 (AskUserQuestion)

### 유형 2 (유틸리티) - 권장 흐름
1. **YAML 설정 로드** - 필요한 파라미터 확인
2. **.sh 스크립트 실행** - 표준화된 로직 수행
3. **결과 파싱** - 성공/실패/경고 분류
4. **사용자 피드백** - 에러 시 AskUserQuestion으로 옵션 제공
5. **후속 작업 제안** - 다음 단계 자동 추천

### 유형 3 (하이브리드) - 권장 흐름
1. **초기 분석** - YAML 기반 자동 분석
2. **AskUserQuestion** - 필요 시 추가 정보 수집
3. **스크립트 실행** - 자동화 가능한 부분 처리
4. **AI 판단** - 스크립트 결과 기반 의사결정
5. **통합 결과 제시** - .md 형식 + 선택형 다음 단계

---

## 🔍 현재 발견된 문제점

### 문제 1: 질의응답 방식의 비효율성
**현재 상황:**
```
AI: 다음 중 선택하세요:
A. Major workflow
B. Minor workflow
C. Micro workflow

사용자가 "A" 또는 "Major" 또는 "첫 번째"라고 입력
```

**개선안:**
```typescript
AskUserQuestion({
  questions: [{
    question: "어떤 워크플로우를 실행하시겠습니까?",
    header: "워크플로우",
    multiSelect: false,
    options: [
      { label: "Major", description: "신규 기능 추가 (2일 이상)" },
      { label: "Minor", description: "버그 수정, 개선 (1일 이내)" },
      { label: "Micro", description: "간단한 수정 (30분 이내)" }
    ]
  }]
})
```

### 문제 2: 흐름 중단 문제
**발생 시나리오:**
```
/major 실행 중...
→ Step 1.5: 계획 확인
→ 사용자: "잠깐, 이 부분 수정해줘"
→ AI: (일반 채팅으로 인식, /major 흐름 이탈)
```

**해결 방안:**
- 명령어 컨텍스트 유지 메커니즘 필요
- 사용자 개입 후 자동으로 원래 흐름 복귀
- 또는 명시적으로 "계속하시겠습니까?" 질문 (AskUserQuestion)

### 문제 3: 추천 명령어 실행의 비효율성
**현재 상황:**
```
/triage 결과: "Major workflow를 추천합니다"
사용자: (직접 "/major" 입력 필요)
```

**개선안:**
```typescript
AskUserQuestion({
  questions: [{
    question: "추천된 워크플로우를 실행하시겠습니까?",
    header: "다음 단계",
    options: [
      { label: "Major 실행", description: "추천된 워크플로우 시작" },
      { label: "다른 워크플로우 선택", description: "수동 선택" },
      { label: "나중에", description: "분석 결과만 확인" }
    ]
  }]
})
```

---

## ✅ 개선 작업 계획

### 1단계: AskUserQuestion 도구 통합
- [ ] 워크플로우 명령어의 모든 질문을 AskUserQuestion으로 전환
- [ ] 하이브리드 명령어의 YAML prompts를 AskUserQuestion으로 매핑
- [ ] 각 질문의 최적 옵션 개수 (2-4개) 및 설명 작성

### 2단계: 명령어 추천 자동화
- [ ] /triage → 추천 워크플로우 즉시 실행 옵션
- [ ] /commit → /pr 실행 제안
- [ ] /pr → /dashboard 메트릭 확인 제안
- [ ] 모든 추천을 AskUserQuestion으로 구현

### 3단계: 흐름 중단 방지
- [ ] 명령어 컨텍스트 추적 시스템 구현
- [ ] 사용자 개입 감지 및 컨텍스트 저장
- [ ] 복귀 시 자동으로 이전 단계 상기
- [ ] "중단된 명령어 계속하기" 옵션 제공

### 4단계: 미사용 파일 정리
- [ ] 모든 .sh 스크립트의 참조 확인
- [ ] 모든 YAML 파일의 활용도 검증
- [ ] 미사용 파일 아카이브 또는 삭제
- [ ] 문서화 업데이트

---

## 📝 결론

현재 프로젝트의 슬래시 명령어는 **체계적으로 3가지 타입**으로 분류되어 있습니다:

1. **워크플로우 명령어**: AI 주도형, 복잡한 사고 과정 필요
2. **유틸리티 명령어**: 스크립트 기반, 표준화된 자동 실행
3. **하이브리드 명령어**: 두 가지의 장점 결합

각 타입은 **명확한 역할과 실행 흐름**을 가지고 있으며, YAML 설정을 통해 일관성을 유지합니다.

**주요 개선 방향**:
- AskUserQuestion 도구를 활용한 사용자 경험 개선
- 명령어 간 자동 연계 강화
- 흐름 중단 방지 메커니즘 구현

이러한 개선을 통해 사용자 경험과 워크플로우 효율성을 크게 향상시킭니다.
