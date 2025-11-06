# Page 템플릿

Page는 라우트 핸들러로, Widgets와 Features를 조합하여 전체 페이지를 구성합니다.

## 파일 구조

```
pages/{page-name}/
├── model/
│   └── use{Page}Logic.ts  # (선택) 페이지 레벨 로직
└── ui/
    └── {Page}Page.tsx     # 메인 페이지 컴포넌트
```

## ui/{Page}Page.tsx

```typescript
import { Header } from '@/widgets/header';
import { Footer } from '@/widgets/footer';
import { {Feature}Form } from '@/features/{feature}';

export function {Page}Page() {
  // 페이지 레벨 로직 (최소화)

  return (
    <div className="page">
      <Header />

      <main>
        {/* Widgets/Features 조합 */}
        <{Feature}Form />
      </main>

      <Footer />
    </div>
  );
}
```

## 예시: Dashboard Page

```typescript
// pages/dashboard/ui/DashboardPage.tsx
import { Header } from '@/widgets/header';
import { GNB } from '@/widgets/gnb';
import { Dashboard } from '@/widgets/dashboard';
import { useUserStore } from '@/app/model/stores';

export function DashboardPage() {
  const user = useUserStore((state) => state.user);

  if (!user) {
    return <div>로그인이 필요합니다.</div>;
  }

  return (
    <div className="dashboard-page">
      <Header />
      <GNB />
      <Dashboard userId={user.id} />
    </div>
  );
}
```

## 예시: Sign Up Page

```typescript
// pages/sign-up/ui/SignUpPage.tsx
import { SignUpForm } from '@/features/sign-up';
import { PolicyAgreement } from '@/features/policy-agreement';

export function SignUpPage() {
  return (
    <div className="sign-up-page">
      <header>
        <h1>회원가입</h1>
      </header>

      <main>
        <PolicyAgreement />
        <SignUpForm />
      </main>
    </div>
  );
}
```

## model/use{Page}Logic.ts (선택)

페이지 레벨 로직이 필요한 경우 별도 훅으로 분리합니다:

```typescript
// pages/dashboard/model/useDashboardLogic.ts
import { useEffect } from 'react';
import { useUserStore } from '@/app/model/stores';
import { useNavigate } from 'react-router-dom';

export function useDashboardLogic() {
  const user = useUserStore((state) => state.user);
  const navigate = useNavigate();

  useEffect(() => {
    // 인증 체크
    if (!user) {
      navigate('/sign-in');
    }
  }, [user, navigate]);

  return {
    user,
  };
}
```

사용:

```typescript
export function DashboardPage() {
  const { user } = useDashboardLogic();

  return (
    <div>
      <Dashboard userId={user.id} />
    </div>
  );
}
```

## 라우팅 설정

```typescript
// app/config/routes.tsx
import { DashboardPage } from '@/pages/dashboard';
import { SignUpPage } from '@/pages/sign-up';

export const routes = [
  {
    path: '/dashboard',
    element: <DashboardPage />,
  },
  {
    path: '/sign-up',
    element: <SignUpPage />,
  },
];
```

## ❌ Page에서 금지된 패턴

```typescript
// ❌ 직접 API 호출 (Features에서 처리)
export function Page() {
  useEffect(() => {
    fetch('/api/data');  // 금지!
  }, []);
}

// ❌ 복잡한 비즈니스 로직 (Features로 분리)
export function Page() {
  const [data, setData] = useState([]);

  const processData = () => {
    // 복잡한 데이터 가공 (금지!)
  };
}

// ❌ Entity 직접 스타일링 (Widgets로 분리)
export function Page() {
  return (
    <div>
      <EntityCard data={...} className="custom-style" />  // 금지!
    </div>
  );
}
```

## ✅ Page에서 허용된 패턴

```typescript
// ✅ Widgets/Features 조합
export function Page() {
  return (
    <>
      <Header />
      <Widget />
      <Feature />
      <Footer />
    </>
  );
}

// ✅ 라우트 파라미터 전달
export function Page() {
  const { id } = useParams();

  return <Widget itemId={id} />;
}

// ✅ 페이지 레벨 인증 체크
export function Page() {
  const { user } = usePageLogic();

  if (!user) return <SignInPage />;

  return <DashboardWidget userId={user.id} />;
}
```

## 플랫폼별 Page 분기

```typescript
// pages/dashboard/ui/DashboardPage.tsx
import { usePlatformStore } from '@/app/model/stores';
import { MobileDashboard } from '@/widgets/mobile-dashboard';
import { DesktopDashboard } from '@/widgets/desktop-dashboard';

export function DashboardPage() {
  const platform = usePlatformStore((state) => state.platform);

  if (platform === 'app' || platform === 'mobile-web') {
    return <MobileDashboard />;
  }

  return <DesktopDashboard />;
}
```

## Page 설계 가이드라인

1. **라우트 핸들링**: React Router와 연결
2. **레이아웃 조합**: Widgets/Features를 조합
3. **최소 로직**: 인증 체크, 파라미터 전달 정도만
4. **플랫폼 분기**: 필요시 플랫폼별 UI 분기
5. **로딩/에러 처리**: 페이지 레벨에서 처리
