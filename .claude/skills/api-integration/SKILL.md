---
name: api-integration
description: 프로젝트의 기존 API 통합 패턴을 분석하고 동일한 방식으로 적용합니다. API 클라이언트, 에러 처리, 데이터 페칭 패턴을 자동 감지하여 일관성을 유지합니다. Major 워크플로우에서 사용됩니다.
allowed-tools: Read, Write, Grep, Glob
---

# API Integration Skill

프로젝트의 기존 API 통합 패턴을 분석하고 동일하게 적용합니다.

## 실행 조건

다음 요청 시 자동으로 실행됩니다:
- "API 연결해줘"
- "백엔드 API 통합"
- "데이터 페칭 구현"
- Major 워크플로우에서 API 엔드포인트 추가

## Step 0: 기존 API 패턴 분석 (신규 - 최우선)

### 패턴 검색
```bash
# 1. API 클라이언트 파악
grep -r "fetch\|axios\|httpClient" src/app/api/ src/shared/api/ | head -10

# 2. 데이터 페칭 패턴 파악
grep -r "useQuery\|useMutation\|useEffect.*fetch" src/ | head -10

# 3. 에러 처리 패턴 파악
grep -r "try.*catch\|.catch\|handleError" src/features/*/api/ | head -10

# 4. 기존 API 함수 구조 분석
find src -name "*api*.ts" -exec head -50 {} \; | head -200
```

### 발견된 패턴 적용
```markdown
## 🔍 기존 API 패턴 분석 결과

### 사용 중인 도구
- API 클라이언트: fetch/axios/httpClient 중 확인
- 데이터 페칭: React Query/SWR/useEffect 중 확인
- 에러 처리: try-catch/Promise.catch 중 확인

### 패턴 구조
1. API 함수 위치: features/{feature}/api/
2. 타입 정의: model/types.ts
3. 훅 위치: api/use{Feature}.ts
4. 에러 처리: 일관된 에러 객체 사용

✅ 위 패턴을 100% 동일하게 적용합니다.
```

## 통합 프로세스

### Step 1: API 계약 정의

백엔드 API 명세를 기반으로 Request/Response 타입을 정의합니다.

**features/{feature}/model/types.ts**:
```typescript
export interface Create{Feature}Request {
  field1: string;
  field2: number;
  // 요청 필드
}

export interface Create{Feature}Response {
  id: string;
  status: string;
  createdAt: string;
  // 응답 필드
}

export interface {Feature}Error {
  code: string;
  message: string;
  field?: string;
}
```

### Step 2: Zod 스키마 작성

Request 데이터 검증용 Zod 스키마를 생성합니다.

**features/{feature}/model/schema.ts**:
```typescript
import { z } from 'zod';

export const create{Feature}Schema = z.object({
  field1: z.string().min(1, '필드1을 입력하세요'),
  field2: z.number().positive('양수를 입력하세요'),
  // 검증 규칙
});

export type Create{Feature}Input = z.infer<typeof create{Feature}Schema>;
```

### Step 3: API 호출 함수 작성

httpClient를 사용하여 API 호출 함수를 작성합니다.

**features/{feature}/api/create{Feature}.ts**:
```typescript
import { httpClient } from '@/app/api/httpClient';
import type { Create{Feature}Request, Create{Feature}Response } from '../model/types';

export async function create{Feature}(
  data: Create{Feature}Request
): Promise<Create{Feature}Response> {
  const response = await httpClient.post<Create{Feature}Response>(
    '/api/{endpoint}',
    data
  );
  return response.data;
}
```

### Step 4: React Query 훅 작성

useMutation 또는 useQuery 훅을 생성합니다.

**features/{feature}/api/useCreate{Feature}.ts**:
```typescript
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { create{Feature} } from './create{Feature}';
import type { {Feature}Error } from '../model/types';
import type { AxiosError } from 'axios';

export function useCreate{Feature}() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: create{Feature},
    onSuccess: (data) => {
      // 성공 시 캐시 무효화
      queryClient.invalidateQueries({ queryKey: ['{feature}'] });
    },
    onError: (error: AxiosError<{Feature}Error>) => {
      // httpClient가 401은 이미 처리했으므로
      // 여기서는 비즈니스 에러만 처리

      if (error.response?.status === 400) {
        // 검증 에러
        console.error('검증 실패:', error.response.data.message);
      } else if (error.response?.status === 422) {
        // 처리 불가 에러
        console.error('처리 불가:', error.response.data.message);
      }
    },
  });
}
```

### Step 5: MSW 핸들러 생성

개발 환경에서 사용할 MSW 목업을 생성합니다.

**shared/api/mocks/handlers/{feature}.ts**:
```typescript
import { http, HttpResponse } from 'msw';

export const {feature}Handlers = [
  http.post('/api/{endpoint}', async ({ request }) => {
    const body = await request.json();

    // 검증 에러 시뮬레이션
    if (!body.field1) {
      return HttpResponse.json(
        { code: 'VALIDATION_ERROR', message: '필드1을 입력하세요' },
        { status: 400 }
      );
    }

    // 성공 응답
    return HttpResponse.json({
      id: 'mock-id-123',
      status: 'success',
      createdAt: new Date().toISOString(),
    });
  }),
];
```

