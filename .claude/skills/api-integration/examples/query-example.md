# useQuery 예시

운송 내역 조회 Feature의 완전한 API 통합 예시입니다.

## 1. 타입 정의

```typescript
// features/dispatch/model/types.ts
export interface Dispatch {
  id: string;
  vehicleType: string;
  ton: string;
  plateNumber: string;
  startAddress: string;
  endAddress: string;
  scheduledDate: string;
  scheduledTime: string;
  status: 'pending' | 'confirmed' | 'in-progress' | 'completed' | 'rejected';
  createdAt: string;
  updatedAt: string;
}

export interface FetchDispatchesParams {
  page?: number;
  limit?: number;
  status?: Dispatch['status'];
}

export interface FetchDispatchesResponse {
  items: Dispatch[];
  total: number;
  hasMore: boolean;
}
```

## 2. API 호출 함수

```typescript
// features/dispatch/api/fetchDispatches.ts
import { httpClient } from '@/app/api/httpClient';
import type { FetchDispatchesParams, FetchDispatchesResponse } from '../model/types';

export async function fetchDispatches(
  params: FetchDispatchesParams = {}
): Promise<FetchDispatchesResponse> {
  const { page = 0, limit = 20, status } = params;

  const response = await httpClient.get<FetchDispatchesResponse>('/api/dispatches', {
    params: { page, limit, status },
  });

  return response.data;
}
```

```typescript
// features/dispatch/api/fetchDispatch.ts
import { httpClient } from '@/app/api/httpClient';
import type { Dispatch } from '../model/types';

export async function fetchDispatch(id: string): Promise<Dispatch> {
  const response = await httpClient.get<Dispatch>(`/api/dispatch/${id}`);
  return response.data;
}
```

## 3. React Query 훅

### 목록 조회

```typescript
// features/dispatch/api/useDispatches.ts
import { useQuery } from '@tanstack/react-query';
import { fetchDispatches } from './fetchDispatches';
import type { FetchDispatchesParams } from '../model/types';

export function useDispatches(params: FetchDispatchesParams = {}) {
  return useQuery({
    queryKey: ['dispatches', params],
    queryFn: () => fetchDispatches(params),
    staleTime: 3 * 60 * 1000, // 3분
    retry: 2,
  });
}
```

### 단일 항목 조회

```typescript
// features/dispatch/api/useDispatch.ts
import { useQuery } from '@tanstack/react-query';
import { fetchDispatch } from './fetchDispatch';

export function useDispatch(id: string) {
  return useQuery({
    queryKey: ['dispatch', id],
    queryFn: () => fetchDispatch(id),
    staleTime: 5 * 60 * 1000, // 5분
    enabled: !!id, // id가 있을 때만 실행
  });
}
```

## 4. Feature 컴포넌트 - 목록

```typescript
// features/dispatch/ui/DispatchList.tsx
import { useDispatches } from '../api/useDispatches';
import { DispatchCard } from '@/entities/dispatch';

export function DispatchList() {
  const { data, isLoading, isError, error } = useDispatches();

  if (isLoading) {
    return <div>로딩 중...</div>;
  }

  if (isError) {
    return <div>에러 발생: {String(error)}</div>;
  }

  if (!data || data.items.length === 0) {
    return <div>운송 내역이 없습니다</div>;
  }

  return (
    <div>
      <h2>운송 내역 ({data.total}건)</h2>
      <ul>
        {data.items.map((dispatch) => (
          <li key={dispatch.id}>
            <DispatchCard data={dispatch} />
          </li>
        ))}
      </ul>
    </div>
  );
}
```

## 5. Feature 컴포넌트 - 필터링

```typescript
// features/dispatch/ui/DispatchListFiltered.tsx
import { useState } from 'react';
import { useDispatches } from '../api/useDispatches';
import { DispatchCard } from '@/entities/dispatch';
import type { Dispatch } from '../model/types';

export function DispatchListFiltered() {
  const [status, setStatus] = useState<Dispatch['status'] | undefined>();

  const { data, isLoading } = useDispatches({ status });

  return (
    <div>
      <div>
        <label>상태 필터:</label>
        <select value={status || ''} onChange={(e) => setStatus(e.target.value as any)}>
          <option value="">전체</option>
          <option value="pending">대기</option>
          <option value="confirmed">확정</option>
          <option value="in-progress">진행중</option>
          <option value="completed">완료</option>
          <option value="rejected">거절</option>
        </select>
      </div>

      {isLoading ? (
        <div>로딩 중...</div>
      ) : (
        <ul>
          {data?.items.map((dispatch) => (
            <li key={dispatch.id}>
              <DispatchCard data={dispatch} />
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
```

