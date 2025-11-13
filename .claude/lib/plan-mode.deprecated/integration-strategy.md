# Plan Mode Integration Strategy (Revised)

## 핵심 발견

ExitPlanMode는 **데이터 반환 도구가 아니라 모드 전환 신호**입니다.

## 수정된 통합 방법

### Before (잘못된 가정)
```
User → /triage → Plan Mode 진입
  → Plan Mode에서 계획 수립
  → ExitPlanMode 호출
  → **구조화된 데이터 반환** ← 잘못됨
  → Major 워크플로우 변수에 매핑
```

### After (올바른 접근)
```
User → /triage → Plan Mode 진입 제안
  ↓
[Option A] Plan Mode 사용:
  → "Plan Mode로 계획을 수립하세요"
  → Claude가 Plan Mode에서 계획 작성 (자연어)
  → ExitPlanMode 호출
  → **사용자가 계획 내용을 복사**
  → /major 실행 시 계획 내용 붙여넣기
  
[Option B] Plan Mode 건너뛰기:
  → 기존 /major 워크플로우 실행
  → Step 2-5에서 질문-응답
```

## 실용적 통합 방안

### 1. Soft Integration (권장)

**Triage에서 Plan Mode 안내**:
```bash
/triage "복잡한 기능"
→ 복잡도 12점 (Major)

💡 추천: Plan Mode로 계획 수립 후 /major 실행

다음 단계:
1. Shift+Tab으로 Plan Mode 진입
2. "이 기능의 상세 계획을 작성해주세요" 요청
3. 계획 완료 후 내용 복사
4. /major 실행 시 계획 내용 붙여넣기
```

**장점**:
- ExitPlanMode API 의존성 제거
- 사용자가 계획 내용 직접 확인/수정 가능
- 구현 복잡도 낮음

**단점**:
- 자동화 수준 낮음 (수동 복사-붙여넣기)

### 2. Context-based Integration

**Plan Mode 세션 컨텍스트 활용**:
```bash
# Plan Mode에서 작성된 계획을 대화 컨텍스트에 저장
# /major 실행 시 이전 대화 내용 참조

/triage → "Plan Mode 권장"
→ User: Shift+Tab (Plan Mode 진입)
→ User: "상세 계획 작성해주세요"
→ Claude: [계획 작성]
→ User: "/major 위 계획대로 진행"
→ Claude: **대화 컨텍스트에서 계획 추출**
```

**장점**:
- 자동화 가능
- 사용자 복사-붙여넣기 불필요

**단점**:
- 대화 컨텍스트 의존
- 계획 내용 파싱 필요

### 3. Hybrid Approach (최종 권장)

**Plan Mode 활용 + Manual Fallback**:

```typescript
if (complexityScore >= 5) {
  showPlanModeGuide();
  
  // Option 1: Plan Mode 사용 (권장)
  guide = `
  📋 복잡한 작업입니다. Plan Mode 사용을 권장합니다:
  
  1. Shift+Tab → Plan Mode 진입
  2. "이 기능의 상세 계획을 작성해주세요"
  3. 계획 완료 후 ExitPlanMode
  4. /major 실행 (계획 내용이 자동 참조됨)
  `;
  
  // Option 2: 바로 Major 실행
  option = "Plan Mode 건너뛰고 바로 /major 실행";
}
```

**구현**:
- Triage: Plan Mode 안내 메시지 추가
- Major: 이전 대화에서 "계획" 키워드 검색
- 계획 발견 시 Step 2-5 자동 채움

## 결론

ExitPlanMode의 실제 역할:
- ❌ 데이터 API (구조화된 JSON 반환)
- ✅ 모드 전환 신호 (사용자에게 프롬프트)

**권장 접근**:
1. Triage에서 Plan Mode 사용 안내
2. Plan Mode 계획을 대화 컨텍스트로 활용
3. Major 워크플로우에서 컨텍스트 파싱
4. Fallback: 수동 질문-응답

이 접근은 ExitPlanMode API에 의존하지 않으면서도 Plan Mode의 이점을 활용합니다.
