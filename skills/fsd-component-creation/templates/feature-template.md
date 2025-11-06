# Feature 템플릿

Feature는 하나의 사용자 액션을 담당하며, 훅 기반 비즈니스 로직으로 구현됩니다.

## 파일 구조

```
features/{feature-name}/
├── api/
│   ├── {action}.ts             # API 호출 함수
│   └── use{Action}.ts          # React Query 훅
├── config/
│   └── constants.ts            # 상수
├── model/
│   ├── types.ts                # 타입 정의
│   ├── schema.ts               # Zod 스키마
│   └── use{Feature}.ts         # 비즈니스 로직 훅
├── lib/
│   └── validators.ts           # 유틸리티
└── ui/
    └── {Feature}Form.tsx       # UI 컴포넌트
```

## model/types.ts

```typescript
export interface {Feature}FormData {
  field1: string;
  field2: number;
  // 폼 필드
}

export interface {Feature}Result {
  ok: boolean;
  data?: any;
  error?: string;
}
```

## model/schema.ts

```typescript
import { z } from 'zod';

export const {feature}Schema = z.object({
  field1: z.string().min(1, '필드1을 입력하세요'),
  field2: z.number().positive('양수를 입력하세요'),
  // 검증 규칙
});

export type {Feature}Input = z.infer<typeof {feature}Schema>;
```

## model/use{Feature}.ts

```typescript
import { useState } from 'react';
import type { {Feature}FormData, {Feature}Result } from './types';
import { {feature}Schema } from './schema';
import { use{Action}Mutation } from '../api/use{Action}';

export function use{Feature}() {
  const [isLoading, setIsLoading] = useState(false);
  const mutation = use{Action}Mutation();

  const handle{Feature} = async (data: {Feature}FormData): Promise<{Feature}Result> => {
    try {
      // 1. Validation
      const validated = {feature}Schema.parse(data);

      setIsLoading(true);

      // 2. Business logic
      const result = await mutation.mutateAsync(validated);

      return { ok: true, data: result };
    } catch (error) {
      return { ok: false, error: String(error) };
    } finally {
      setIsLoading(false);
    }
  };

  return {
    handle{Feature},
    isLoading,
    isError: mutation.isError,
    error: mutation.error,
  };
}
```

## api/{action}.ts

```typescript
import { httpClient } from '@/app/api/httpClient';
import type { {Feature}Input } from '../model/schema';

export interface {Action}Response {
  id: string;
  status: string;
}

export async function {action}(data: {Feature}Input): Promise<{Action}Response> {
  const response = await httpClient.post<{Action}Response>('/api/{endpoint}', data);
  return response.data;
}
```

## api/use{Action}.ts

```typescript
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { {action} } from './{action}';

export function use{Action}Mutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: {action},
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['{feature}'] });
    },
    onError: (error) => {
      console.error('{Feature} 실패:', error);
    },
  });
}
```

## ui/{Feature}Form.tsx

```typescript
import { use{Feature} } from '../model/use{Feature}';

interface Props {
  // ✅ 도메인 데이터만 props로 받음 (NO event handlers)
  userId: string;
  initialData?: {Feature}FormData;
}

export function {Feature}Form({ userId, initialData }: Props) {
  const { handle{Feature}, isLoading, error } = use{Feature}();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    // Collect form data
    const formData = {
      // ...
    };

    const result = await handle{Feature}(formData);

    if (result.ok) {
      // Success handling
    } else {
      // Error handling
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      {/* Form UI */}
      <button type="submit" disabled={isLoading}>
        {isLoading ? '처리중...' : '제출'}
      </button>
      {error && <p className="error">{String(error)}</p>}
    </form>
  );
}
```

## ❌ Feature에서 금지된 패턴

```typescript
// ❌ Props에 이벤트 핸들러 전달
interface Props {
  onSubmit: () => void;  // 금지!
  onChange: (value: string) => void;  // 금지!
}

// ❌ Props에 UI 설정 전달 (Features는 도메인 로직에 집중)
interface Props {
  buttonColor: string;  // 금지!
  showTitle: boolean;  // 금지!
}
```

## ✅ Feature에서 허용된 패턴

```typescript
// ✅ 도메인 데이터만 props
interface Props {
  userId: string;
  vehicleId: string;
  initialDate?: string;
}

// ✅ 내부에서 이벤트 핸들러 정의
export function FeatureForm({ userId }: Props) {
  const handleSubmit = () => { ... };  // 내부 정의
  const handleChange = (value: string) => { ... };  // 내부 정의

  return <form onSubmit={handleSubmit}>...</form>;
}

// ✅ 훅으로 비즈니스 로직 분리
const { handleFeature, isLoading } = useFeature();
```

## React Hook Form 사용 예시

```typescript
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { {feature}Schema } from '../model/schema';
import { use{Feature} } from '../model/use{Feature}';

export function {Feature}Form({ userId }: Props) {
  const { handle{Feature} } = use{Feature}();

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm({
    resolver: zodResolver({feature}Schema),
  });

  const onSubmit = async (data: any) => {
    const result = await handle{Feature}(data);
    if (result.ok) {
      // Success
    }
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register('field1')} />
      {errors.field1 && <span>{errors.field1.message}</span>}

      <button type="submit" disabled={isSubmitting}>
        제출
      </button>
    </form>
  );
}
```
