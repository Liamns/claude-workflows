# TypeScript 타입 에러 패턴

## 1. Optional 타입 에러

### 에러
```
Type 'string | undefined' is not assignable to type 'string'
```

### 해결책
```typescript
// ❌
const value: string = formData.name;

// ✅ Option 1: Null coalescing
const value: string = formData.name ?? '';

// ✅ Option 2: Non-null assertion (확실한 경우만)
const value: string = formData.name!;

// ✅ Option 3: 타입 가드
if (formData.name) {
  const value: string = formData.name;
}
```

## 2. Property does not exist

### 에러
```
Property 'street' does not exist on type 'Address | undefined'
```

### 해결책
```typescript
// ❌
const street = data.address.street;

// ✅ Optional chaining
const street = data.address?.street;
```

## 3. 함수 인자 타입 불일치

### 에러
```
Argument of type 'string' is not assignable to parameter of type 'number'
```

### 해결책
```typescript
// ❌
const id: string = "123";
fetchUser(id);

// ✅ 타입 변환
const id: string = "123";
fetchUser(Number(id));

// ✅ 또는 타입 정의 수정
function fetchUser(id: string | number) { ... }
```
