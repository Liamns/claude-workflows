# 🚀 Major - 통합 워크플로우 v2.0

## Overview

Complete workflow for implementing new features with 60% token savings through intelligent caching and optimized agent coordination.

This command:
1. **Gathers Requirements**: Creates comprehensive specification documents
2. **Analyzes Reusability**: Searches for existing patterns to avoid duplication
3. **Designs Architecture**: Generates technical design and implementation plan
4. **Creates Tasks**: Breaks down work into actionable, testable tasks
5. **Validates Quality**: Enforces all quality gates from workflow-gates.json

**Key Features:**
- Plan Mode auto-detection (skip Steps 2-4 if plan exists)
- 60% token savings through smart-cache system
- Reusability enforcement via reusability-enforcer skill
- Architecture compliance validation
- Test coverage requirements (80%+)
- Full quality gates from workflow-gates.json

## Usage

```bash
/major
```

The command will:
- Interactively gather requirements (or detect existing plan)
- Search for reusable components
- Generate spec.md, clarification.md, plan.md, tasks.md
- Validate against project constitution
- Create implementation roadmap

### Prerequisites

- Git repository initialized
- Architecture configured (run `/start` first)
- Constitution file: `.specify/memory/constitution.md`
- Quality gates: `.claude/workflow-gates.json`

## Examples

### Example 1: New Feature with Plan Mode

```bash
# Step 1: Create plan in Plan Mode (Shift+Tab)
Shift+Tab
"Create detailed implementation plan for user authentication system with JWT"

# Step 2: Run Major workflow
/major
```

**Output:**
```
🚀 Major Workflow - New Feature Implementation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Step 1: Requirements Gathering
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Detected existing plan in conversation history
✓ Auto-populating requirements from plan
✓ Skipping Steps 2-4 (50% time saved)

Creating documents...
✓ spec.md created (requirements summary)
✓ clarification.md created (technical questions)
✓ plan.md created (implementation strategy)
✓ tasks.md created (actionable task list)

📊 Reusability Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Searching for existing patterns...
✓ Found: src/shared/lib/api/apiClient.ts (API client)
✓ Found: src/shared/lib/storage/tokenStorage.ts (Token storage)
✓ Found: src/features/auth/ui/LoginForm.tsx (Similar form)

⚡ Recommendations:
- Reuse apiClient for HTTP requests
- Extend tokenStorage for JWT management
- Follow LoginForm pattern for AuthForm

Token Savings: 18,000 (from reusability)

🎯 Quality Gates Applied
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

From workflow-gates.json:
✓ Architecture compliance required
✓ Test coverage minimum: 80%
✓ Related tests must pass
✓ No breaking changes without migration
✓ Constitution check enabled

📝 Next Steps
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Documents created in .claude/docs/features/auth-system/
1. Review spec.md for requirements accuracy
2. Read clarification.md for technical decisions
3. Follow plan.md for implementation strategy
4. Execute tasks.md step-by-step

Ready to implement!
Expected tokens: ~80,000 (vs 200,000 without optimization)
```

### Example 2: Interactive Mode (No Plan)

```bash
/major
```

**Prompts:**
```
What feature are you implementing?
> User profile page with avatar upload

What are the user scenarios? (Enter to skip)
> 1. View current profile
> 2. Edit name and email
> 3. Upload profile picture
> [Enter]

Any technical constraints? (Enter to skip)
> Must work on mobile, max 2MB image size
> [Enter]

Creating specification...
✓ spec.md created
✓ Asking 5 clarification questions...
✓ clarification.md updated
✓ plan.md generated
✓ tasks.md created

Ready to implement!
```

### Example 3: Architecture-Specific Feature (FSD)

```bash
/major
```

**Task:** "Add shopping cart feature"

**Generated Structure:**
```
features/cart/
├── ui/
│   ├── CartWidget.tsx        # Main cart component
│   ├── CartItem.tsx          # Individual item
│   └── CartButton.tsx        # Add to cart button
├── model/
│   ├── useCart.ts            # Cart state management
│   ├── cartSlice.ts          # Redux/state logic
│   └── types.ts              # TypeScript types
├── api/
│   └── cartApi.ts            # API calls
└── index.ts                  # Public API

Generated with FSD compliance:
✓ Proper layer separation
✓ Public API via index.ts
✓ No upper layer dependencies
✓ Reused entities/product
```

