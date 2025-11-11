# FSD 레이어 규칙 (Team Custom: Domain-Centric)

Feature-Sliced Design 아키텍처의 레이어별 상세 규칙입니다.

**팀 철학**: "One feature = one domain (like a backend service)"

## 레이어 계층 구조 (Team Custom)

```
┌─────────────┐
│   Pages     │  라우트 핸들링, 페이지 특화 로직 (v2.1 Pages First)
├─────────────┤
│  Features   │  도메인 중심 사용자 인터랙션 (Domain-Centric)
├─────────────┤
│  Entities   │  순수 도메인 모델 (Optional)
├─────────────┤
│   Shared    │  범용 유틸리티 (도메인 지식 없음)
└─────────────┘

Type-only: Features ⇄ Features (import type only)
```

**의존성 방향**:
- 기본: Pages → Features → Entities (optional) → Shared
- 예외: Features ⇄ Features (type-only imports)

**제거된 레이어**:
- ~~Widgets~~: Team Custom에서 제거 (features/pages로 병합)
- ~~Processes~~: FSD v2에서 deprecated

## 1. Shared Layer

**목적**: 재사용 가능한 UI 컴포넌트 및 유틸리티

**허용**:
- ✅ 재사용 UI 컴포넌트 (Button, Input, Modal)
- ✅ 이벤트 핸들러 props
- ✅ 스타일 props
- ✅ 범용 유틸리티 함수
- ✅ API 기본 설정 (httpClient)

**금지**:
- ❌ 비즈니스 로직
- ❌ 도메인 특화 로직
- ❌ 상위 레이어 import

**예시**:
```typescript
// shared/ui/Button.tsx
interface ButtonProps {
  onClick: () => void;  // ✅ 이벤트 핸들러 허용
  variant?: 'primary' | 'secondary';  // ✅ 스타일 props 허용
  children: React.ReactNode;
}

export function Button({ onClick, variant = 'primary', children }: ButtonProps) {
  return (
    <button className={variant} onClick={onClick}>
      {children}
    </button>
  );
}
```

## 2. Entities Layer

**목적**: 비즈니스 엔티티의 순수한 표현

**허용**:
- ✅ 순수 함수 (포맷팅, 변환)
- ✅ 타입 정의
- ✅ Zod 스키마
- ✅ 순수 프레젠테이션 컴포넌트
- ✅ 도메인 데이터 props

**금지**:
- ❌ useState, useEffect, useRef 등 React 훅
- ❌ API 호출
- ❌ 전역 상태 관리 (Zustand, Context)
- ❌ 이벤트 핸들러 props
- ❌ 비즈니스 로직

**순수성 체크리스트**:
- [ ] 컴포넌트는 props만 받아서 UI 표시
- [ ] 상태 관리 없음 (no useState)
- [ ] 부수 효과 없음 (no useEffect)
- [ ] API 호출 없음
- [ ] 같은 props = 같은 출력 (멱등성)

**예시**:
```typescript
// entities/vehicle/model/types.ts
export interface Vehicle {
  id: string;
  type: string;
  ton: string;
  plateNumber: string;
}

// entities/vehicle/lib/format.ts
export function formatVehicleDisplay(vehicle: Vehicle): string {
  return `${vehicle.type} ${vehicle.ton} (${vehicle.plateNumber})`;
}

// entities/vehicle/ui/VehicleCard.tsx
export function VehicleCard({ data }: { data: Vehicle }) {
  return (
    <div>
      <h3>{formatVehicleDisplay(data)}</h3>
    </div>
  );
}
```

## 3. Features Layer (Team Custom: Domain-Centric)

**목적**: 도메인 중심 사용자 인터랙션 (백엔드 서비스와 유사)

**Team Principle**: One feature = one domain with multiple related actions

