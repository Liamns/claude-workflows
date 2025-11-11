# Widget 템플릿

Widget은 Features와 Entities를 조합하여 독립적인 UI 블록을 만듭니다.

## 파일 구조

```
widgets/{widget-name}/
├── config/
│   └── constants.ts    # (선택) 상수
└── ui/
    └── {Widget}.tsx    # 메인 컴포넌트
```

## ui/{Widget}.tsx

```typescript
// Features와 Entities import
import { {Feature}Form } from '@/features/{feature}';
import { {Entity}Card } from '@/entities/{entity}';

interface Props {
  // ✅ 도메인 데이터만 (또는 props 없음)
  userId?: string;
}

export function {Widget}({ userId }: Props) {
  // 최소한의 로직만
  // 복잡한 로직은 Features로 분리

  return (
    <div>
      <header>
        {/* 헤더 */}
      </header>

      <main>
        {/* Features/Entities 조합 */}
        {userId && <{Feature}Form userId={userId} />}
        <{Entity}Card data={...} />
      </main>
    </div>
  );
}
```

## 예시: Header Widget

```typescript
// widgets/header/ui/Header.tsx
import { usePlatformStore } from '@/app/model/stores';
import { useUserStore } from '@/app/model/stores';
import { UserMenu } from '@/features/user-menu';
import { Notifications } from '@/features/notifications';

export function Header() {
  const platform = usePlatformStore((state) => state.platform);
  const user = useUserStore((state) => state.user);

  return (
    <header className="header">
      <div className="logo">배차킹</div>

      {user && (
        <div className="actions">
          <Notifications userId={user.id} />
          <UserMenu user={user} />
        </div>
      )}
    </header>
  );
}
```

## 예시: Dashboard Widget

```typescript
// widgets/dashboard/ui/Dashboard.tsx
import { OrderList } from '@/features/order-list';
import { Statistics } from '@/features/statistics';

interface Props {
  userId: string;
}

export function Dashboard({ userId }: Props) {
  return (
    <div className="dashboard">
      <Statistics userId={userId} />
      <OrderList userId={userId} />
    </div>
  );
}
```

## ❌ Widget에서 금지된 패턴

```typescript
// ❌ 복잡한 비즈니스 로직
export function Widget() {
  const [data, setData] = useState([]);

  useEffect(() => {
    // 복잡한 데이터 가공 (금지!)
    const processed = data.map(...).filter(...).reduce(...);
    setData(processed);
  }, []);
}

// ❌ API 호출 (Features에서 처리)
export function Widget() {
  useEffect(() => {
    fetch('/api/data');  // 금지!
  }, []);
}
```

## ✅ Widget에서 허용된 패턴

```typescript
// ✅ Features/Entities 조합
export function Widget({ userId }: Props) {
  return (
    <>
      <FeatureA userId={userId} />
      <FeatureB userId={userId} />
      <EntityCard data={...} />
    </>
  );
}

// ✅ 최소한의 레이아웃 로직
export function Widget() {
  const [isCollapsed, setIsCollapsed] = useState(false);

  return (
    <div className={isCollapsed ? 'collapsed' : 'expanded'}>
      {/* Features 조합 */}
    </div>
  );
}

// ✅ 플랫폼별 조건부 렌더링
export function Widget() {
  const platform = usePlatformStore((state) => state.platform);

  if (platform === 'app') {
    return <MobileFeature />;
  }

  return <DesktopFeature />;
}
```

## Widget 설계 가이드라인

1. **독립성**: Widget은 독립적으로 동작해야 함
2. **조합**: Features/Entities를 조합하는 역할
3. **최소 로직**: 복잡한 로직은 Features로 분리
4. **재사용성**: 여러 페이지에서 재사용 가능
5. **Props**: 도메인 데이터만 또는 props 없음
