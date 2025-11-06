---
name: bug-fix-pattern
description: Minor 워크플로우 전용. 일반적인 버그 패턴(타입 에러, null check, 비동기 처리, useEffect 의존성 등)을 자동 감지하고 수정합니다. TypeScript, React, React Query 관련 오류를 빠르게 해결합니다.
allowed-tools: Read, Edit, Bash(yarn type-check), Bash(yarn test*)
---

# Bug Fix Pattern Skill

일반적인 프론트엔드 버그 패턴을 자동으로 감지하고 수정하는 Skill입니다.

## 사용 시점

다음과 같은 상황에서 자동으로 활성화됩니다:

- TypeScript 타입 에러 발생 시
- Null/Undefined 참조 에러 발생 시
- React Hook 경고 발생 시
- 비동기 처리 관련 문제 발생 시
- React Query 사용 관련 오류 발생 시

## 주요 기능

### 1. 타입 에러 자동 수정

상세 패턴은 [`patterns/type-error.md`](patterns/type-error.md) 참조

**일반적 패턴**:
- `Type 'string | undefined' is not assignable to type 'string'`
  → Optional chaining + null coalescing
- `Property does not exist on type`
  → 타입 정의 확인 및 수정
- `Argument of type X is not assignable to parameter of type Y`
  → 타입 캐스팅 또는 타입 가드 추가

### 2. Null/Undefined 안전 처리

**패턴**:
```typescript
// ❌ 위험
const value = data.user.name;

// ✅ 안전
const value = data.user?.name ?? '';
```

**자동 수정 규칙**:
- 체인 접근에 Optional chaining (`?.`) 추가
- 기본값 제공 (`?? ''`)
- 조건부 렌더링에 null check 추가

### 3. useEffect 의존성 배열 자동 수정

**패턴**:
```typescript
// ❌ Warning: React Hook useEffect has a missing dependency
useEffect(() => {
  fetchData(userId);
}, []);

// ✅ 수정
useEffect(() => {
  fetchData(userId);
}, [userId, fetchData]); // 또는 useCallback 활용
```

**자동 수정 전략**:
1. ESLint 경고에서 누락된 의존성 추출
2. 의존성 배열에 추가
3. 필요 시 `useCallback`/`useMemo` 제안

### 4. 비동기 상태 관리

상세 패턴은 [`patterns/async.md`](patterns/async.md) 참조

**패턴**:
```typescript
// ❌ 컴포넌트 unmount 후 setState 경고
const handleSubmit = async () => {
  await submitForm();
  setIsSubmitting(false);
};

// ✅ 수정
const handleSubmit = async () => {
  try {
    await submitForm();
  } catch (error) {
    // 에러 처리
  } finally {
    setIsSubmitting(false);
  }
};
```

### 5. React Query 패턴

**일반적 문제**:
- Stale data 처리 미흡
- Loading/Error 상태 누락
- 캐시 키 관리 실수

**수정 예시**:
```typescript
// ❌ 불완전
const { data } = useQuery(['user'], fetchUser);

// ✅ 완전
const { data, isLoading, isError, error } = useQuery(
  ['user'],
  fetchUser,
  {
    staleTime: 5 * 60 * 1000,
    cacheTime: 10 * 60 * 1000,
    retry: 2,
  }
);

if (isLoading) return <Loading />;
if (isError) return <Error message={error.message} />;
```

## 작업 흐름

### Step 1: 에러 분석
1. 에러 메시지 또는 타입 체크 결과 확인
2. 에러가 발생한 파일 및 라인 특정
3. 관련 코드 컨텍스트 읽기

### Step 2: 패턴 매칭
1. 에러 유형 분류 (타입/null/hook/async)
2. 해당 패턴 파일에서 해결책 조회
3. 프로젝트 컨텍스트에 맞는 수정 방법 결정

### Step 3: 코드 수정
1. 최소 변경으로 수정
2. 기존 코드 스타일 유지
3. 필요 시 import 문 추가/수정

### Step 4: 검증
1. `yarn type-check` 실행
2. 관련 테스트 실행
3. 다른 에러가 발생하지 않았는지 확인

### Step 5: 보고
수정 내용과 검증 결과를 명확히 보고

## 체크리스트

수정 완료 후 다음 항목을 확인하십시오:

[`checklist/post-fix.md`](checklist/post-fix.md) 전체 체크리스트 참조

- [ ] 타입 체크 통과
- [ ] 관련 테스트 통과
- [ ] 기존 코드 스타일 유지
- [ ] 불필요한 변경 없음
- [ ] Import 문 정리
- [ ] 사이드 이펙트 없음

## 제한 사항

이 Skill은 **Minor 워크플로우**에서만 사용됩니다:

✅ 허용:
- 타입 에러 수정
- Null check 추가
- Hook 의존성 수정
- 간단한 로직 수정

❌ 금지:
- 아키텍처 변경
- 새 파일 생성
- 패키지 추가
- 대규모 리팩토링

복잡한 문제는 Major 워크플로우로 전환하십시오.

## 참조 파일

- [타입 에러 패턴](patterns/type-error.md): TypeScript 타입 에러 해결책
- [Null 체크 패턴](patterns/null-check.md): Null/Undefined 안전 처리
- [비동기 패턴](patterns/async.md): Promise, async/await 관련 이슈
- [수정 후 체크리스트](checklist/post-fix.md): 검증 항목

## 사용 예시

```
사용자: "VehicleInfo.tsx에서 타입 에러 나는데 고쳐줘"

1. 파일 읽기
2. 타입 에러 분석
3. patterns/type-error.md에서 해결책 조회
4. 코드 수정
5. yarn type-check 실행
6. 결과 보고
```
