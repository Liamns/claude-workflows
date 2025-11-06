# React Query 패턴 모음

React Query를 활용한 다양한 API 통합 패턴입니다.

## 기본 패턴

### useQuery (조회)

**단일 항목 조회**:
```typescript
export function useDispatch(id: string) {
  return useQuery({
    queryKey: ['dispatch', id],
    queryFn: () => fetchDispatch(id),
    staleTime: 5 * 60 * 1000, // 5분
    retry: 2,
    enabled: !!id, // id가 있을 때만 실행
  });
}
```

**목록 조회**:
```typescript
export function useDispatches() {
  return useQuery({
    queryKey: ['dispatches'],
    queryFn: fetchDispatches,
    staleTime: 3 * 60 * 1000, // 3분
  });
}
```

### useMutation (생성/수정/삭제)

**생성**:
```typescript
export function useCreateDispatch() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: createDispatch,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['dispatches'] });
    },
  });
}
```

**수정**:
```typescript
export function useUpdateDispatch() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: updateDispatch,
    onSuccess: (data, variables) => {
      // 특정 항목만 무효화
      queryClient.invalidateQueries({ queryKey: ['dispatch', variables.id] });
      // 목록도 무효화
      queryClient.invalidateQueries({ queryKey: ['dispatches'] });
    },
  });
}
```

**삭제**:
```typescript
export function useDeleteDispatch() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: deleteDispatch,
    onSuccess: (data, id) => {
      // 캐시에서 제거
      queryClient.removeQueries({ queryKey: ['dispatch', id] });
      // 목록 무효화
      queryClient.invalidateQueries({ queryKey: ['dispatches'] });
    },
  });
}
```

## 고급 패턴

### 1. 낙관적 업데이트

**즉시 UI 반영** (서버 응답 전):
```typescript
export function useUpdateDispatch() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: updateDispatch,
    onMutate: async (updated) => {
      // 1. 진행 중인 쿼리 취소
      await queryClient.cancelQueries({ queryKey: ['dispatch', updated.id] });

      // 2. 이전 데이터 백업
      const previous = queryClient.getQueryData(['dispatch', updated.id]);

      // 3. 낙관적 업데이트
      queryClient.setQueryData(['dispatch', updated.id], (old: any) => ({
        ...old,
        ...updated,
      }));

      return { previous };
    },
    onError: (err, updated, context) => {
      // 에러 시 롤백
      queryClient.setQueryData(['dispatch', updated.id], context?.previous);
    },
    onSettled: (data, error, variables) => {
      // 완료 후 다시 fetch
      queryClient.invalidateQueries({ queryKey: ['dispatch', variables.id] });
    },
  });
}
```

### 2. Infinite Query (무한 스크롤)

```typescript
export function useInfiniteDispatches() {
  return useInfiniteQuery({
    queryKey: ['dispatches', 'infinite'],
    queryFn: ({ pageParam = 0 }) => fetchDispatches({ page: pageParam }),
    getNextPageParam: (lastPage, allPages) => {
      return lastPage.hasMore ? allPages.length : undefined;
    },
    initialPageParam: 0,
  });
}

// 사용
function DispatchList() {
  const {
    data,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
  } = useInfiniteDispatches();

  return (
    <>
      {data?.pages.map((page, i) => (
        <div key={i}>
          {page.items.map((item) => (
            <DispatchCard key={item.id} data={item} />
          ))}
        </div>
      ))}

      {hasNextPage && (
        <button onClick={() => fetchNextPage()} disabled={isFetchingNextPage}>
          {isFetchingNextPage ? '로딩...' : '더 보기'}
        </button>
      )}
    </>
  );
}
```

### 3. Dependent Queries (의존 쿼리)

**쿼리 B는 쿼리 A 완료 후 실행**:
```typescript
function DispatchDetail({ id }: Props) {
  // 1단계: Dispatch 조회
  const { data: dispatch } = useDispatch(id);

  // 2단계: Dispatch의 driver 정보 조회 (dispatch 로드 후)
  const { data: driver } = useDriver(dispatch?.driverId, {
    enabled: !!dispatch?.driverId,
  });

  return (
    <>
      {dispatch && <DispatchInfo data={dispatch} />}
      {driver && <DriverInfo data={driver} />}
    </>
  );
}
```

### 4. Parallel Queries (병렬 쿼리)

**여러 쿼리 동시 실행**:
```typescript
function Dashboard({ userId }: Props) {
  const { data: dispatches } = useDispatches();
  const { data: vehicles } = useVehicles(userId);
  const { data: stats } = useStats(userId);

  // 모든 쿼리가 완료될 때까지 로딩
  const isLoading = !dispatches || !vehicles || !stats;

  if (isLoading) return <Loading />;

  return (
    <>
      <Stats data={stats} />
      <DispatchList data={dispatches} />
      <VehicleList data={vehicles} />
    </>
  );
}
```

