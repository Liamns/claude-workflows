# Major 워크플로우 - 문제 해결

## 목차

1. [일반적인 오류](#일반적인-오류)
2. [디렉토리 및 브랜치 문제](#디렉토리-및-브랜치-문제)
3. [아키텍처 위반](#아키텍처-위반)
4. [Quality Gate 실패](#quality-gate-실패)
5. [재사용성 검증 실패](#재사용성-검증-실패)
6. [Epic 통합 문제](#epic-통합-문제)
7. [문서 생성 문제](#문서-생성-문제)
8. [성능 및 토큰 문제](#성능-및-토큰-문제)

---

## 일반적인 오류

### 오류 1: Git 저장소 미초기화

**증상:**
```
✗ Git 저장소가 초기화되지 않았습니다
✗ Major 워크플로우를 실행할 수 없습니다
```

**원인:**
- 프로젝트 디렉토리가 Git 저장소가 아님

**해결:**
```bash
# Git 저장소 초기화
git init

# 원격 저장소 연결 (필요시)
git remote add origin <repository-url>

# 다시 실행
/major
```

---

### 오류 2: 아키텍처 미설정

**증상:**
```
✗ .specify/config/architecture.json 파일이 없습니다
✗ 아키텍처를 먼저 설정하세요
```

**원인:**
- `/start` 명령어를 실행하지 않음
- 아키텍처 설정 파일 누락

**해결:**
```bash
# 아키텍처 설정 실행
/start

# 프롬프트에 따라 아키텍처 선택
# - Custom FSD (Frontend)
# - Clean Architecture (Backend)
# - Hexagonal (Backend)

# 설정 후 다시 실행
/major
```

---

### 오류 3: Constitution 파일 누락

**증상:**
```
⚠️  .specify/memory/constitution.md 파일이 없습니다
⚠️  아키텍처 검증을 건너뜁니다
```

**원인:**
- Constitution 파일이 생성되지 않음
- 아키텍처 설정 불완전

**해결:**
```bash
# Constitution 파일 확인
cat .specify/memory/constitution.md

# 파일이 없으면 /start 재실행
/start

# 또는 수동 생성
mkdir -p .specify/memory
# Constitution 템플릿 작성
```

---

## 디렉토리 및 브랜치 문제

### 문제 1: 잘못된 디렉토리 경로

**잘못된 경로:**
```
✗ .claude/docs/features/auth-system/
✗ .claude/plans/auth-system/
✗ docs/specs/auth-system/
```

**올바른 경로:**
```
✓ .specify/features/010-auth-system/
```

**Major 워크플로우가 생성하는 경로:**
1. 사용자로부터 기능 설명 입력 받음
2. 다음 spec ID 계산 (예: 010)
3. kebab-case로 이름 변환 (예: auth-system)
4. `.specify/features/010-auth-system/` 디렉토리 생성
5. `010-auth-system` 브랜치 생성 및 체크아웃

**확인 방법:**
```bash
# Spec 디렉토리 확인
ls -la .specify/features/

# 출력 예시:
# drwxr-xr-x  010-auth-system
# drwxr-xr-x  011-payment-integration
# drwxr-xr-x  012-user-profile

# 현재 브랜치 확인
git branch --show-current
# 출력: 010-auth-system
```

---

### 문제 2: 브랜치 생성 실패

**증상:**
```
✗ 브랜치 010-auth-system 생성 실패
fatal: A branch named '010-auth-system' already exists
```

**원인:**
- 이미 동일한 이름의 브랜치가 존재

**해결 방법 1: 기존 브랜치 사용**
```bash
# 기존 브랜치로 체크아웃
git checkout 010-auth-system

# 기존 spec 디렉토리 확인
ls .specify/features/010-auth-system/

# 기존 작업이 있다면 계속 진행
# 새로 시작하려면 해결 방법 2 참고
```

**해결 방법 2: 브랜치 삭제 후 재생성**
```bash
# 현재 브랜치 확인
git branch --show-current

# main 브랜치로 이동
git checkout main

# 기존 브랜치 삭제
git branch -D 010-auth-system

# spec 디렉토리도 삭제 (주의!)
rm -rf .specify/features/010-auth-system/

# Major 재실행
/major
```

**해결 방법 3: 새 번호로 시작**
```bash
# 다음 번호로 새 spec 생성
# Major가 자동으로 011번 할당
/major
```

---

### 문제 3: Spec ID 충돌

**증상:**
```
⚠️  .specify/features/010-auth-system/ 디렉토리가 이미 존재합니다
```

**원인:**
- 이전에 같은 ID로 spec 생성했지만 브랜치는 삭제됨
- 또는 수동으로 디렉토리만 생성함

**해결:**
```bash
# 기존 디렉토리 내용 확인
ls -la .specify/features/010-auth-system/

# 내용이 있고 유지하려면
git checkout -b 010-auth-system  # 브랜치 재생성
# 기존 문서 확인 후 계속 작업

# 내용을 버리려면
rm -rf .specify/features/010-auth-system/
/major  # 재실행
```

---

## 아키텍처 위반

### 위반 1: Standard FSD 구조 사용

**잘못된 구조 (Standard FSD):**
```typescript
// ❌ Standard FSD - 우리는 사용하지 않음
features/
├── create-order/           // 액션 단위
│   ├── ui/
│   │   └── CreateOrderButton.tsx
│   └── model/
│       └── useCreateOrder.ts
├── update-order/
│   └── ui/UpdateOrderButton.tsx
└── calculate-freight/
    └── ui/FreightCalculator.tsx
```

**오류 메시지:**
```
✗ Architecture violation detected
✗ Standard FSD detected: features/create-order/
✗ Expected: Custom FSD (Domain-centric)
```

**올바른 구조 (Custom FSD):**
```typescript
// ✅ Custom FSD - Domain-centric
features/order/             // 도메인 단위
├── api/
│   ├── createOrder.ts
│   ├── updateOrder.ts
│   └── calculateFreight.ts
├── model/
│   ├── types.ts
│   ├── useOrderCreate.ts
│   ├── useOrderUpdate.ts
│   └── orderValidation.ts  // 도메인 내 공유 로직
├── lib/
│   └── orderUtils.ts
└── ui/
    ├── OrderCreateForm.tsx
    ├── OrderUpdateForm.tsx
    └── FreightCalculator.tsx
```

**수정 방법:**
```bash
# 1. 액션별 디렉토리를 도메인 디렉토리로 병합
mkdir -p features/order/{api,model,lib,ui}

# 2. 파일 이동
mv features/create-order/model/useCreateOrder.ts features/order/model/
mv features/update-order/model/useUpdateOrder.ts features/order/model/
mv features/create-order/ui/*.tsx features/order/ui/

# 3. 기존 디렉토리 삭제
rm -rf features/create-order features/update-order

# 4. 공유 로직 통합
# orderValidation.ts에 모든 주문 관련 검증 로직 통합
```

---

### 위반 2: Widgets 레이어 사용

**잘못된 구조:**
```typescript
// ❌ Widgets 레이어 (Custom FSD에서 제거됨)
widgets/
├── order-summary/
│   └── OrderSummaryWidget.tsx
└── user-dashboard/
    └── DashboardWidget.tsx
```

**오류 메시지:**
```
✗ Architecture violation: widgets/ layer detected
✗ Custom FSD removes widgets layer
✗ Move to features/ or pages/
```

**올바른 구조:**
```typescript
// ✅ Widgets는 features 또는 pages로 이동

// 옵션 1: 도메인 Feature로 이동
features/order/
└── ui/
    └── OrderSummary.tsx  // Widget → Component

// 옵션 2: Page-specific이면 pages로
pages/dashboard/
└── ui/
    └── DashboardSummary.tsx
```

**수정 방법:**
```bash
# 1. Widget이 특정 도메인에 속하면 features로
mv widgets/order-summary/OrderSummaryWidget.tsx \
   features/order/ui/OrderSummary.tsx

# 2. Widget이 특정 페이지에만 사용되면 pages로
mv widgets/user-dashboard/DashboardWidget.tsx \
   pages/dashboard/ui/DashboardSummary.tsx

# 3. widgets 디렉토리 삭제
rm -rf widgets/
```

---

### 위반 3: Features 간 비즈니스 로직 import

**잘못된 코드:**
```typescript
// ❌ features/cart/model/useCart.ts
import { calculateTotal } from '@/features/order/model/orderUtils'
//                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// Business logic import 금지

export function useCart() {
  const total = calculateTotal(items)  // 위반!
}
```

**오류 메시지:**
```
✗ Architecture violation in features/cart/model/useCart.ts
✗ Business logic import from another feature detected
✗ Only type-only imports allowed between features
```

**올바른 코드:**

**옵션 1: Type-only import**
```typescript
// ✅ features/cart/model/useCart.ts
import type { OrderTotal } from '@/features/order/model/types'
//     ^^^^
// Type-only import는 허용

export function useCart(): OrderTotal {
  // 자체 계산 로직 구현
  const total = items.reduce((sum, item) => sum + item.price, 0)
  return { total }
}
```

**옵션 2: 공유 로직을 shared로 이동**
```typescript
// 1. shared/lib/calculations.ts 생성
export function calculateTotal(items: CartItem[]): number {
  return items.reduce((sum, item) => sum + item.price, 0)
}

// 2. ✅ features/cart/model/useCart.ts
import { calculateTotal } from '@/shared/lib/calculations'
//                              ^^^^^^^^^^^
// shared에서 import는 허용

export function useCart() {
  const total = calculateTotal(items)  // OK!
}

// 3. ✅ features/order/model/useOrder.ts
import { calculateTotal } from '@/shared/lib/calculations'

export function useOrder() {
  const total = calculateTotal(items)  // OK!
}
```

---

## Quality Gate 실패

### 실패 1: 테스트 커버리지 부족

**오류 메시지:**
```
✗ Test coverage: 65%
✗ Required: 80%
✗ Quality gate failed: minTestCoverage
```

**원인:**
- tasks.md의 테스트 작업 미완료
- 테스트 작성 누락

**해결:**

**1단계: 커버리지 확인**
```bash
# 테스트 실행 및 커버리지 확인
yarn test --coverage

# 출력 예시:
# File                 | % Stmts | % Branch | % Funcs | % Lines |
# features/auth/       |   65.23 |    58.33 |   70.00 |   64.52 |
#   api/login.ts       |   45.45 |    33.33 |   50.00 |   45.45 |
#   model/useAuth.ts   |   80.00 |    75.00 |   85.71 |   80.00 |
```

**2단계: 누락된 테스트 식별**
```bash
# tasks.md에서 테스트 작업 확인
cat .specify/features/010-auth-system/tasks.md | grep -A5 "테스트"

# 예시:
# - [ ] Task 1.3: Login API 테스트 작성
# - [ ] Task 2.2: useAuth 훅 테스트
```

**3단계: 테스트 작성**
```typescript
// features/auth/api/__tests__/login.test.ts
import { describe, it, expect } from 'vitest'
import { login } from '../login'

describe('login', () => {
  it('should return token on success', async () => {
    const result = await login('user@example.com', 'password')
    expect(result.token).toBeDefined()
  })

  it('should throw error on invalid credentials', async () => {
    await expect(
      login('invalid@example.com', 'wrong')
    ).rejects.toThrow('Invalid credentials')
  })

  it('should handle network errors', async () => {
    // 네트워크 에러 시뮬레이션
    await expect(login('', '')).rejects.toThrow()
  })
})
```

**4단계: 커버리지 재확인**
```bash
yarn test --coverage

# 목표: 80% 이상
```

---

### 실패 2: Constitution 위반

**오류 메시지:**
```
✗ Constitution check failed
✗ Violation: features/auth/widgets/LoginWidget.tsx
✗ Custom FSD does not allow widgets/ layer
```

**원인:**
- Constitution에 정의된 아키텍처 규칙 위반

**해결:**

**1단계: Constitution 확인**
```bash
# Constitution 규칙 확인
cat .specify/memory/constitution.md | grep -A10 "Custom FSD"

# 예시 출력:
# - Widgets 레이어 제거
# - Domain-centric 구조
# - Type-only imports between features
```

**2단계: 위반 수정**
```bash
# 위반 파일 이동
mv features/auth/widgets/LoginWidget.tsx \
   features/auth/ui/LoginForm.tsx

# widgets 디렉토리 삭제
rm -rf features/auth/widgets
```

**3단계: 재검증**
```bash
# Constitution 검증 재실행
/review --staged

# 또는 tasks.md의 검증 단계 재실행
```

---

### 실패 3: Breaking Changes 감지

**오류 메시지:**
```
✗ Breaking change detected
✗ Public API modified: features/auth/index.ts
✗ Removed export: loginUser
```

**원인:**
- 기존 public API에서 export 제거
- 함수 시그니처 변경

**해결:**

**옵션 1: Deprecated 마킹 (권장)**
```typescript
// ✅ features/auth/index.ts
// 기존 API 유지하되 deprecated 마킹
/**
 * @deprecated Use login() instead
 */
export const loginUser = login

// 새 API
export { login } from './api/login'
```

**옵션 2: Migration Guide 제공**
```typescript
// features/auth/MIGRATION.md
# Migration Guide: v1 → v2

## Breaking Changes

### loginUser → login

**Before:**
```typescript
import { loginUser } from '@/features/auth'
const result = await loginUser(email, password)
```

**After:**
```typescript
import { login } from '@/features/auth'
const result = await login(email, password)
```
```

**옵션 3: Major 버전 업 (신중히)**
```bash
# package.json
# "version": "1.2.3" → "2.0.0"

# Breaking change를 명시적으로 허용
git commit -m "feat!: redesign auth API

BREAKING CHANGE: loginUser renamed to login"
```

---

## 재사용성 검증 실패

### 실패 1: 중복 코드 발견

**오류 메시지:**
```
✗ Reusability check failed
✗ Duplicate pattern detected:
    src/features/auth/lib/apiClient.ts
    src/shared/lib/api/apiClient.ts
✗ Reuse existing implementation
```

**원인:**
- 기존 구현을 재사용하지 않고 새로 작성

**해결:**

**1단계: 기존 구현 확인**
```bash
# 기존 API 클라이언트 확인
cat src/shared/lib/api/apiClient.ts
```

**2단계: 중복 코드 제거**
```typescript
// ❌ features/auth/lib/apiClient.ts (삭제)
export function apiClient() {
  // 중복 구현
}

// ✅ features/auth/api/login.ts
import { apiClient } from '@/shared/lib/api/apiClient'
//                        ^^^^^^^^^^^^^^^
// 기존 구현 재사용

export async function login(email: string, password: string) {
  return apiClient.post('/auth/login', { email, password })
}
```

**3단계: 중복 파일 삭제**
```bash
# 중복 파일 삭제
rm src/features/auth/lib/apiClient.ts

# Git에서도 삭제
git rm src/features/auth/lib/apiClient.ts
```

---

### 실패 2: Plan.md 재사용 권장사항 무시

**오류 메시지:**
```
✗ Reusability enforcement failed
✗ plan.md recommended reusing tokenStorage
✗ But new implementation created: features/auth/lib/storage.ts
```

**원인:**
- plan.md의 재사용 권장사항을 따르지 않음

**해결:**

**1단계: plan.md 재사용 권장사항 확인**
```bash
cat .specify/features/010-auth-system/plan.md | grep -A10 "재사용"

# 출력:
# ## Reusability Analysis
# - src/shared/lib/storage/tokenStorage.ts: 토큰 저장
# - 권장: 새로 만들지 말고 재사용할 것
```

**2단계: 새 구현 제거 및 기존 것 사용**
```typescript
// ❌ 삭제: features/auth/lib/storage.ts
export function saveToken(token: string) {
  localStorage.setItem('token', token)
}

// ✅ 사용: features/auth/api/login.ts
import { tokenStorage } from '@/shared/lib/storage/tokenStorage'
//                           ^^^^^^^^^^^
// plan.md 권장사항 따름

export async function login(email: string, password: string) {
  const { token } = await apiClient.post('/auth/login', { email, password })
  tokenStorage.save(token)  // 기존 구현 재사용
  return token
}
```

---

## Epic 통합 문제

### 문제 1: Epic 브랜치 외부에서 Feature 생성

**증상:**
```
⚠️  현재 브랜치: 011-user-profile
⚠️  예상 브랜치: 009-ecommerce-platform (Epic)
⚠️  Epic의 Feature는 Epic 브랜치 내에서 작업해야 합니다
```

**원인:**
- Epic 외부에서 `/major` 실행
- Epic 브랜치로 체크아웃하지 않음

**해결:**
```bash
# 1. Epic 브랜치로 체크아웃
git checkout 009-ecommerce-platform

# 2. 현재 브랜치 확인
git branch --show-current
# 출력: 009-ecommerce-platform

# 3. Major 실행
/major "사용자 인증"
# → .specify/features/009-ecommerce-platform/features/001-auth/ 생성
```

---

### 문제 2: Epic 디렉토리 구조 혼동

**잘못된 구조:**
```
.specify/features/
├── 009-ecommerce-platform/
│   ├── epic.md
│   ├── 001-auth-system/        # ✗ 잘못됨
│   │   ├── spec.md
│   │   └── plan.md
│   └── 002-payment/            # ✗ 잘못됨
│       ├── spec.md
│       └── plan.md
```

**올바른 구조:**
```
.specify/features/
├── 009-ecommerce-platform/
│   ├── epic.md
│   ├── progress.md
│   ├── roadmap.md
│   └── features/               # ✓ features/ 디렉토리 필수
│       ├── 001-auth-system/
│       │   ├── spec.md
│       │   ├── plan.md
│       │   └── tasks.md
│       └── 002-payment/
│           ├── spec.md
│           ├── plan.md
│           └── tasks.md
```

**수정:**
```bash
# Epic 디렉토리로 이동
cd .specify/features/009-ecommerce-platform/

# features 디렉토리 생성
mkdir -p features

# 잘못 생성된 Feature 이동
mv 001-auth-system features/
mv 002-payment features/

# 구조 확인
tree -L 3
```

---

### 문제 3: Epic Feature 브랜치 분리

**잘못된 방식:**
```bash
# ✗ Feature마다 별도 브랜치 생성 (Epic에서는 안됨)
git checkout -b 009-ecommerce-platform-auth
git checkout -b 009-ecommerce-platform-payment
```

**올바른 방식:**
```bash
# ✓ 모든 Feature가 Epic 브랜치에서 작업
git checkout 009-ecommerce-platform

# Feature 1 작업
/major "인증 시스템"
# ... 구현 ...
git add .
git commit -m "feat(auth): implement authentication"

# Feature 2 작업 (같은 브랜치에서)
/major "결제 통합"
# ... 구현 ...
git add .
git commit -m "feat(payment): integrate payment gateway"

# 모든 Feature 완료 후 한 번에 PR
git push origin 009-ecommerce-platform
```

---

## 문서 생성 문제

### 문제 1: 문서 템플릿 누락

**증상:**
```
✗ Failed to generate spec.md
✗ Template not found: .claude/templates/spec.md
```

**원인:**
- 템플릿 파일 누락 또는 손상

**해결:**
```bash
# 1. 템플릿 디렉토리 확인
ls -la .claude/templates/

# 2. Git에서 복구
git checkout HEAD -- .claude/templates/

# 3. 또는 최신 버전으로 업데이트
git pull origin main

# 4. Major 재실행
/major
```

---

### 문제 2: 생성된 문서가 비어있음

**증상:**
```bash
cat .specify/features/010-auth-system/spec.md
# (빈 파일 또는 헤더만 있음)
```

**원인:**
- 요구사항 수집 단계에서 충분한 정보 제공 안함
- 대화형 Q&A에서 모두 스킵

**해결:**

**재실행 시 상세 정보 제공:**
```
구현할 기능이 무엇인가요?
> 사용자 인증 시스템 - 이메일/비밀번호 로그인, JWT 토큰 기반

사용자 시나리오는 무엇인가요?
> 1. 사용자가 이메일/비밀번호로 로그인
> 2. 서버가 JWT 토큰 발급
> 3. 토큰을 로컬스토리지에 저장
> 4. 이후 요청에 토큰 포함
> 5. 로그아웃 시 토큰 삭제
> [Enter]

기술적 제약사항이 있나요?
> - JWT 만료 시간: 24시간
> - Refresh token 사용
> - HTTPS 필수
> - Password: bcrypt 해싱
> [Enter]
```

**결과: 풍부한 spec.md 생성**

---

### 문제 3: tasks.md 작업 순서 잘못됨

**증상:**
```markdown
## Phase 1: 구현
- Task 1.1: 로그인 UI 구현
- Task 1.2: 로그인 API 구현  ← 의존성 문제

## Phase 2: 테스트
- Task 2.1: API 테스트
- Task 2.2: UI 테스트
```

**문제:**
- UI가 API에 의존하는데 UI 먼저 구현하도록 되어있음

**수정:**
```markdown
## Phase 1: Backend
- Task 1.1: 로그인 API 구현
- Task 1.2: 로그인 API 테스트

## Phase 2: Frontend
- Task 2.1: 로그인 UI 구현
- Task 2.2: 로그인 UI 테스트

## Phase 3: 통합
- Task 3.1: E2E 테스트
```

**재생성 방법:**
```bash
# 1. tasks.md 백업
cp .specify/features/010-auth-system/tasks.md tasks.md.bak

# 2. tasks.md 재생성 요청
# Major 워크플로우 내에서 "작업 분해" 단계 재실행

# 3. 의존성 명확히 명시
"Task 1.2는 Task 1.1에 의존합니다"
```

---

## 성능 및 토큰 문제

### 문제 1: 높은 토큰 사용량

**증상:**
```
⚠️  예상 토큰: 180,000
⚠️  목표 절감: 60% (목표: 72,000)
⚠️  실제 절감: 10%
```

**원인:**
- 재사용성 분석 미활용
- 중복 코드 작성
- 대규모 파일 반복 읽기

**해결:**

**1단계: 재사용성 권장사항 따르기**
```bash
# plan.md의 재사용 권장사항 확인
cat .specify/features/010-auth-system/plan.md | grep -A20 "Reusability"

# 권장사항:
# - apiClient 재사용 → -15,000 토큰
# - tokenStorage 재사용 → -8,000 토큰
# - formValidation 재사용 → -12,000 토큰
```

**2단계: Smart-Cache 활용**
```bash
# 캐시 상태 확인
ls -la .claude/cache/

# 캐시 히트율 확인
cat .claude/cache/stats.json

# 목표: 70% 이상 캐시 히트율
```

**3단계: 불필요한 파일 읽기 제거**
```bash
# 실제 필요한 파일만 읽기
# ✗ 전체 codebase 읽기
# ✓ plan.md에 명시된 파일만 읽기
```

---

### 문제 2: 느린 재사용성 분석

**증상:**
```
⏳ 재사용성 분석 중...
⏳ (5분 경과)
⏳ (10분 경과)
```

**원인:**
- 대규모 codebase
- 인덱싱 미사용
- 병렬 처리 비활성화

**해결:**

**옵션 1: 분석 범위 제한**
```bash
# .claude/config/reusability.json
{
  "searchPaths": [
    "src/features",
    "src/shared"
  ],
  "excludePaths": [
    "node_modules",
    "dist",
    "build",
    ".next"
  ],
  "maxFiles": 500
}
```

**옵션 2: 캐시 사용**
```bash
# 재사용성 분석 결과 캐싱 활성화
# .claude/config/smart-cache.json
{
  "reusability": {
    "enabled": true,
    "ttl": 3600  // 1시간
  }
}
```

---

### 문제 3: 메모리 부족

**증상:**
```
✗ Failed to generate documents
✗ JavaScript heap out of memory
```

**원인:**
- 한 번에 너무 많은 파일 처리
- 메모리 제한 낮음

**해결:**

**Node.js 메모리 증가:**
```bash
# package.json
{
  "scripts": {
    "claude": "NODE_OPTIONS='--max-old-space-size=4096' claude-code"
  }
}
```

**Phase별 처리:**
```bash
# 전체를 한 번에 하지 말고 Phase별로 나눔

# Phase 1만 먼저
/major
# → spec.md, plan.md만 생성

# Phase 2
# → tasks.md 생성

# Phase 3
# → research.md, data-model.md 생성
```

---

## 디버깅 팁

### 로그 확인

```bash
# Major 워크플로우 로그
cat .claude/logs/major-$(date +%Y%m%d).log

# 에러 로그만 필터
grep "ERROR" .claude/logs/major-*.log

# 최근 10개 오류
tail -n 100 .claude/logs/major-*.log | grep "ERROR"
```

### 상세 모드 실행

```bash
# 디버그 모드로 Major 실행
DEBUG=true /major

# 또는 환경 변수 설정
export CLAUDE_DEBUG=1
/major
```

### Git 상태 확인

```bash
# 현재 상태 전체 확인
git status
git branch --show-current
git log --oneline -5

# Spec 디렉토리 구조
tree .specify/features/ -L 3

# 브랜치 목록
git branch -a
```

### Constitution 검증

```bash
# Constitution 규칙 확인
cat .specify/memory/constitution.md

# 아키텍처 설정 확인
cat .specify/config/architecture.json

# Quality gates 확인
cat .claude/workflow-gates.json | jq '.major'
```

---

## 추가 도움말

### 관련 문서

- [major.md](../major.md) - Major 워크플로우 메인 문서
- [major-examples.md](major-examples.md) - 사용 예시
- [major-document-templates.md](major-document-templates.md) - 문서 템플릿

### 커뮤니티 지원

- GitHub Issues: https://github.com/your-repo/issues
- 문서: https://docs.your-project.com
- FAQ: https://docs.your-project.com/faq

---

**Version**: 3.3.2
**Last Updated**: 2025-11-18