**허용**:
- ✅ React 훅 (useState, useEffect, custom hooks)
- ✅ 비즈니스 로직
- ✅ API 호출 (api/ 디렉토리)
- ✅ 도메인 데이터 props
- ✅ Entities import
- ✅ Type-only imports from other features (`import type { Type } from '@/features/other'`)
- ✅ Shared logic within domain (validation, schemas, types)

**금지**:
- ❌ 이벤트 핸들러 props (onSubmit, onChange 등)
- ❌ UI 설정 props (color, size, variant 등)
- ❌ Pages import (상위 레이어)
- ❌ Runtime imports from other features (type-only만 허용)

**Props 규칙**:
```typescript
// ❌ 금지
interface Props {
  onSubmit: () => void;  // 이벤트 핸들러
  onChange: (value: string) => void;  // 이벤트 핸들러
  buttonColor: string;  // UI 설정
}

// ✅ 허용
interface Props {
  userId: string;  // 도메인 데이터
  vehicleId: string;  // 도메인 데이터
  initialDate?: string;  // 도메인 데이터
}
```

**구조 (Domain-Centric)**:
```typescript
// features/order/model/types.ts (모든 order 관련 타입)
export interface OrderCreateData { /* ... */ }
export interface OrderUpdateData { /* ... */ }
export interface Order { /* ... */ }

// features/order/model/orderSchemas.ts (공유 스키마)
export const orderCreateSchema = z.object({ /* ... */ });
export const orderUpdateSchema = z.object({ /* ... */ });

// features/order/model/orderValidation.ts (공유 검증)
export function validateOrderData(data: unknown): boolean { /* ... */ }

// features/order/model/useOrderCreate.ts
export function useOrderCreate() {
  const [isLoading, setIsLoading] = useState(false);

  const handleCreate = async (data: OrderCreateData) => {
    // 비즈니스 로직
  };

  return { handleCreate, isLoading };
}

// features/order/ui/OrderCreateForm.tsx
export function OrderCreateForm({ userId }: { userId: string }) {
  const { handleCreate, isLoading } = useOrderCreate();

  return (
    <form onSubmit={(e) => { e.preventDefault(); /* ... */ }}>
      {/* UI */}
    </form>
  );
}

// features/order/api/createOrder.ts
export async function createOrder(data: OrderCreateData): Promise<Order> {
  // API 호출
}
```

**Domain Grouping Example**:
```
features/order/
├── api/
│   ├── createOrder.ts
│   ├── updateOrder.ts
│   └── cancelOrder.ts
├── model/
│   ├── types.ts              # 모든 order 관련 타입
│   ├── orderSchemas.ts        # 공유 스키마
│   ├── orderValidation.ts     # 공유 검증
│   ├── useOrderCreate.ts
│   ├── useOrderUpdate.ts
│   └── useOrderCancel.ts
└── ui/
    ├── OrderCreateForm.tsx
    ├── OrderUpdateForm.tsx
    └── OrderCancelButton.tsx
```

## 4. Pages Layer (Team Custom: v2.1 Pages First)

**목적**: 라우트 핸들링 및 페이지 특화 로직

**Team Principle**: 페이지 특화 로직은 pages에 유지 (2+ 페이지에서 재사용되지 않으면 features로 추출하지 않음)

**허용**:
- ✅ Features import 및 조합
- ✅ Entities import 및 조합
- ✅ 라우트 파라미터 전달
- ✅ 페이지 레벨 인증 체크
- ✅ 플랫폼별 분기
- ✅ 페이지 특화 로직 (api, model, ui segments)
- ✅ 페이지 내부에서만 사용되는 컴포넌트

**금지**:
- ❌ 불필요한 feature 추출 (1개 페이지에서만 사용되는 로직은 pages에 유지)