## Implementation

### Architecture

The Major workflow orchestrates 6 unified agents:
- **architect-unified**: Requirements gathering, architecture design
- **reusability-enforcer**: Search for existing patterns (auto-runs)
- **implementer-unified**: Generate plan and tasks
- **reviewer-unified**: Validate against constitution
- **smart-cache**: Token optimization (70% cache hit rate)
- **documenter-unified**: Generate documentation

### Dependencies

**Required:**
- All unified agents (architect, reusability-enforcer, implementer, reviewer, documenter)
- Constitution file: `.specify/memory/constitution.md`
- Quality gates: `.claude/workflow-gates.json`
- Architecture config: `.specify/config/architecture.json`

**Optional:**
- Git repository for commit tracking
- Notion MCP for changelog integration

### Workflow Steps

**Step 1: Plan Detection & Requirements (5-10 min)**
- Check conversation history for existing plan
- If found: Auto-populate and skip to Step 5
- If not: Interactive Q&A to gather requirements
- Output: Initial requirements draft

**Step 2: Clarification Questions (5-10 min)**
- Architect-unified analyzes requirements
- Generates 3-7 technical questions
- User answers interactively
- Output: clarification.md

**Step 3: Reusability Analysis (automatic)**
- Reusability-enforcer skill searches codebase
- Identifies existing patterns, components, utilities
- Suggests reuse opportunities
- Output: Reusability recommendations in plan.md

**Step 4: Design & Planning (10-15 min)**
- Generate technical specification (spec.md)
- Create implementation plan (plan.md)
- Define quality gates and acceptance criteria
- Validate against constitution
- Output: Complete design documents

**Step 5: Task Breakdown (5-10 min)**
- Break implementation into user stories
- Create sequential, testable tasks
- Add verification steps
- Include reusability checks
- Output: tasks.md

**Step 6: Validation (automatic)**
- Check constitution compliance
- Verify quality gate definitions
- Validate architecture constraints
- Review reusability enforcement
- Output: Validation report

### Related Resources

- **Documents**: `.claude/docs/features/<feature-name>/`
  - `spec.md`: Requirements and scenarios
  - `clarification.md`: Technical decisions
  - `plan.md`: Implementation strategy
  - `tasks.md`: Actionable task list
- **Configuration**: `workflow-gates.json`
- **Constitution**: `.specify/memory/constitution.md`
- **Agents**: All 6 unified agents

### Token Optimization

**Smart-Cache System:**
- File caching: 70% hit rate
- Test caching: 85% hit rate
- Analysis caching: 60% hit rate
- Total savings: 60% on average

**Reusability Impact:**
- Pattern detection: -15,000 tokens
- Component reuse: -20,000 tokens
- Architecture validation: -10,000 tokens

**Plan Mode Benefit:**
- Skip Steps 2-4: -40,000 tokens
- Direct to document generation
- 50% time reduction

## 생성되는 문서

### 1. spec.md (요구사항 명세서)

**포함 내용:**
- Metadata: 작업 ID, 날짜, 복잡도 점수
- User Scenarios: 사용자 시나리오와 테스트 케이스
- Functional Requirements: 기능 요구사항
- Key Entities: 핵심 엔티티와 데이터 구조
- Success Criteria: 성공 기준
- Assumptions & Constraints: 가정과 제약사항
- Open Questions: 미해결 질문

**예시:**
```markdown
# Spec: User Authentication System

## Metadata
- Feature ID: AUTH-001
- Complexity: 12/15 (Major)
- Estimated: 3-5 days
- Created: 2025-11-18

## User Scenarios
1. [US1] Login with Email
   - User enters email/password
   - System validates credentials
   - User receives JWT token
   - User is redirected to dashboard

## Success Criteria
- 80%+ test coverage
- Login < 500ms
- JWT expires in 24h
- Refresh token support
```

### 2. clarification.md (기술 질문/답변)

**포함 내용:**
- Technical Questions: 기술적 의사결정 필요 항목
- Answered Questions: 답변된 질문과 결정사항
- Pending Questions: 미해결 질문
- Technical Feasibility: 기술적 실현 가능성
- Risks & Mitigation: 리스크와 완화 방안

