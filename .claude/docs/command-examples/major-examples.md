# Major 워크플로우 - 사용 예시

> **참고**: Major 워크플로우는 `/plan-major` (계획) → `/implement` (구현) 2단계로 분리되어 있습니다.

## 예시 1: 기본 흐름

**시나리오**: 사용자 프로필 페이지 구현

### Step 1: 계획 수립
```bash
/plan-major "아바타 업로드가 가능한 사용자 프로필 페이지"
```

**출력:**
```
🚀 Major Workflow - 계획 단계
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Step 1: Spec 디렉토리 및 브랜치 생성
✓ .specify/features/011-user-profile/ 생성
✓ 브랜치 011-user-profile 생성 및 체크아웃

📋 Step 2: 요구사항 수집
✓ 요구사항 초안 작성 완료

📊 Step 3: 재사용성 분석
기존 패턴 검색 중...
✓ 발견: src/shared/lib/api/apiClient.ts
✓ 발견: src/shared/lib/validation/formValidation.ts

📝 Step 4: 문서 생성
✓ spec.md 생성 완료
✓ plan.md 생성 완료 (재사용 정보 포함)
✓ tasks.md 생성 완료 (12개 작업)

✅ 계획 완료!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

문서 위치: .specify/features/011-user-profile/
다음 단계: /implement 로 구현 시작
```

### Step 2: 구현
```bash
/implement
```

**출력:**
```
🔧 Implementation - 구현 단계
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📁 작업 디렉토리: .specify/features/011-user-profile/

📋 Tasks (12개):
[1/12] 프로필 API 타입 정의 - in_progress
[2/12] useProfile 훅 구현 - pending
...

✅ 현재 작업을 시작합니다.
```

## 예시 2: Custom FSD 아키텍처 적용

**시나리오**: 주문 관리 기능 추가

```bash
/plan-major "주문 생성, 수정, 배송비 계산 기능"
```

**생성된 구조 (Custom FSD - Domain-centric):**
```typescript
features/order/              // ✅ Domain 중심 (단일 액션이 아님)
├── api/
│   ├── createOrder.ts       // 관련 액션들을 하나의 도메인에
│   ├── updateOrder.ts
│   ├── cancelOrder.ts
│   └── calculateFreight.ts
├── model/
│   ├── types.ts             // 모든 주문 관련 타입
│   ├── useOrderCreate.ts
│   ├── useOrderUpdate.ts
│   ├── orderValidation.ts   // ✅ 도메인 내 공유 로직
│   └── orderSchemas.ts      // Zod schemas
├── lib/
│   └── orderUtils.ts        // 유틸리티 함수
├── ui/
│   ├── OrderCreateForm.tsx
│   ├── OrderUpdateForm.tsx
│   ├── OrderStatusBadge.tsx
│   └── FreightCalculator.tsx
└── index.ts                 // Public API

// ✅ Custom FSD 준수 완료:
// - Domain-centric 구조 (한 Feature = 한 도메인)
// - Widgets 레이어 제거 (features/pages로 통합)
// - 도메인 내 검증 로직 공유 가능
// - Type-only imports는 features 간 허용
```

## 예시 3: 재사용성 분석 활용

**시나리오**: 결제 시스템 통합

```bash
/plan-major "결제 시스템 통합"
```

**실행 결과:**
```
📊 Step 3: 재사용성 분석
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

기존 패턴 검색 중...
✓ 발견: src/shared/lib/api/apiClient.ts (API 클라이언트)
✓ 발견: src/shared/lib/validation/formValidation.ts (폼 검증)
✓ 발견: src/features/order/model/orderSchemas.ts (Zod 패턴)

⚡ 재사용 권장사항:
- HTTP 요청에 apiClient 재사용 (새로 만들지 마세요)
- 폼 검증은 formValidation 확장
- Zod 스키마 패턴은 orderSchemas 참고

토큰 절감: 18,000 (재사용성을 통한 절감)
```

```bash
# 계획 검토 후 구현 시작
/implement
```

## 예시 4: Epic 내부 Feature로 사용

**시나리오**: 전자상거래 플랫폼의 일부 기능

```bash
# 먼저 Epic 생성
/epic "전자상거래 플랫폼"
# → .specify/features/009-ecommerce-platform/ 생성
# → 브랜치 009-ecommerce-platform 생성

# Epic 내부에서 각 Feature를 Major로 구현
/plan-major "사용자 인증 시스템"
# → .specify/features/009-ecommerce-platform/features/001-auth-system/ 생성
# → 같은 브랜치(009-ecommerce-platform)에서 작업
/implement

/plan-major "상품 카탈로그"
# → .specify/features/009-ecommerce-platform/features/002-product-catalog/ 생성
/implement

/plan-major "장바구니"
# → .specify/features/009-ecommerce-platform/features/003-shopping-cart/ 생성
/implement
```