**예시**:
```typescript
// pages/order-list/ui/OrderListPage.tsx
import { Header } from '@/features/header';  // 재사용 feature
import { OrderList } from '@/features/order';  // 재사용 feature
import { useOrderListData } from '../model/useOrderListData';  // 페이지 특화 로직

export function OrderListPage() {
  const { orders, filters, setFilters } = useOrderListData();

  // 페이지 특화 로직: 필터링, 정렬 등
  // 다른 페이지에서 재사용되지 않으면 여기에 유지

  return (
    <div>
      <Header />
      {/* 필터 UI (페이지 특화) */}
      <OrderList data={orders} />
    </div>
  );
}

// pages/order-list/model/useOrderListData.ts (페이지 특화 로직)
export function useOrderListData() {
  // 이 페이지에서만 사용되는 로직
  const [filters, setFilters] = useState({});
  const [orders, setOrders] = useState([]);

  // 필터링, 정렬 로직

  return { orders, filters, setFilters };
}
```

**Pages First 판단 기준**:
- **1개 페이지에서만 사용**: pages에 유지
- **2+ 페이지에서 재사용**: features로 추출
- **페이지 특화 로직**: 인증 체크, 라우트 파라미터, 페이지별 필터 등

## 의존성 방향 검증 (Team Custom)

**허용되는 import**:
```typescript
// Pages
import { Feature } from '@/features/order';  // ✅
import { Entity } from '@/entities/vehicle';  // ✅
import { Button } from '@/shared/ui';  // ✅

// Features
import { Entity } from '@/entities/vehicle';  // ✅
import { Button } from '@/shared/ui';  // ✅
import type { OrderType } from '@/features/order';  // ✅ Type-only import from other feature

// Entities
import { formatDate } from '@/shared/lib';  // ✅
```

**금지되는 import**:
```typescript
// Entities
import { Feature } from '@/features/order';  // ❌ 상위 레이어

// Features
import { Page } from '@/pages/dashboard';  // ❌ 상위 레이어
import { OrderList } from '@/features/order';  // ❌ Runtime import from other feature (type-only만 허용)

// Shared
import { Order } from '@/entities/order';  // ❌ 상위 레이어
```

**Type-Only Import 규칙** (Team Custom 예외):
```typescript
// ✅ 허용: Feature 간 타입 참조
import type { OrderType, OrderStatus } from '@/features/order';

// ❌ 금지: Feature 간 런타임 import
import { OrderList, useOrderCreate } from '@/features/order';
```

## 레이어 규칙 검증 명령어 (Team Custom)

```bash
# Entity에서 훅 사용 검색
grep -r "useState\|useEffect" src/entities/

# Entity에서 Feature import 검색
grep -r "from.*features" src/entities/

# Feature에서 Pages import 검색 (상위 레이어)
grep -r "from.*pages" src/features/

# Feature 간 런타임 import 검색 (type-only만 허용)
grep -r "from '@/features/" src/features/ | grep -v "import type"

# Features Props에서 이벤트 핸들러 검색
grep -r "on[A-Z].*:.*=>" src/features/*/ui/*.tsx

# Shared에서 상위 레이어 import 검색
grep -r "from.*\(entities\|features\|pages\)" src/shared/

# Type-only import 규칙 검증
# Feature 간 타입 참조는 "import type" 사용해야 함
grep -r "from '@/features/" src/features/ | grep -v "import type" | grep "features"
```

## 팀 커스텀 규칙 요약

1. **Widgets 레이어 제거**: features 또는 pages로 병합
2. **Domain-Centric Features**: 하나의 feature = 하나의 도메인 (관련 액션들 그룹화)
3. **Type-Only Imports**: Feature 간 타입 참조는 `import type` 사용
4. **Pages First**: 페이지 특화 로직은 pages에 유지 (2+ 페이지 재사용 시 features로 추출)
5. **Optional Entities**: Simple projects can merge entity types into features

**참고 문서**:
- `architectures/frontend/fsd/config.json`: 팀 커스텀 FSD 설정
- `architectures/frontend/fsd/fsd-architecture.mdc`: 팀 커스텀 FSD 아키텍처 전체 문서