handlers/index.ts에 등록:
```typescript
import { {feature}Handlers } from './{feature}';

export const handlers = [
  ...{feature}Handlers,
  // ... 다른 핸들러
];
```

### Step 6: Feature에서 사용

생성된 훅을 Feature 컴포넌트에서 사용합니다.

**features/{feature}/ui/{Feature}Form.tsx**:
```typescript
import { useCreate{Feature} } from '../api/useCreate{Feature}';
import { create{Feature}Schema } from '../model/schema';

export function {Feature}Form({ userId }: Props) {
  const mutation = useCreate{Feature}();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    // 폼 데이터 수집
    const formData = { ... };

    // Zod 검증
    const validated = create{Feature}Schema.parse(formData);

    // API 호출
    try {
      const result = await mutation.mutateAsync(validated);
      console.log('성공:', result);
    } catch (error) {
      console.error('실패:', error);
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      {/* UI */}
      <button type="submit" disabled={mutation.isPending}>
        {mutation.isPending ? '처리중...' : '제출'}
      </button>
      {mutation.isError && (
        <p className="error">{String(mutation.error)}</p>
      )}
    </form>
  );
}
```

## 에러 처리 패턴

### httpClient 자동 처리 (건드리지 말 것)

- ✅ 401: 자동 토큰 갱신 및 재시도
- ✅ 토큰 갱신 실패: 자동 로그아웃 및 로그인 페이지 이동

### Feature에서 처리할 에러

```typescript
onError: (error: AxiosError<FeatureError>) => {
  // 400: 검증 에러
  if (error.response?.status === 400) {
    const { field, message } = error.response.data;
    // UI에 필드별 에러 표시
  }

  // 403: 권한 에러
  if (error.response?.status === 403) {
    // 권한 없음 UI 표시
  }

  // 422: 처리 불가 에러
  if (error.response?.status === 422) {
    const { message } = error.response.data;
    // 에러 메시지 표시
  }

  // 500: 서버 에러
  if (error.response?.status === 500) {
    // 일반 에러 메시지 표시
  }
}
```

## React Query 패턴

### 1. useMutation (POST, PUT, DELETE)

**생성/수정/삭제**에 사용:
```typescript
export function useCreate{Feature}() {
  return useMutation({
    mutationFn: create{Feature},
    onSuccess: (data) => {
      queryClient.invalidateQueries({ queryKey: ['{feature}'] });
    },
  });
}
```

### 2. useQuery (GET)

**조회**에 사용:
```typescript
export function use{Feature}(id: string) {
  return useQuery({
    queryKey: ['{feature}', id],
    queryFn: () => fetch{Feature}(id),
    staleTime: 5 * 60 * 1000, // 5분
    retry: 2,
  });
}
```

### 3. 낙관적 업데이트

**즉시 UI 반영**이 필요한 경우:
```typescript
export function useUpdate{Feature}() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: update{Feature},
    onMutate: async (updated) => {
      await queryClient.cancelQueries({ queryKey: ['{feature}'] });

      const previous = queryClient.getQueryData(['{feature}']);

      queryClient.setQueryData(['{feature}'], (old: any) => {
        // 낙관적 업데이트
        return { ...old, ...updated };
      });

      return { previous };
    },
    onError: (err, updated, context) => {
      // 롤백
      queryClient.setQueryData(['{feature}'], context?.previous);
    },
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ['{feature}'] });
    },
  });
}
```

## 상세 참고 파일

- **reference/error-handling.md**: 에러 처리 상세 가이드
- **reference/query-patterns.md**: React Query 패턴 모음
- **examples/mutation-example.md**: useMutation 예시
- **examples/query-example.md**: useQuery 예시

## 보고 형식

```markdown
## ✅ API 통합 완료

### 엔드포인트
POST /api/dispatch

### 생성된 파일
- features/dispatch/model/types.ts (Request/Response 타입)
- features/dispatch/model/schema.ts (Zod 스키마)
- features/dispatch/api/createDispatch.ts (API 호출 함수)
- features/dispatch/api/useCreateDispatch.ts (React Query 훅)
- shared/api/mocks/handlers/dispatch.ts (MSW 핸들러)

### httpClient 활용
- ✅ 자동 토큰 첨부
- ✅ 401 자동 처리
- ✅ 에러 구조화

### 다음 단계
1. DispatchForm에서 useCreateDispatch 훅 사용
2. MSW 활성화하여 로컬 테스트
3. 백엔드 준비 후 실제 API 연동
```

## 주의 사항

1. **httpClient 사용 필수**: 직접 axios 사용하지 말 것
2. **401 처리 금지**: httpClient가 자동 처리하므로 Feature에서 처리하지 말 것
3. **Zod 검증**: API 호출 전 항상 Zod로 검증
4. **MSW 핸들러**: 모든 엔드포인트에 대해 MSW 핸들러 제공
5. **에러 타입**: AxiosError<FeatureError> 타입 사용

## 통합

이 Skill은 다음과 함께 사용됩니다:
- **api-designer** agent: API 계약 먼저 설계
- **form-validation** Skill: React Hook Form과 통합
- **test-guardian** agent: API 호출 테스트 작성