### 5. Prefetching (사전 로드)

**다음 페이지 미리 로드**:
```typescript
function DispatchList() {
  const queryClient = useQueryClient();
  const [page, setPage] = useState(0);

  const { data } = useDispatches(page);

  // 다음 페이지 prefetch
  useEffect(() => {
    if (data?.hasMore) {
      queryClient.prefetchQuery({
        queryKey: ['dispatches', page + 1],
        queryFn: () => fetchDispatches(page + 1),
      });
    }
  }, [data, page, queryClient]);

  return (
    <>
      {data?.items.map((item) => <DispatchCard key={item.id} data={item} />)}
      <button onClick={() => setPage(page + 1)}>다음</button>
    </>
  );
}
```

### 6. Polling (주기적 refetch)

**실시간 업데이트**:
```typescript
export function useDispatchStatus(id: string) {
  return useQuery({
    queryKey: ['dispatch', id, 'status'],
    queryFn: () => fetchDispatchStatus(id),
    refetchInterval: 5000, // 5초마다 refetch
    refetchIntervalInBackground: false, // 백그라운드에서는 중지
  });
}
```

### 7. Select (데이터 변환)

**응답 데이터 변환**:
```typescript
export function useDispatchNames() {
  return useQuery({
    queryKey: ['dispatches'],
    queryFn: fetchDispatches,
    select: (data) => data.map((d) => d.name), // 이름만 추출
  });
}
```

## 캐싱 전략

### staleTime vs cacheTime

```typescript
useQuery({
  queryKey: ['dispatches'],
  queryFn: fetchDispatches,
  staleTime: 5 * 60 * 1000, // 5분: 데이터가 신선한 시간
  cacheTime: 10 * 60 * 1000, // 10분: 캐시 유지 시간
});
```

- **staleTime**: 데이터가 "신선"하다고 간주되는 시간 (이 시간 동안은 refetch 안 함)
- **cacheTime**: 사용하지 않는 데이터를 메모리에 유지하는 시간

### 캐시 무효화 전략

**패턴 1: 전체 무효화**
```typescript
queryClient.invalidateQueries({ queryKey: ['dispatches'] });
```

**패턴 2: 특정 항목만**
```typescript
queryClient.invalidateQueries({ queryKey: ['dispatch', id] });
```

**패턴 3: 조건부 무효화**
```typescript
queryClient.invalidateQueries({
  predicate: (query) => query.queryKey[0] === 'dispatch',
});
```

## 에러 처리

### 재시도 설정

```typescript
useQuery({
  queryKey: ['dispatches'],
  queryFn: fetchDispatches,
  retry: 3, // 3번 재시도
  retryDelay: (attemptIndex) => Math.min(1000 * 2 ** attemptIndex, 30000),
});
```

### 에러 경계

```typescript
useQuery({
  queryKey: ['dispatches'],
  queryFn: fetchDispatches,
  useErrorBoundary: true, // 에러 발생 시 Error Boundary로 전파
});
```

## 타입 안전성

```typescript
// API 함수 타입
async function fetchDispatch(id: string): Promise<Dispatch> {
  const response = await httpClient.get<Dispatch>(`/api/dispatch/${id}`);
  return response.data;
}

// 훅 타입
export function useDispatch(id: string): UseQueryResult<Dispatch, AxiosError> {
  return useQuery({
    queryKey: ['dispatch', id],
    queryFn: () => fetchDispatch(id),
  });
}

// 사용
function Component() {
  const { data, error, isLoading } = useDispatch('123');
  //     ^? Dispatch | undefined
  //            ^? AxiosError | null
}
```

## 성능 최적화

### 1. 필요한 것만 select

```typescript
// ❌ 전체 데이터 사용
const { data } = useDispatches();
const names = data?.map((d) => d.name);

// ✅ select로 필요한 것만
const { data: names } = useDispatches({
  select: (data) => data.map((d) => d.name),
});
```

### 2. keepPreviousData

```typescript
useQuery({
  queryKey: ['dispatches', page],
  queryFn: () => fetchDispatches(page),
  keepPreviousData: true, // 페이지 전환 시 이전 데이터 유지
});
```

### 3. initialData

```typescript
useQuery({
  queryKey: ['dispatch', id],
  queryFn: () => fetchDispatch(id),
  initialData: () => {
    // 목록에서 찾기
    return queryClient
      .getQueryData<Dispatch[]>(['dispatches'])
      ?.find((d) => d.id === id);
  },
});
```
