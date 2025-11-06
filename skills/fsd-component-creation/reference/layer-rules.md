# FSD 레이어 규칙

Feature-Sliced Design 아키텍처의 레이어별 상세 규칙입니다.

## 레이어 계층 구조

```
┌─────────────┐
│   Pages     │  라우트 핸들링, 페이지 조합
├─────────────┤
│   Widgets   │  독립 UI 블록, Features/Entities 조합
├─────────────┤
│  Features   │  사용자 액션, 비즈니스 로직
├─────────────┤
│  Entities   │  비즈니스 엔티티, 순수 표현
├─────────────┤
│   Shared    │  재사용 UI, 유틸리티
└─────────────┘
```

**의존성 방향**: 위에서 아래로만 (Pages → Widgets → Features → Entities → Shared)

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

## 3. Features Layer

**목적**: 하나의 완결된 사용자 액션 구현

**허용**:
- ✅ React 훅 (useState, useEffect, custom hooks)
- ✅ 비즈니스 로직
- ✅ API 호출 (api/ 디렉토리)
- ✅ 도메인 데이터 props
- ✅ Entities import

**금지**:
- ❌ 이벤트 핸들러 props (onSubmit, onChange 등)
- ❌ UI 설정 props (color, size, variant 등)
- ❌ Widgets import (상위 레이어)
- ❌ Pages import (상위 레이어)

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

**구조**:
```typescript
// features/dispatch/model/useDispatchForm.ts
export function useDispatchForm() {
  const [formData, setFormData] = useState({});

  const handleSubmit = async () => {
    // 비즈니스 로직
  };

  return { formData, handleSubmit };
}

// features/dispatch/ui/DispatchForm.tsx
export function DispatchForm({ userId }: { userId: string }) {
  const { formData, handleSubmit } = useDispatchForm();

  return (
    <form onSubmit={handleSubmit}>
      {/* UI */}
    </form>
  );
}
```

## 4. Widgets Layer

**목적**: 독립적인 UI 블록, Features/Entities 조합

**허용**:
- ✅ Features import 및 조합
- ✅ Entities import 및 조합
- ✅ 최소한의 레이아웃 로직
- ✅ 도메인 데이터 props (또는 props 없음)

**금지**:
- ❌ 복잡한 비즈니스 로직 (Features로 분리)
- ❌ 직접 API 호출 (Features에서 처리)
- ❌ Pages import

**예시**:
```typescript
// widgets/header/ui/Header.tsx
import { UserMenu } from '@/features/user-menu';
import { Notifications } from '@/features/notifications';
import { Logo } from '@/entities/branding';

export function Header() {
  const user = useUserStore((state) => state.user);

  return (
    <header>
      <Logo />
      {user && (
        <>
          <Notifications userId={user.id} />
          <UserMenu user={user} />
        </>
      )}
    </header>
  );
}
```

## 5. Pages Layer

**목적**: 라우트 핸들링 및 페이지 레벨 조합

**허용**:
- ✅ Widgets import 및 조합
- ✅ Features import 및 조합
- ✅ 라우트 파라미터 전달
- ✅ 페이지 레벨 인증 체크
- ✅ 플랫폼별 분기

**금지**:
- ❌ 직접 API 호출 (Features에서 처리)
- ❌ 복잡한 비즈니스 로직 (Features로 분리)

**예시**:
```typescript
// pages/dashboard/ui/DashboardPage.tsx
import { Header } from '@/widgets/header';
import { Dashboard } from '@/widgets/dashboard';

export function DashboardPage() {
  const user = useUserStore((state) => state.user);

  if (!user) {
    return <Navigate to="/sign-in" />;
  }

  return (
    <div>
      <Header />
      <Dashboard userId={user.id} />
    </div>
  );
}
```

## 의존성 방향 검증

**허용되는 import**:
```typescript
// Pages
import { Widget } from '@/widgets/header';  // ✅
import { Feature } from '@/features/sign-up';  // ✅
import { Entity } from '@/entities/user';  // ✅
import { Button } from '@/shared/ui';  // ✅

// Widgets
import { Feature } from '@/features/sign-up';  // ✅
import { Entity } from '@/entities/user';  // ✅
import { Button } from '@/shared/ui';  // ✅

// Features
import { Entity } from '@/entities/user';  // ✅
import { Button } from '@/shared/ui';  // ✅

// Entities
import { formatDate } from '@/shared/lib';  // ✅
```

**금지되는 import**:
```typescript
// Entities
import { Feature } from '@/features/sign-up';  // ❌ 상위 레이어

// Features
import { Widget } from '@/widgets/header';  // ❌ 상위 레이어

// Widgets
import { Page } from '@/pages/dashboard';  // ❌ 상위 레이어
```

## 레이어 규칙 검증 명령어

```bash
# Entity에서 훅 사용 검색
grep -r "useState\|useEffect" src/entities/

# Entity에서 Feature import 검색
grep -r "from.*features" src/entities/

# Feature에서 Widget import 검색
grep -r "from.*widgets" src/features/

# Features Props에서 이벤트 핸들러 검색
grep -r "on[A-Z].*:.*=>" src/features/*/ui/*.tsx
```
