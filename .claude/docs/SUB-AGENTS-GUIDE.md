# 📚 Claude Workflows Sub-Agents 상세 가이드

## 목차
1. [Sub-Agents 아키텍처](#sub-agents-아키텍처)
2. [전체 Sub-Agents 목록](#전체-sub-agents-목록)
3. [상세 사용 가이드](#상세-사용-가이드)
4. [워크플로우별 활용 매트릭스](#워크플로우별-활용-매트릭스)
5. [협업 패턴](#협업-패턴)
6. [성능 최적화 팁](#성능-최적화-팁)

---

## Sub-Agents 아키텍처

### 기본 구조
```yaml
---
name: agent-name          # 에이전트 식별자
description: 설명        # 간단한 설명 (Claude가 활성화 시점 판단)
tools: [...]            # 사용 가능한 도구 목록
model: sonnet/haiku     # 사용할 모델 (기본: sonnet)
---
```

### 동작 원리
1. **독립 컨텍스트**: 각 sub-agent는 별도의 컨텍스트 윈도우를 가짐
2. **자동 활성화**: Task tool을 통해 Claude가 필요 시 자동으로 호출
3. **병렬 실행**: 최대 10개까지 동시 실행 가능
4. **결과 통합**: 각 agent의 결과를 메인 컨텍스트로 수집

---

## 전체 Sub-Agents 목록

### 1. 🔧 quick-fixer
**역할**: Minor 워크플로우 전용 버그 수정 전문가

**주요 기능**:
- 타입 에러 즉시 수정
- Null/Undefined 참조 에러 처리
- React Hook 경고 해결
- 기존 패턴 유지하며 최소 변경

**도구 권한**:
- Read, Edit, Grep, Glob
- Bash(yarn test*), Bash(yarn type-check)

**활성화 조건**:
- 버그 수정 요청
- 타입 에러 발생
- 기존 코드 개선 필요 시

**사용 예시**:
```bash
"VehicleInfo.tsx에서 타입 에러가 발생합니다"
→ quick-fixer 자동 활성화
→ 타입 체크 → 수정 → 테스트 → 완료 보고
```

---

### 2. 📝 changelog-writer
**역할**: Git 변경사항을 Notion으로 자동 문서화

**주요 기능**:
- Git diff 분석 및 요약
- 커밋 메시지 한국어 번역
- Notion 형제 페이지 형식 유지
- 일별/주별/기간별 변경 이력 작성

**도구 권한**:
- Bash(git log*), Bash(git diff*)
- mcp__notion-personal__* (Notion API)

**활성화 조건**:
- "오늘 변경사항 정리"
- "이번 주 changelog"
- "변경 이력 Notion에 작성"

**Notion 페이지 구조**:
```markdown
# YYYY년 MM월 DD일 변경 이력

## 📊 요약
- 변경 파일: N개
- 추가: +NNN 라인
- 삭제: -NNN 라인

## 🔄 주요 변경사항
### 기능명
- 상세 변경 내용...

## 📝 커밋 목록
| 시간 | 커밋 ID | 메시지 | 작성자 |
```

---

### 3. 🏗️ fsd-architect
**역할**: Feature-Sliced Design 아키텍처 검증 전문가

**주요 기능**:
- 레이어 간 import 규칙 검증
- Entity 순수성 체크
- Props 전달 규칙 확인
- 아키텍처 위반 자동 감지

**도구 권한**:
- Read, Grep, Glob

**FSD 검증 규칙**:
```
entities/ → 순수 함수만, state 금지
features/ → 훅 기반 로직, domain props만
widgets/ → features 조합, 최소 로직
pages/ → 라우팅, 위젯 조합
shared/ → 모든 props 허용
```

**활성화 조건**:
- 컴포넌트 생성/수정 시
- 아키텍처 검토 요청
- Major 워크플로우 실행

---

### 4. 🧪 test-guardian
**역할**: Test-First Development 강제 집행관

**주요 기능**:
- 테스트 커버리지 80% 이상 보장
- 구현 전 테스트 작성 강제
- Critical 테스트 자동 실행
- 테스트 품질 검증

**도구 권한**:
- Bash(yarn test*), Bash(yarn test:coverage)
- Read, Write, Grep

**테스트 전략**:
```typescript
// 1. 테스트 먼저 작성
describe('Component', () => {
  it('should handle user action', () => {
    // Given - When - Then
  });
});

// 2. 구현 코드 작성
// 3. 커버리지 확인 (80%+)
```

**활성화 조건**:
- Major 워크플로우 시작
- "테스트 작성해줘"
- 새 기능 구현 시

---

### 5. 🔌 api-designer
**역할**: API 계약 설계 및 httpClient 통합 전문가

**주요 기능**:
- API 엔드포인트 설계
- Request/Response 타입 정의
- 에러 처리 패턴 구현
- React Query 훅 생성
- MSW 목업 자동 생성

**도구 권한**:
- Read, Grep, Write
- WebFetch(domain:*)

**생성 패턴**:
```typescript
// 1. API 타입 정의
interface CreateOrderRequest { ... }
interface CreateOrderResponse { ... }

// 2. httpClient 함수
export const createOrder = async (data: CreateOrderRequest) => {
  return httpClient.post<CreateOrderResponse>('/api/orders', data);
};

// 3. React Query 훅
export const useCreateOrder = () => {
  return useMutation({
    mutationFn: createOrder,
    onSuccess: (data) => { ... }
  });
};

// 4. MSW 핸들러
http.post('/api/orders', async ({ request }) => { ... })
```

**활성화 조건**:
- API 통합 필요 시
- 새 엔드포인트 추가
- Major 워크플로우 API 설계 단계

---

### 6. 📱 mobile-specialist
**역할**: Capacitor 모바일 앱 빌드 전문가

**주요 기능**:
- Android/iOS 빌드 자동화
- 플랫폼별 설정 관리
- 네이티브 API 통합
- 웹 ↔ 네이티브 브릿지 구현

**도구 권한**:
- Bash(npx cap*), Bash(yarn build*)
- Read, Glob, Write

**빌드 프로세스**:
```bash
# 1. 웹 빌드
yarn build:prod

# 2. Capacitor 동기화
npx cap sync

# 3. 플랫폼별 빌드
npx cap open android  # Android Studio
npx cap open ios      # Xcode
```

**활성화 조건**:
- "앱 빌드해줘"
- 네이티브 기능 추가
- 플랫폼별 이슈 해결

---

### 7. 🔍 code-reviewer
**역할**: 코드 품질, 보안, 성능 자동 검토

**주요 기능**:
- XSS/SQL Injection 취약점 탐지
- 성능 최적화 포인트 발견
- 베스트 프랙티스 제안
- PR 자동 리뷰 코멘트

**도구 권한**:
- Bash(git diff*), Read, Grep

**검토 항목**:
```markdown
## 보안 검토
- [ ] XSS 취약점 없음
- [ ] 민감 정보 노출 없음
- [ ] 안전한 API 호출

## 성능 검토
- [ ] 불필요한 리렌더링 없음
- [ ] 메모이제이션 적절
- [ ] 번들 크기 최적

## 코드 품질
- [ ] DRY 원칙 준수
- [ ] 가독성 우수
- [ ] 에러 처리 완벽
```

**활성화 조건**:
- PR 생성 시
- "코드 리뷰해줘"
- Major 워크플로우 완료 단계

---

## 워크플로우별 활용 매트릭스

| Sub-Agent | Major | Minor | Micro |
|-----------|-------|-------|-------|
| quick-fixer | - | ✅ | ✅ |
| changelog-writer | ✅ | ✅ | ⚪ |
| fsd-architect | ✅ | ✅ | - |
| test-guardian | ✅ | ⚪ | - |
| api-designer | ✅ | - | - |
| mobile-specialist | ✅ | ✅ | - |
| code-reviewer | ✅ | ⚪ | - |

- ✅: 자동 활성화
- ⚪: 선택적 활성화
- -: 비활성

---

## 협업 패턴

### 패턴 1: Sequential Chain
```
test-guardian → api-designer → quick-fixer → code-reviewer
```
테스트 작성 → API 설계 → 구현 수정 → 최종 검토

### 패턴 2: Parallel Execution
```
[fsd-architect + code-reviewer] 동시 실행
```
아키텍처 검증과 코드 리뷰를 병렬로 수행

### 패턴 3: Conditional Branching
```
if (모바일 관련) → mobile-specialist
else if (버그) → quick-fixer
else → api-designer
```

---

## 성능 최적화 팁

### 1. 모델 선택 최적화
```yaml
# 간단한 작업은 haiku 모델 사용
model: haiku  # 빠르고 저렴

# 복잡한 분석은 sonnet 모델 사용
model: sonnet  # 정확하고 강력
```

### 2. 도구 권한 최소화
각 agent는 필요한 도구만 사용:
- 읽기 전용: Read, Grep, Glob
- 수정 필요: Edit, Write
- 실행 필요: Bash(특정 명령만)

### 3. 병렬 실행 활용
```typescript
// 독립적인 작업은 병렬로
await Promise.all([
  Task('fsd-architect', 'validate'),
  Task('code-reviewer', 'review'),
  Task('test-guardian', 'check coverage')
]);
```

### 4. 캐싱 전략
- Git diff는 한 번만 실행
- 파일 읽기 결과 재사용
- 테스트 결과 캐싱

### 5. Early Exit
```typescript
// 실패 시 즉시 중단
if (typeCheckFailed) {
  return quickFixer.fix();  // 다른 작업 중단
}
```

---

## 디버깅 가이드

### Sub-Agent 동작 확인
```bash
# 로그 확인
tail -f ~/.claude/logs/agents.log

# 특정 agent 트레이싱
CLAUDE_DEBUG=quick-fixer yarn dev
```

### 일반적인 문제 해결

**문제**: Agent가 활성화되지 않음
- 해결: description이 명확한지 확인
- 해결: 필요한 도구 권한이 있는지 확인

**문제**: 병렬 실행 시 충돌
- 해결: 파일 수정은 순차적으로
- 해결: 읽기 작업만 병렬로

**문제**: 토큰 한도 초과
- 해결: haiku 모델로 변경
- 해결: 작업을 더 작게 분할

---

## 커스터마이징 가이드

### 새 Sub-Agent 추가
```bash
# 1. 파일 생성
touch .claude/agents/my-agent.md

# 2. 헤더 작성
---
name: my-agent
description: 설명
tools: [Read, Write]
model: sonnet
---

# 3. 지시사항 작성
```

### 기존 Agent 수정
1. 필요한 도구 추가/제거
2. 모델 변경 (sonnet ↔ haiku)
3. 프롬프트 개선
4. 검증 로직 추가

---

## 베스트 프랙티스

### DO ✅
- 명확한 단일 책임 부여
- 최소 권한 원칙 적용
- 병렬 실행 적극 활용
- 결과 검증 자동화
- 에러 처리 명확히

### DON'T ❌
- 너무 많은 책임 부여
- 과도한 도구 권한
- 순환 의존성 생성
- 컨텍스트 오염
- 무한 루프 가능성

---

## 참고 자료

- [Claude Code Sub-agents 공식 문서](https://docs.claude.com/en/docs/claude-code/sub-agents)
- [Task Tool API Reference](https://docs.claude.com/api/task-tool)
- [워크플로우 설정 가이드](./WORKFLOW-SETUP.md)
- [Skills 통합 가이드](./SKILLS-GUIDE.md)