**예시:**
```markdown
# Clarification: Auth System

## Questions & Answers

Q1: Which authentication strategy?
A: JWT with refresh tokens (industry standard)

Q2: Password hashing algorithm?
A: bcrypt with salt rounds = 10

Q3: Token storage location?
A: HttpOnly cookies for security

## Technical Decisions
- Use existing apiClient from shared/lib
- Store tokens in httpOnly cookies
- Implement refresh token rotation
```

### 3. plan.md (구현 계획)

**포함 내용:**
- Existing Solutions Analysis: 기존 솔루션 분석
- Technical Foundation: 기술적 기반
- Constitution Check: 아키텍처 규칙 확인
- Source Code Structure: 소스 코드 구조
- Implementation Phases: 구현 단계
- Estimated Timeline: 예상 소요 시간

**예시:**
```markdown
# Implementation Plan: Auth System

## Reusability Analysis
Found reusable components:
- src/shared/lib/api/apiClient.ts ✓
- src/shared/lib/storage/tokenStorage.ts ✓
- src/features/auth/ui/LoginForm.tsx (pattern)

## Constitution Check
✓ FSD layer separation maintained
✓ No upper layer dependencies
✓ Public API via index.ts

## Source Code Structure
features/auth/
├── ui/
│   ├── LoginForm.tsx
│   ├── RegisterForm.tsx
│   └── PasswordReset.tsx
├── model/
│   ├── useAuth.ts
│   └── authSlice.ts
├── api/
│   └── authApi.ts
└── index.ts

## Implementation Phases
Phase 1: Setup (1 day)
- Install dependencies (bcrypt, jsonwebtoken)
- Create feature structure
- Setup API endpoints

Phase 2: Core Logic (2 days)
- Implement login/register
- Add JWT generation
- Token validation

Phase 3: UI Components (1 day)
- Build forms
- Add validation
- Error handling

Phase 4: Testing (1 day)
- Unit tests (80%+)
- Integration tests
- E2E scenarios
```

### 4. tasks.md (작업 목록)

**포함 내용:**
- Task Format: 체크리스트 형식
- Phase Breakdown: 단계별 작업 분류
- User Story Grouping: 사용자 스토리별 그룹화
- Verification Steps: 각 작업의 검증 단계
- Dependencies: 작업 간 의존성

**예시:**
```markdown
# Tasks: Auth System Implementation

## Phase 1: Setup & Prerequisites

### Task 1.1: Project Setup
- [ ] Install dependencies: bcrypt, jsonwebtoken
- [ ] Create features/auth/ directory structure
- [ ] Setup TypeScript types
- [ ] Configure API routes

Verification:
- Directory structure matches plan.md
- All dependencies installed
- TypeScript compiles without errors

### Task 1.2: Reusability Integration
- [ ] Import apiClient from shared/lib
- [ ] Extend tokenStorage for JWT
- [ ] Reuse validation patterns from shared/lib/validation

Verification:
- No duplicate API client code
- TokenStorage tests pass
- Reusability enforcer satisfied

## Phase 2: User Story - [US1] Login with Email

### Task 2.1: Backend - Login Endpoint
- [ ] Create POST /api/auth/login route
- [ ] Implement password verification (bcrypt)
- [ ] Generate JWT token
- [ ] Set httpOnly cookie

Files to modify:
- features/auth/api/authApi.ts (new)
- src/app/api/routes.ts (update)

Verification:
- Endpoint returns 200 on valid credentials
- JWT token valid for 24h
- Cookie is httpOnly and secure

### Task 2.2: Frontend - Login Form
- [ ] Create LoginForm component
- [ ] Add form validation
- [ ] Integrate with authApi
- [ ] Handle errors

Files to modify:
- features/auth/ui/LoginForm.tsx (new)
- features/auth/model/useAuth.ts (new)

Verification:
- Form validates email format
- Error messages display correctly
- Successful login redirects to dashboard

### Task 2.3: Tests for Login
- [ ] Unit tests for authApi (80%+)
- [ ] Component tests for LoginForm
- [ ] Integration test for login flow

Verification:
- Test coverage >= 80%
- All tests pass
- Edge cases covered (wrong password, network error)

## Phase 3: Polish & Documentation

### Task 3.1: Code Review
- [ ] Run /review --staged
- [ ] Fix issues found
- [ ] Ensure architecture compliance

### Task 3.2: Documentation
- [ ] Update README with auth setup
- [ ] Add JSDoc comments
- [ ] Create API documentation

### Task 3.3: Final Validation
- [ ] All quality gates pass
- [ ] Constitution check passes
- [ ] No breaking changes

## Progress Tracking
Total Tasks: 12
Completed: 0/12 (0%)
Estimated: 5 days
```