## 6. Feature 컴포넌트 - 상세

```typescript
// features/dispatch/ui/DispatchDetail.tsx
import { useDispatch } from '../api/useDispatch';
import { DispatchInfo } from '@/entities/dispatch';

interface Props {
  id: string;
}

export function DispatchDetail({ id }: Props) {
  const { data, isLoading, isError } = useDispatch(id);

  if (isLoading) {
    return <div>로딩 중...</div>;
  }

  if (isError || !data) {
    return <div>운송 정보를 불러올 수 없습니다</div>;
  }

  return (
    <div>
      <h2>운송 상세</h2>
      <DispatchInfo data={data} />
    </div>
  );
}
```

## 7. MSW 핸들러

```typescript
// shared/api/mocks/handlers/dispatch.ts
import { http, HttpResponse } from 'msw';

const mockDispatches = [
  {
    id: 'dispatch-1',
    vehicleType: '냉장',
    ton: '1톤',
    plateNumber: '12가3456',
    startAddress: '서울시 강남구',
    endAddress: '부산시 해운대구',
    scheduledDate: '2025-11-10',
    scheduledTime: '10:00',
    status: 'confirmed',
    createdAt: '2025-11-01T00:00:00Z',
    updatedAt: '2025-11-02T00:00:00Z',
  },
  {
    id: 'dispatch-2',
    vehicleType: '냉동',
    ton: '2.5톤',
    plateNumber: '34나5678',
    startAddress: '인천시 남동구',
    endAddress: '대구시 중구',
    scheduledDate: '2025-11-11',
    scheduledTime: '14:00',
    status: 'pending',
    createdAt: '2025-11-03T00:00:00Z',
    updatedAt: '2025-11-03T00:00:00Z',
  },
];

export const dispatchHandlers = [
  // 목록 조회
  http.get('/api/dispatches', ({ request }) => {
    const url = new URL(request.url);
    const status = url.searchParams.get('status');
    const page = Number(url.searchParams.get('page')) || 0;
    const limit = Number(url.searchParams.get('limit')) || 20;

    let filtered = mockDispatches;
    if (status) {
      filtered = mockDispatches.filter((d) => d.status === status);
    }

    const start = page * limit;
    const end = start + limit;
    const items = filtered.slice(start, end);

    return HttpResponse.json({
      items,
      total: filtered.length,
      hasMore: end < filtered.length,
    });
  }),

  // 단일 조회
  http.get('/api/dispatch/:id', ({ params }) => {
    const { id } = params;
    const dispatch = mockDispatches.find((d) => d.id === id);

    if (!dispatch) {
      return HttpResponse.json(
        { code: 'NOT_FOUND', message: '운송 정보를 찾을 수 없습니다' },
        { status: 404 }
      );
    }

    return HttpResponse.json(dispatch);
  }),
];
```

## 8. 페이지네이션 예시

```typescript
// features/dispatch/ui/DispatchListPaginated.tsx
import { useState } from 'react';
import { useDispatches } from '../api/useDispatches';
import { DispatchCard } from '@/entities/dispatch';

export function DispatchListPaginated() {
  const [page, setPage] = useState(0);
  const limit = 10;

  const { data, isLoading } = useDispatches({ page, limit });

  return (
    <div>
      {isLoading ? (
        <div>로딩 중...</div>
      ) : (
        <>
          <ul>
            {data?.items.map((dispatch) => (
              <li key={dispatch.id}>
                <DispatchCard data={dispatch} />
              </li>
            ))}
          </ul>

          <div>
            <button onClick={() => setPage(page - 1)} disabled={page === 0}>
              이전
            </button>
            <span>페이지 {page + 1}</span>
            <button onClick={() => setPage(page + 1)} disabled={!data?.hasMore}>
              다음
            </button>
          </div>
        </>
      )}
    </div>
  );
}
```

## 9. 테스트

```typescript
// features/dispatch/api/useDispatches.test.ts
import { renderHook, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useDispatches } from './useDispatches';

const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: { retry: false },
    },
  });

  return ({ children }: { children: React.ReactNode }) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  );
};

describe('useDispatches', () => {
  it('운송 목록을 조회한다', async () => {
    const { result } = renderHook(() => useDispatches(), {
      wrapper: createWrapper(),
    });

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true);
    });

    expect(result.current.data?.items).toBeDefined();
    expect(result.current.data?.total).toBeGreaterThan(0);
  });

  it('상태별 필터링이 동작한다', async () => {
    const { result } = renderHook(() => useDispatches({ status: 'confirmed' }), {
      wrapper: createWrapper(),
    });

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true);
    });

    expect(result.current.data?.items.every((d) => d.status === 'confirmed')).toBe(true);
  });
});
```
