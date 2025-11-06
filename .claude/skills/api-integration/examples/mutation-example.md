# useMutation 예시

운송 신청 Feature의 완전한 API 통합 예시입니다.

## 1. 타입 정의

```typescript
// features/dispatch/model/types.ts
export interface CreateDispatchRequest {
  vehicleType: string;
  ton: string;
  plateNumber: string;
  startAddress: string;
  endAddress: string;
  scheduledDate: string;
  scheduledTime: string;
}

export interface CreateDispatchResponse {
  id: string;
  status: 'pending' | 'confirmed' | 'rejected';
  createdAt: string;
}

export interface DispatchError {
  code: string;
  message: string;
  field?: string;
}
```

## 2. Zod 스키마

```typescript
// features/dispatch/model/schema.ts
import { z } from 'zod';

export const createDispatchSchema = z.object({
  vehicleType: z.enum(['냉장', '냉동', '건식', '탑차'], {
    required_error: '차량 종류를 선택하세요',
  }),
  ton: z.enum(['1톤', '2.5톤', '5톤', '11톤'], {
    required_error: '톤수를 선택하세요',
  }),
  plateNumber: z
    .string()
    .regex(/^\d{2}[가-힣]\d{4}$/, '올바른 차량번호를 입력하세요 (예: 12가3456)'),
  startAddress: z.string().min(1, '상차지를 입력하세요'),
  endAddress: z.string().min(1, '하차지를 입력하세요'),
  scheduledDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, '날짜 형식이 올바르지 않습니다'),
  scheduledTime: z.string().regex(/^\d{2}:\d{2}$/, '시간 형식이 올바르지 않습니다'),
});

export type CreateDispatchInput = z.infer<typeof createDispatchSchema>;
```

## 3. API 호출 함수

```typescript
// features/dispatch/api/createDispatch.ts
import { httpClient } from '@/app/api/httpClient';
import type { CreateDispatchRequest, CreateDispatchResponse } from '../model/types';

export async function createDispatch(
  data: CreateDispatchRequest
): Promise<CreateDispatchResponse> {
  const response = await httpClient.post<CreateDispatchResponse>('/api/dispatch', data);
  return response.data;
}
```

## 4. React Query 훅

```typescript
// features/dispatch/api/useCreateDispatch.ts
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { createDispatch } from './createDispatch';
import type { DispatchError } from '../model/types';
import type { AxiosError } from 'axios';

export function useCreateDispatch() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: createDispatch,
    onSuccess: (data) => {
      // 캐시 무효화
      queryClient.invalidateQueries({ queryKey: ['dispatches'] });

      // 성공 로깅
      console.log('운송 신청 성공:', data.id);
    },
    onError: (error: AxiosError<DispatchError>) => {
      // httpClient가 401은 이미 처리
      // 여기서는 비즈니스 에러만

      if (error.response?.status === 400) {
        // 검증 에러 (UI에서 처리)
        console.error('검증 실패:', error.response.data.message);
      } else if (error.response?.status === 422) {
        // 처리 불가 에러
        console.error('처리 불가:', error.response.data.message);
      } else {
        // 기타 에러
        console.error('알 수 없는 오류:', error);
      }
    },
  });
}
```

## 5. Feature 컴포넌트 (React Hook Form)