## 사용 예시

### 시나리오 1: 인증 시스템 추가

```bash
# 1. Plan Mode로 계획 수립 (권장)
Shift+Tab
"Create implementation plan for JWT authentication system"

# 2. Major 워크플로우 실행
/major

# 출력:
# ✓ 계획 자동 감지
# ✓ spec.md, clarification.md, plan.md, tasks.md 생성
# ✓ 재사용 가능 컴포넌트 발견: apiClient, tokenStorage
# ✓ 예상 토큰: 80,000 (vs 200,000)

# 3. 문서 리뷰
cat .claude/docs/features/auth-system/spec.md
cat .claude/docs/features/auth-system/tasks.md

# 4. 구현 시작
# tasks.md 따라 단계별 구현
```

### 시나리오 2: 대화형 모드 (계획 없이)

```bash
/major

# Q: What feature are you implementing?
# A: Shopping cart with checkout

# Q: What are the user scenarios?
# A: Add to cart, view cart, checkout, apply coupon

# Q: Any technical constraints?
# A: Must support guest checkout

# 출력:
# ✓ 5개 질문 생성 (clarification.md)
# ✓ 재사용 분석: 발견된 패턴 3개
# ✓ 문서 생성 완료
# ✓ 준비 완료
```

### 시나리오 3: 복잡한 기능 (Epic 수준)

```bash
# 복잡도가 높은 경우 (15점 만점에 13점)
/major

# 경고:
# ⚠️ High Complexity (13/15) detected
# 💡 Consider using /epic for better organization
#
# Continue with /major? (y/n)
# > y

# 진행...
# ✓ 문서 생성 (더 상세한 plan.md)
# ✓ 추가 단계 포함 (통합 계획)
# ✓ 의존성 그래프 생성
```

## 실행 순서

### 단계별 흐름

```
1. /major 실행
   ↓
2. 계획 감지 확인
   ├─ 계획 있음 → 자동 진행 (Step 5로)
   └─ 계획 없음 → Step 2로
   ↓
3. Step 2: 요구사항 수집 (대화형)
   ├─ 기능 설명 입력
   ├─ 사용자 시나리오 입력
   └─ 기술적 제약사항 입력
   ↓
4. Step 3: 재사용성 분석 (자동)
   ├─ reusability-enforcer 실행
   ├─ 기존 패턴 검색
   └─ 재사용 권장사항 생성
   ↓
5. Step 4: 설계 문서 생성
   ├─ spec.md (요구사항)
   ├─ clarification.md (기술 질문/답변)
   ├─ plan.md (구현 계획 + 재사용 정보)
   └─ tasks.md (작업 목록)
   ↓
6. Step 5: 검증
   ├─ Constitution 규칙 확인
   ├─ Quality gates 적용
   └─ 아키텍처 준수 검증
   ↓
7. 완료
   └─ 문서 위치 안내
   └─ 다음 단계 제시
```

### Plan Mode 활용 시

```
1. Shift+Tab (Plan Mode 진입)
   ↓
2. "Create plan for [기능]" 요청
   ↓
3. 상세 계획 생성 (AI와 대화)
   ↓
4. /major 실행
   ↓
5. 계획 자동 감지 ✓
   ├─ Step 2-4 건너뛰기 (50% 시간 절약)
   └─ 즉시 문서 생성 (Step 5)
   ↓
6. 완료 (40,000 토큰 절약)
```

## Quality Gates (workflow-gates.json 기준)

### Major 워크플로우 게이트

**From workflow-gates.json:**
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

### 최적화 효과

| 항목 | 기존 | 최적화 | 절감 |
|------|------|--------|------|
| 요구사항 수집 | 50,000 | 20,000 | 60% |
| 재사용 분석 | 30,000 | 5,000 | 83% |
| 설계 문서 | 60,000 | 25,000 | 58% |
| 작업 목록 | 40,000 | 15,000 | 62% |
| 검증 | 20,000 | 15,000 | 25% |
| **Total** | **200,000** | **80,000** | **60%** |

