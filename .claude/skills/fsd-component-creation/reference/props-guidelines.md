# Props 사용 가이드라인

FSD 아키텍처에서 각 레이어별 Props 사용 규칙입니다.

## 기본 원칙

1. **Shared/UI**: 모든 종류의 props 허용 (이벤트 핸들러, 스타일 등)
2. **Entities**: 도메인 데이터 props만
3. **Features**: 도메인 데이터 props만 (이벤트 핸들러 금지)
4. **Widgets**: 도메인 데이터 props 또는 props 없음
5. **Pages**: 도메인 데이터 props 또는 props 없음

## Shared/UI Props

**목적**: 재사용 가능한 UI 컴포넌트

**허용되는 Props**:
```typescript
interface ButtonProps {
  // ✅ 이벤트 핸들러
  onClick?: () => void;
  onMouseEnter?: () => void;
  onFocus?: () => void;

  // ✅ 스타일 props
  variant?: 'primary' | 'secondary' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  color?: string;
  className?: string;

  // ✅ 설정 props
  disabled?: boolean;
  loading?: boolean;
  type?: 'button' | 'submit' | 'reset';

  // ✅ 컨텐츠
  children: React.ReactNode;
  icon?: React.ReactNode;
}
```

**예시**:
```typescript
// shared/ui/Button.tsx
export function Button({
  onClick,
  variant = 'primary',
  size = 'md',
  disabled,
  loading,
  children,
}: ButtonProps) {
  return (
    <button
      className={`btn btn-${variant} btn-${size}`}
      onClick={onClick}
      disabled={disabled || loading}
    >
      {loading ? <Spinner /> : children}
    </button>
  );
}
```

## Entities Props

**목적**: 도메인 엔티티의 순수한 표현

**허용되는 Props**:
```typescript
interface VehicleCardProps {
  // ✅ 도메인 데이터
  data: Vehicle;

  // ✅ 최소한의 스타일 (선택)
  className?: string;

  // ✅ 표시 옵션 (선택)
  variant?: 'default' | 'compact';
}
```

**금지되는 Props**:
```typescript
interface VehicleCardProps {
  // ❌ 이벤트 핸들러
  onClick?: () => void;
  onSelect?: (id: string) => void;

  // ❌ 비즈니스 로직 관련
  isSelectable?: boolean;
  canEdit?: boolean;
}
```

**예시**:
```typescript
// entities/vehicle/ui/VehicleCard.tsx
export function VehicleCard({ data, className, variant = 'default' }: VehicleCardProps) {
  return (
    <div className={className}>
      {variant === 'compact' ? (
        <CompactView data={data} />
      ) : (
        <DefaultView data={data} />
      )}
    </div>
  );
}
```

## Features Props

**목적**: 사용자 액션의 완결된 구현

**허용되는 Props**:
```typescript
interface DispatchFormProps {
  // ✅ 도메인 데이터
  userId: string;
  vehicleId?: string;

  // ✅ 초기값
  initialData?: DispatchFormData;

  // ✅ 설정 (도메인 관련)
  mode?: 'create' | 'edit';
}
```

**금지되는 Props**:
```typescript
interface DispatchFormProps {
  // ❌ 이벤트 핸들러
  onSubmit?: (data: any) => void;
  onChange?: (field: string, value: any) => void;
  onCancel?: () => void;

  // ❌ UI 스타일
  buttonColor?: string;
  formLayout?: 'vertical' | 'horizontal';

  // ❌ UI 설정
  showTitle?: boolean;
  hideFooter?: boolean;
}
```

**올바른 패턴**:
```typescript
// features/dispatch/ui/DispatchForm.tsx
export function DispatchForm({ userId, initialData }: DispatchFormProps) {
  // 이벤트 핸들러는 내부에서 정의
  const handleSubmit = async (data: any) => {
    // 비즈니스 로직
  };

  const handleCancel = () => {
    // 취소 로직
  };

  return (
    <form onSubmit={handleSubmit}>
      {/* UI */}
      <button type="button" onClick={handleCancel}>취소</button>
      <button type="submit">제출</button>
    </form>
  );
}
```

## 왜 Features에서 이벤트 핸들러 Props를 금지하나?

**이유 1: 책임의 분산**
```typescript
// ❌ 나쁜 패턴: 책임 분산
function ParentPage() {
  const handleSubmit = (data: any) => {
    // 비즈니스 로직이 Parent에...
  };

  return <DispatchForm onSubmit={handleSubmit} />;
}

// ✅ 좋은 패턴: 책임 집중
function ParentPage() {
  return <DispatchForm userId={userId} />;
}

function DispatchForm({ userId }: Props) {
  const handleSubmit = async (data: any) => {
    // 비즈니스 로직이 Feature 내부에
  };
}
```