```typescript
// features/dispatch/ui/DispatchForm.tsx
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { useCreateDispatch } from '../api/useCreateDispatch';
import { createDispatchSchema } from '../model/schema';
import type { CreateDispatchInput } from '../model/schema';

interface Props {
  userId: string;
}

export function DispatchForm({ userId }: Props) {
  const mutation = useCreateDispatch();

  const {
    register,
    handleSubmit,
    setError,
    formState: { errors, isSubmitting },
  } = useForm<CreateDispatchInput>({
    resolver: zodResolver(createDispatchSchema),
  });

  const onSubmit = async (data: CreateDispatchInput) => {
    try {
      const result = await mutation.mutateAsync(data);

      // 성공 처리
      alert(`운송 신청 완료: ${result.id}`);

      // 페이지 이동 등
      // navigate('/dashboard');
    } catch (error) {
      // 에러는 이미 useCreateDispatch에서 로깅
      // 필요시 추가 처리

      if (axios.isAxiosError(error) && error.response?.status === 400) {
        const { field, message } = error.response.data;
        if (field) {
          setError(field as any, { message });
        }
      }
    }
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <div>
        <label htmlFor="vehicleType">차량 종류</label>
        <select {...register('vehicleType')} id="vehicleType">
          <option value="">선택</option>
          <option value="냉장">냉장</option>
          <option value="냉동">냉동</option>
          <option value="건식">건식</option>
          <option value="탑차">탑차</option>
        </select>
        {errors.vehicleType && <span>{errors.vehicleType.message}</span>}
      </div>

      <div>
        <label htmlFor="ton">톤수</label>
        <select {...register('ton')} id="ton">
          <option value="">선택</option>
          <option value="1톤">1톤</option>
          <option value="2.5톤">2.5톤</option>
          <option value="5톤">5톤</option>
          <option value="11톤">11톤</option>
        </select>
        {errors.ton && <span>{errors.ton.message}</span>}
      </div>

      <div>
        <label htmlFor="plateNumber">차량번호</label>
        <input {...register('plateNumber')} id="plateNumber" placeholder="12가3456" />
        {errors.plateNumber && <span>{errors.plateNumber.message}</span>}
      </div>

      <div>
        <label htmlFor="startAddress">상차지</label>
        <input {...register('startAddress')} id="startAddress" />
        {errors.startAddress && <span>{errors.startAddress.message}</span>}
      </div>

      <div>
        <label htmlFor="endAddress">하차지</label>
        <input {...register('endAddress')} id="endAddress" />
        {errors.endAddress && <span>{errors.endAddress.message}</span>}
      </div>

      <div>
        <label htmlFor="scheduledDate">운송 날짜</label>
        <input {...register('scheduledDate')} id="scheduledDate" type="date" />
        {errors.scheduledDate && <span>{errors.scheduledDate.message}</span>}
      </div>

      <div>
        <label htmlFor="scheduledTime">운송 시간</label>
        <input {...register('scheduledTime')} id="scheduledTime" type="time" />
        {errors.scheduledTime && <span>{errors.scheduledTime.message}</span>}
      </div>

      <button type="submit" disabled={isSubmitting || mutation.isPending}>
        {mutation.isPending ? '신청 중...' : '운송 신청'}
      </button>

      {mutation.isError && <p className="error">신청 중 오류가 발생했습니다</p>}
    </form>
  );
}
```

## 6. MSW 핸들러

```typescript
// shared/api/mocks/handlers/dispatch.ts
import { http, HttpResponse } from 'msw';

export const dispatchHandlers = [
  http.post('/api/dispatch', async ({ request }) => {
    const body = await request.json();

    // 검증 에러 시뮬레이션
    if (!body.vehicleType) {
      return HttpResponse.json(
        {
          code: 'VALIDATION_ERROR',
          message: '차량 종류를 선택하세요',
          field: 'vehicleType',
        },
        { status: 400 }
      );
    }

    if (!body.plateNumber || !/^\d{2}[가-힣]\d{4}$/.test(body.plateNumber)) {
      return HttpResponse.json(
        {
          code: 'VALIDATION_ERROR',
          message: '올바른 차량번호를 입력하세요',
          field: 'plateNumber',
        },
        { status: 400 }
      );
    }

    // 성공 응답
    return HttpResponse.json({
      id: `dispatch-${Date.now()}`,
      status: 'pending',
      createdAt: new Date().toISOString(),
    });
  }),
];
```

## 7. 테스트

```typescript
// features/dispatch/api/useCreateDispatch.test.ts
import { renderHook, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useCreateDispatch } from './useCreateDispatch';
import { server } from '@/shared/api/mocks/server';
import { http, HttpResponse } from 'msw';

const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: { retry: false },
      mutations: { retry: false },
    },
  });

  return ({ children }: { children: React.ReactNode }) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  );
};

describe('useCreateDispatch', () => {
  it('성공 시 dispatches 캐시를 무효화한다', async () => {
    const { result } = renderHook(() => useCreateDispatch(), {
      wrapper: createWrapper(),
    });

    await result.current.mutateAsync({
      vehicleType: '냉장',
      ton: '1톤',
      plateNumber: '12가3456',
      startAddress: '서울',
      endAddress: '부산',
      scheduledDate: '2025-11-10',
      scheduledTime: '10:00',
    });

    expect(result.current.isSuccess).toBe(true);
  });

  it('400 에러 시 검증 에러를 처리한다', async () => {
    server.use(
      http.post('/api/dispatch', () => {
        return HttpResponse.json(
          {
            code: 'VALIDATION_ERROR',
            message: '차량번호 오류',
            field: 'plateNumber',
          },
          { status: 400 }
        );
      })
    );

    const { result } = renderHook(() => useCreateDispatch(), {
      wrapper: createWrapper(),
    });

    try {
      await result.current.mutateAsync({
        vehicleType: '냉장',
        ton: '1톤',
        plateNumber: 'invalid',
        startAddress: '서울',
        endAddress: '부산',
        scheduledDate: '2025-11-10',
        scheduledTime: '10:00',
      });
    } catch (error) {
      // 예상된 에러
    }

    expect(result.current.isError).toBe(true);
  });
});
```
