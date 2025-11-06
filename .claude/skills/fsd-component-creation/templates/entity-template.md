# Entity 템플릿

Entity는 순수한 비즈니스 엔티티 표현으로, 상태 없이 데이터를 받아 표시하는 프레젠테이션 컴포넌트입니다.

## 파일 구조

```
entities/{entity-name}/
├── model/
│   ├── types.ts       # 인터페이스 정의
│   └── schema.ts      # Zod 스키마
├── lib/
│   └── format.ts      # 순수 함수 (포맷팅, 변환)
└── ui/
    ├── {Entity}Card.tsx
    └── {Entity}Info.tsx
```

## model/types.ts

```typescript
export interface {Entity} {
  id: string;
  name: string;
  // 엔티티 속성
}

export interface {Entity}CardProps {
  data: {Entity};
  className?: string;
}

export interface {Entity}InfoProps {
  data: {Entity};
  variant?: 'default' | 'compact';
}
```

## model/schema.ts

```typescript
import { z } from 'zod';

export const {entity}Schema = z.object({
  id: z.string(),
  name: z.string().min(1, '이름을 입력하세요'),
  // 검증 규칙
});

export type {Entity}Input = z.infer<typeof {entity}Schema>;
```

## lib/format.ts (선택)

```typescript
import type { {Entity} } from '../model/types';

export function format{Entity}Display(data: {Entity}): string {
  // 순수 함수로 데이터 포맷팅
  return `${data.name} (${data.id})`;
}

export function is{Entity}Valid(data: {Entity}): boolean {
  // 순수 함수로 검증
  return data.id.length > 0 && data.name.length > 0;
}
```

## ui/{Entity}Card.tsx

```typescript
import type { {Entity}CardProps } from '../model/types';
import { format{Entity}Display } from '../lib/format';

export function {Entity}Card({ data, className }: {Entity}CardProps) {
  return (
    <div className={className}>
      <h3>{format{Entity}Display(data)}</h3>
      {/* 순수 프레젠테이션 */}
    </div>
  );
}
```

## ❌ Entity에서 금지된 패턴

```typescript
// ❌ 상태 관리
const [selected, setSelected] = useState(false);

// ❌ 부수 효과
useEffect(() => {
  fetchData();
}, []);

// ❌ API 호출
const data = await fetch('/api/entity');

// ❌ 전역 상태
const user = useUserStore((state) => state.user);
```

## ✅ Entity에서 허용된 패턴

```typescript
// ✅ 순수 함수
function formatName(name: string): string {
  return name.toUpperCase();
}

// ✅ Props 받아서 표시
export function EntityCard({ data }: Props) {
  return <div>{formatName(data.name)}</div>;
}

// ✅ 조건부 렌더링 (순수)
{data.isActive && <Badge>활성</Badge>}
```