**생성된 구조:**
```
.specify/features/009-ecommerce-platform/
├── epic.md                 # Epic 전체 정의
├── progress.md             # 진행 상황 (자동 업데이트)
├── roadmap.md              # 로드맵
└── features/
    ├── 001-auth-system/
    │   ├── spec.md
    │   ├── plan.md
    │   ├── tasks.md
    │   └── research.md
    ├── 002-product-catalog/
    │   ├── spec.md
    │   ├── plan.md
    │   └── tasks.md
    └── 003-shopping-cart/
        ├── spec.md
        ├── plan.md
        └── tasks.md

Branch: 009-ecommerce-platform (모든 Feature가 이 브랜치에서)
```

## 예시 5: 전체 개발 사이클

**처음부터 배포까지 전체 흐름**

```bash
# 1. 아키텍처 설정 (프로젝트 최초 1회)
/start

# 2. 작업 복잡도 분석
/triage "사용자 인증 추가"
# → Major 추천됨 (복잡도: 12/15)

# 3. Major 계획 수립
/plan-major
# 출력:
# ✓ Spec 디렉토리 생성: .specify/features/010-auth-system/
# ✓ 브랜치 생성: 010-auth-system
# ✓ 문서 생성 완료

# 4. 생성된 문서 검토
cat .specify/features/010-auth-system/spec.md
cat .specify/features/010-auth-system/plan.md
cat .specify/features/010-auth-system/tasks.md

# 5. 구현 시작
/implement
# → tasks.md를 따라 순차적으로 구현

# 6. 코드 리뷰
/review --staged

# 7. 커밋 & PR 생성
/commit
/pr

# 8. 메트릭 확인
/dashboard
```

## 예시 6: 복잡한 기능 (Epic 수준)

**시나리오**: 복잡도가 매우 높은 기능

```bash
/plan-major "실시간 협업 편집 시스템"
```

**경고 메시지:**
```
⚠️ 높은 복잡도 감지 (13/15)
💡 더 나은 구조화를 위해 /epic 사용을 고려하세요

/plan-major로 계속 진행하시겠습니까? (y/n)
> y

진행 중...
✓ 더 상세한 plan.md 생성
✓ 통합 계획 포함
✓ 의존성 그래프 생성 완료
```

## 예시 7: 다른 워크플로우와 연계

**실무 통합 예시**

```bash
# 패턴 1: Triage → Plan-Major → Implement
/triage "결제 시스템 통합"
# → "이 작업은 Major 워크플로우가 적합합니다 (복잡도: 11/15)"
/plan-major
/implement

# 패턴 2: Plan-Major → Implement → Review → Commit
/plan-major "사용자 대시보드"
# ... 문서 검토 ...
/implement
# ... 코딩 ...
/review --staged
/commit

# 패턴 3: Review 결과 기반 리팩토링
/review --staged
# → "아키텍처 위반 3건 발견"
# ... 수정 ...
/plan-major   # 리팩토링 계획 재수립
/implement

# 패턴 4: Epic의 하위 Feature로 Major 사용
/epic "전자상거래 플랫폼"
# → Feature 1, 2, 3 생성
/plan-major   # 각 Feature별로 계획
/implement    # 구현
```

## 예시 8: 데이터 모델 포함

**시나리오**: 데이터베이스 스키마가 필요한 기능

```bash
/plan-major "사용자 멤버십 시스템"
```

**생성되는 문서:**
```
.specify/features/013-membership-system/
├── spec.md          # 요구사항
├── plan.md          # 구현 계획
├── tasks.md         # 작업 목록
├── research.md      # 멤버십 레벨 조사
└── data-model.md    # ✅ 데이터 모델 생성됨

data-model.md 내용:
- User 엔티티
- Membership 엔티티
- Subscription 엔티티
- ERD 다이어그램
- Prisma 스키마
```

```bash
# 문서 검토 후 구현
/implement
```

## 빠른 참조

### 기본 워크플로우
```bash
# 계획 수립
/plan-major "기능 설명"

# 문서 검토
cat .specify/features/NNN-feature-name/spec.md
cat .specify/features/NNN-feature-name/plan.md
cat .specify/features/NNN-feature-name/tasks.md

# 구현 시작
/implement
```

### 복잡도 확인 후 실행
```bash
/triage "작업 설명"
# → Major 권장 시
/plan-major
/implement
```

### Epic 내부에서 실행
```bash
# (이미 Epic 브랜치에 있는 상태)
/plan-major "Feature 설명"
/implement
```

### 토큰 절감 효과

| 시나리오 | 기존 | 최적화 | 절감 |
|---------|------|--------|------|
| 단순 기능 | 150,000 | 60,000 | 60% |
| 재사용 많음 | 200,000 | 50,000 | 75% |
| Epic Feature | 180,000 | 70,000 | 61% |

---

**참고**:
- [major-document-templates.md](major-document-templates.md) - 문서 템플릿
- [major-troubleshooting.md](major-troubleshooting.md) - 문제 해결
- [plan-major.md](../../commands/plan-major.md) - 계획 명령어
- [implement.md](../../commands/implement.md) - 구현 명령어