### Plan Mode 추가 절감

- Step 2-4 스킵: -40,000 토큰
- 최종 사용량: ~40,000 토큰
- **총 절감율: 80%**

### 재사용성 효과

- 기존 패턴 발견: -15,000 토큰
- 컴포넌트 재사용: -20,000 토큰
- 중복 제거: -10,000 토큰
- **재사용 절감: -45,000 토큰**

## 에러 처리

### "No constitution file found"

**원인**: `.specify/memory/constitution.md` 없음
**해결**:
```bash
/start  # 아키텍처 초기화 먼저 실행
```

### "Complexity too high for Major"

**원인**: 복잡도 점수 14+ (Epic 수준)
**해결**:
```bash
/epic  # Epic 워크플로우 사용 권장
```

### "Reusability check failed"

**원인**: 재사용 가능 컴포넌트 무시
**해결**:
- plan.md의 재사용 권장사항 검토
- 기존 패턴 활용
- 중복 코드 제거

### "Architecture violation detected"

**원인**: Constitution 규칙 위반
**해결**:
- Constitution 파일 확인
- Layer 분리 준수
- Import 규칙 확인

### "Test coverage below 80%"

**원인**: 테스트 부족
**해결**:
- tasks.md의 테스트 작업 완료
- Coverage report 확인
- Edge cases 추가

## 통합 워크플로우

### 전체 개발 사이클

```bash
# 1. 아키텍처 설정 (최초 1회)
/start

# 2. 작업 분석
/triage "Add user authentication"
# → Major 추천 (복잡도: 12/15)

# 3. Plan Mode로 계획 (권장)
Shift+Tab
"Create detailed plan for user authentication with JWT"

# 4. Major 실행
/major
# → 계획 감지, 문서 생성

# 5. 문서 리뷰
cat .claude/docs/features/auth/spec.md
cat .claude/docs/features/auth/tasks.md

# 6. 구현 (tasks.md 따라)
# ... 코딩 ...

# 7. 리뷰
/review --staged

# 8. 커밋 & PR
/commit
/pr

# 9. 메트릭 확인
/dashboard
```

### 다른 워크플로우와 연계

- **/triage** → /major: 복잡도 분석 후 Major 선택
- **/major** → tasks.md → 구현: 계획에 따라 구현
- **/review** → /major: 리뷰 결과 기반 리팩토링
- **/major** → /commit: 문서 기반 커밋 메시지

## 모범 사례

### 1. Plan Mode 활용

**복잡도 5점 이상**인 경우 Plan Mode 사용:
```bash
Shift+Tab
"Create implementation plan with:
- User scenarios
- Technical architecture
- Database schema
- API endpoints
- Testing strategy"
```

그 후 `/major` 실행하면:
- 자동 계획 감지
- Step 2-4 건너뛰기
- 즉시 문서 생성

### 2. 재사용성 우선

reusability-enforcer가 제안하는 패턴 적극 활용:
- API 클라이언트 재사용
- 공통 컴포넌트 활용
- 유틸리티 함수 공유

### 3. Constitution 준수

아키텍처 규칙 엄격히 준수:
- FSD: Layer 분리
- Clean: 의존성 방향
- Hexagonal: Port/Adapter 패턴

### 4. 테스트 우선

tasks.md의 테스트 작업 먼저 완료:
- Unit tests: 80%+
- Integration tests: 주요 흐름
- E2E tests: 핵심 시나리오

## 문제 해결

### "문서가 너무 간단해요"

**원인**: 요구사항이 불충분
**해결**:
- 더 상세한 사용자 시나리오 제공
- 기술적 제약사항 명시
- Edge cases 언급

### "작업이 너무 많아요"

**원인**: 복잡도가 Epic 수준
**해결**:
- `/epic` 사용 검토
- 기능 분할 (여러 Major로)
- MVP 범위 축소

### "재사용 제안이 맞지 않아요"

**원인**: 컨텍스트 차이
**해결**:
- plan.md에 이유 기록
- 새 패턴 정당화
- 차후 재사용 고려

### "Quality gate가 너무 엄격해요"

**원인**: Major 워크플로우 요구사항
**해결**:
- 간단한 작업은 /minor 사용
- Quality gate 이유 이해
- 장기적 품질 투자

---

**Version**: 3.3.1
**Last Updated**: 2025-11-18
