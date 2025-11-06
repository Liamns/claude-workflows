# 에러 처리 가이드

httpClient 기반 API 통합에서 에러를 처리하는 방법입니다.

## 에러 처리 계층

```
┌─────────────────────────┐
│  httpClient (자동 처리)  │  401 토큰 갱신
├─────────────────────────┤
│  React Query (선택)     │  재시도, 캐시 무효화
├─────────────────────────┤
│  Feature (비즈니스)     │  400, 403, 422, 500 처리
├─────────────────────────┤
│  UI (표시)              │  에러 메시지 UI
└─────────────────────────┘
```

## httpClient 자동 처리

**절대 건드리지 말 것!**

httpClient는 다음을 자동 처리합니다:

### 401 Unauthorized (토큰 만료)

```typescript
// httpClient 내부 (참고용)
if (error.response?.status === 401) {
  // 1. Refresh token으로 새 access token 발급
  const newAccessToken = await refreshToken();

  // 2. 새 토큰으로 원래 요청 재시도
  return httpClient.request(originalRequest);
}
```

**Feature에서 할 일: 없음** ✅

### Refresh Token 만료

```typescript
// httpClient 내부 (참고용)
if (refreshFailed) {
  // 1. 모든 토큰 삭제
  useTokenStore.getState().clearTokens();

  // 2. 로그인 페이지로 이동
  window.location.href = '/sign-in';
}
```

**Feature에서 할 일: 없음** ✅

## Feature에서 처리할 에러

### 400 Bad Request (검증 에러)

**백엔드 응답**:
```json
{
  "code": "VALIDATION_ERROR",
  "message": "올바른 차량번호를 입력하세요",
  "field": "plateNumber"
}
```

**처리 방법**:
```typescript
onError: (error: AxiosError<FeatureError>) => {
  if (error.response?.status === 400) {
    const { field, message } = error.response.data;

    // 필드별 에러 표시 (React Hook Form)
    if (field) {
      setError(field, { message });
    } else {
      // 일반 메시지 표시
      toast.error(message);
    }
  }
}
```

### 403 Forbidden (권한 에러)

**백엔드 응답**:
```json
{
  "code": "PERMISSION_DENIED",
  "message": "이 작업을 수행할 권한이 없습니다"
}
```

**처리 방법**:
```typescript
onError: (error: AxiosError<FeatureError>) => {
  if (error.response?.status === 403) {
    const { message } = error.response.data;

    // 권한 없음 메시지 표시
    toast.error(message);

    // 선택: 이전 페이지로 이동
    navigate(-1);
  }
}
```

### 422 Unprocessable Entity (처리 불가)

**백엔드 응답**:
```json
{
  "code": "ALREADY_EXISTS",
  "message": "이미 신청된 운송 건입니다"
}
```

**처리 방법**:
```typescript
onError: (error: AxiosError<FeatureError>) => {
  if (error.response?.status === 422) {
    const { code, message } = error.response.data;

    // 코드별 처리
    if (code === 'ALREADY_EXISTS') {
      toast.warning('이미 신청된 운송 건입니다');
    } else {
      toast.error(message);
    }
  }
}
```

### 500 Internal Server Error (서버 에러)

**백엔드 응답**:
```json
{
  "code": "INTERNAL_ERROR",
  "message": "서버 오류가 발생했습니다"
}
```

**처리 방법**:
```typescript
onError: (error: AxiosError<FeatureError>) => {
  if (error.response?.status === 500) {
    // 일반 에러 메시지
    toast.error('일시적인 오류가 발생했습니다. 잠시 후 다시 시도해주세요.');

    // 선택: 에러 로깅
    console.error('서버 에러:', error);
  }
}
```

## 통합 에러 처리 패턴

### 패턴 1: 모든 에러 처리

```typescript
export function useCreateDispatch() {
  return useMutation({
    mutationFn: createDispatch,
    onError: (error: AxiosError<DispatchError>) => {
      const status = error.response?.status;
      const data = error.response?.data;

      switch (status) {
        case 400:
          // 검증 에러
          if (data.field) {
            setError(data.field, { message: data.message });
          } else {
            toast.error(data.message);
          }
          break;

        case 403:
          // 권한 에러
          toast.error(data.message);
          navigate(-1);
          break;

        case 422:
          // 처리 불가
          toast.warning(data.message);
          break;

        case 500:
          // 서버 에러
          toast.error('일시적인 오류가 발생했습니다');
          break;

        default:
          toast.error('알 수 없는 오류가 발생했습니다');
      }
    },
  });
}
```

### 패턴 2: 에러 핸들러 분리

```typescript
// features/dispatch/lib/handleDispatchError.ts
export function handleDispatchError(
  error: AxiosError<DispatchError>,
  setError?: UseFormSetError
) {
  const status = error.response?.status;
  const data = error.response?.data;

  switch (status) {
    case 400:
      if (data.field && setError) {
        setError(data.field, { message: data.message });
      } else {
        toast.error(data.message);
      }
      break;

    // ... 다른 케이스
  }
}

// 사용
export function useCreateDispatch() {
  return useMutation({
    mutationFn: createDispatch,
    onError: (error) => handleDispatchError(error),
  });
}
```

## React Hook Form 통합

```typescript
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';

export function DispatchForm() {
  const {
    register,
    handleSubmit,
    setError,
    formState: { errors },
  } = useForm({
    resolver: zodResolver(dispatchSchema),
  });

  const mutation = useCreateDispatch();

  const onSubmit = async (data: any) => {
    try {
      await mutation.mutateAsync(data);
    } catch (error) {
      // 400 에러 시 필드별 에러 표시
      if (axios.isAxiosError(error) && error.response?.status === 400) {
        const { field, message } = error.response.data;
        if (field) {
          setError(field, { message });
        }
      }
    }
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register('plateNumber')} />
      {errors.plateNumber && <span>{errors.plateNumber.message}</span>}

      <button type="submit">제출</button>
    </form>
  );
}
```

## 네트워크 에러 처리

```typescript
onError: (error: AxiosError<FeatureError>) => {
  // 응답이 없는 경우 (네트워크 문제)
  if (!error.response) {
    toast.error('네트워크 연결을 확인해주세요');
    return;
  }

  // 타임아웃
  if (error.code === 'ECONNABORTED') {
    toast.error('요청 시간이 초과되었습니다');
    return;
  }

  // 서버 응답 에러
  const status = error.response.status;
  // ... 상태 코드별 처리
}
```

## 에러 로깅

```typescript
onError: (error: AxiosError<FeatureError>) => {
  // 에러 로깅 (선택)
  console.error('API Error:', {
    url: error.config?.url,
    method: error.config?.method,
    status: error.response?.status,
    data: error.response?.data,
  });

  // Sentry 등 에러 추적 서비스 (선택)
  // Sentry.captureException(error);

  // UI 에러 처리
  // ...
}
```

## 테스트

```typescript
// features/dispatch/api/useCreateDispatch.test.ts
import { renderHook, waitFor } from '@testing-library/react';
import { useCreateDispatch } from './useCreateDispatch';

describe('useCreateDispatch', () => {
  it('400 에러 시 검증 에러 처리', async () => {
    // MSW에서 400 응답 설정
    server.use(
      http.post('/api/dispatch', () => {
        return HttpResponse.json(
          { code: 'VALIDATION_ERROR', message: '차량번호 오류', field: 'plateNumber' },
          { status: 400 }
        );
      })
    );

    const { result } = renderHook(() => useCreateDispatch());

    await result.current.mutateAsync({ ... });

    expect(result.current.isError).toBe(true);
    // 에러 처리 검증
  });
});
```