**이유 2: 재사용성 저하**
```typescript
// ❌ 나쁜 패턴: 사용처마다 핸들러 구현 필요
<DispatchForm onSubmit={handleSubmitA} />  // 곳곳에 핸들러 중복
<DispatchForm onSubmit={handleSubmitB} />
<DispatchForm onSubmit={handleSubmitC} />

// ✅ 좋은 패턴: 어디서나 동일하게 동작
<DispatchForm userId={userId} />  // 일관된 동작
```

**이유 3: 테스트 복잡도**
```typescript
// ❌ 나쁜 패턴: Parent와 Feature 모두 테스트 필요
test('Parent의 handleSubmit이 올바르게 동작', () => { ... });
test('DispatchForm이 onSubmit을 올바르게 호출', () => { ... });

// ✅ 좋은 패턴: Feature만 테스트
test('DispatchForm의 제출이 올바르게 동작', () => { ... });
```

## Widgets Props

**목적**: Features/Entities 조합

**허용되는 Props**:
```typescript
interface HeaderProps {
  // ✅ 도메인 데이터 (선택)
  userId?: string;

  // ✅ 또는 props 없음도 가능
}
```

**예시**:
```typescript
// widgets/header/ui/Header.tsx
export function Header({ userId }: HeaderProps) {
  const user = useUserStore((state) => state.user);

  return (
    <header>
      <Logo />
      {user && <UserMenu user={user} />}
    </header>
  );
}

// 또는 props 없음
export function Header() {
  const user = useUserStore((state) => state.user);

  return (
    <header>
      <Logo />
      {user && <UserMenu user={user} />}
    </header>
  );
}
```

## Pages Props

**목적**: 라우트 핸들링

**일반적으로 props 없음**:
```typescript
// pages/dashboard/ui/DashboardPage.tsx
export function DashboardPage() {
  const { userId } = useParams();  // 라우트에서 가져옴
  const user = useUserStore((state) => state.user);  // 전역 상태에서 가져옴

  return (
    <div>
      <Header />
      <Dashboard userId={userId} />
    </div>
  );
}
```

## 예외: 언제 이벤트 핸들러 Props가 필요한가?

**오직 Shared/UI에서만**:

```typescript
// shared/ui/Modal.tsx
interface ModalProps {
  isOpen: boolean;
  onClose: () => void;  // ✅ Shared/UI는 허용
  children: React.ReactNode;
}

export function Modal({ isOpen, onClose, children }: ModalProps) {
  return (
    <div className={isOpen ? 'modal-open' : 'modal-closed'}>
      <button onClick={onClose}>닫기</button>
      {children}
    </div>
  );
}
```

**Features에서 Shared/UI Modal 사용**:
```typescript
// features/dispatch/ui/DispatchForm.tsx
export function DispatchForm({ userId }: Props) {
  const [isModalOpen, setIsModalOpen] = useState(false);

  // 이벤트 핸들러는 Feature 내부에서 정의
  const handleCloseModal = () => {
    setIsModalOpen(false);
  };

  return (
    <div>
      <Modal isOpen={isModalOpen} onClose={handleCloseModal}>
        {/* 모달 컨텐츠 */}
      </Modal>
    </div>
  );
}
```

## Props 체크리스트

### Shared/UI 체크리스트
- [ ] 이벤트 핸들러 props 사용 가능
- [ ] 스타일 props 사용 가능
- [ ] 재사용 가능한 범용 컴포넌트

### Entities 체크리스트
- [ ] 도메인 데이터 props만 사용
- [ ] 이벤트 핸들러 props 없음
- [ ] 최소한의 스타일 props만 (className 정도)

### Features 체크리스트
- [ ] 도메인 데이터 props만 사용
- [ ] 이벤트 핸들러 props 없음
- [ ] UI 설정 props 없음
- [ ] 모든 핸들러는 내부에서 정의

### Widgets 체크리스트
- [ ] 도메인 데이터 props 또는 props 없음
- [ ] Features/Entities 조합에 집중

### Pages 체크리스트
- [ ] 일반적으로 props 없음
- [ ] 라우트 파라미터는 useParams로
- [ ] 전역 상태는 store에서

## 마이그레이션 가이드

**기존 코드**:
```typescript
// ❌ Before
function Parent() {
  const handleSubmit = (data: any) => {
    // 비즈니스 로직
  };

  return <FeatureForm onSubmit={handleSubmit} />;
}
```

**수정 후**:
```typescript
// ✅ After
function Parent() {
  return <FeatureForm userId={userId} />;
}

function FeatureForm({ userId }: Props) {
  const handleSubmit = async (data: any) => {
    // 비즈니스 로직이 Feature 내부로 이동
  };

  return <form onSubmit={handleSubmit}>...</form>;
}
```
