---
name: typescript-strict
description: 엄격한 TypeScript 타입 처리 패턴을 제공합니다. 타입 가드, 제네릭, 유틸리티 타입 활용법을 안내합니다. implementer-unified와 bug-fix-pattern에서 활용됩니다.
allowed-tools: Read, Grep
---

# TypeScript Strict Skill

엄격한 TypeScript 타입 안전성을 보장하는 패턴과 모범 사례를 제공합니다.

## 사용 시점

다음과 같은 상황에서 활성화됩니다:

- 타입 에러 해결
- 제네릭 타입 설계
- 타입 가드 구현
- 유틸리티 타입 활용
- strict 모드 관련 이슈

## 핵심 타입 패턴

### 1. 타입 가드 (Type Guards)

**사용자 정의 타입 가드:**
```typescript
// 타입 가드 함수
function isString(value: unknown): value is string {
  return typeof value === 'string';
}

function isUser(value: unknown): value is User {
  return (
    typeof value === 'object' &&
    value !== null &&
    'id' in value &&
    'email' in value
  );
}

// 사용
function processValue(value: unknown) {
  if (isString(value)) {
    // value는 string 타입
    console.log(value.toUpperCase());
  }

  if (isUser(value)) {
    // value는 User 타입
    console.log(value.email);
  }
}
```

**in 연산자 타입 가드:**
```typescript
interface Dog {
  bark(): void;
}

interface Cat {
  meow(): void;
}

function makeSound(animal: Dog | Cat) {
  if ('bark' in animal) {
    animal.bark(); // Dog 타입
  } else {
    animal.meow(); // Cat 타입
  }
}
```

**instanceof 타입 가드:**
```typescript
class ApiError extends Error {
  constructor(
    message: string,
    public statusCode: number,
  ) {
    super(message);
  }
}

function handleError(error: unknown) {
  if (error instanceof ApiError) {
    console.log(error.statusCode); // ApiError 타입
  } else if (error instanceof Error) {
    console.log(error.message); // Error 타입
  }
}
```

### 2. Discriminated Unions (판별 유니온)

```typescript
// ✅ 판별 가능한 유니온
type Result<T> =
  | { success: true; data: T }
  | { success: false; error: string };

function handleResult<T>(result: Result<T>) {
  if (result.success) {
    // result.data 접근 가능
    console.log(result.data);
  } else {
    // result.error 접근 가능
    console.log(result.error);
  }
}

// API 응답 패턴
type ApiResponse<T> =
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: Error };

function renderResponse<T>(response: ApiResponse<T>) {
  switch (response.status) {
    case 'loading':
      return <Loading />;
    case 'success':
      return <Data data={response.data} />;
    case 'error':
      return <Error error={response.error} />;
  }
}
```

### 3. 제네릭 패턴

**기본 제네릭:**
```typescript
// 제네릭 함수
function identity<T>(value: T): T {
  return value;
}

// 제네릭 인터페이스
interface Repository<T> {
  findOne(id: string): Promise<T | null>;
  findAll(): Promise<T[]>;
  save(entity: T): Promise<T>;
  delete(id: string): Promise<void>;
}

// 제네릭 클래스
class DataStore<T> {
  private items: T[] = [];

  add(item: T): void {
    this.items.push(item);
  }

  get(index: number): T | undefined {
    return this.items[index];
  }
}
```

**제네릭 제약 (Constraints):**
```typescript
// extends로 제약
function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key];
}

// 여러 제약 조합
interface HasId {
  id: string;
}

interface HasName {
  name: string;
}

function processEntity<T extends HasId & HasName>(entity: T): string {
  return `${entity.id}: ${entity.name}`;
}
```

**조건부 타입:**
```typescript
// 조건부 타입
type IsString<T> = T extends string ? true : false;

// infer를 활용한 타입 추출
type UnwrapPromise<T> = T extends Promise<infer U> ? U : T;

type ArrayItem<T> = T extends (infer U)[] ? U : never;

// 사용 예시
type A = UnwrapPromise<Promise<string>>; // string
type B = ArrayItem<number[]>; // number
```

### 4. 유틸리티 타입 활용

```typescript
// Partial - 모든 속성을 선택적으로
interface User {
  id: string;
  name: string;
  email: string;
}

type UpdateUserDto = Partial<User>;
// { id?: string; name?: string; email?: string }

// Required - 모든 속성을 필수로
type RequiredUser = Required<UpdateUserDto>;

// Pick - 특정 속성만 선택
type UserCredentials = Pick<User, 'email'>;
// { email: string }

// Omit - 특정 속성 제외
type UserWithoutId = Omit<User, 'id'>;
// { name: string; email: string }

// Record - 키-값 매핑
type UserRoles = Record<string, 'admin' | 'user' | 'guest'>;

// Extract / Exclude
type NumberOrString = number | string | boolean;
type OnlyNumberOrString = Extract<NumberOrString, number | string>; // number | string
type ExcludeBoolean = Exclude<NumberOrString, boolean>; // number | string

// NonNullable
type MaybeString = string | null | undefined;
type DefinitelyString = NonNullable<MaybeString>; // string

// ReturnType / Parameters
function createUser(name: string, age: number): User {
  return { id: '1', name, email: `${name}@example.com` };
}

type CreateUserReturn = ReturnType<typeof createUser>; // User
type CreateUserParams = Parameters<typeof createUser>; // [string, number]
```

### 5. 커스텀 유틸리티 타입

```typescript
// DeepPartial - 중첩 객체도 선택적으로
type DeepPartial<T> = T extends object
  ? { [P in keyof T]?: DeepPartial<T[P]> }
  : T;

// DeepReadonly - 중첩 객체도 읽기 전용으로
type DeepReadonly<T> = T extends object
  ? { readonly [P in keyof T]: DeepReadonly<T[P]> }
  : T;

// Nullable - null 허용
type Nullable<T> = T | null;

// ValueOf - 객체 값의 유니온 타입
type ValueOf<T> = T[keyof T];

// 사용 예시
interface Config {
  api: {
    baseUrl: string;
    timeout: number;
  };
  features: {
    darkMode: boolean;
  };
}

type PartialConfig = DeepPartial<Config>;
// 중첩된 모든 속성이 선택적
```

### 6. Null 안전 패턴

```typescript
// Optional Chaining + Nullish Coalescing
interface User {
  name: string;
  address?: {
    city?: string;
    country?: string;
  };
}

function getCity(user: User): string {
  return user.address?.city ?? 'Unknown';
}

// Non-null Assertion (주의해서 사용)
function processUser(user: User | null) {
  // 확실히 null이 아닌 경우에만 사용
  const name = user!.name; // 위험!

  // 더 안전한 방법
  if (user) {
    const safeName = user.name; // OK
  }
}

// as const로 리터럴 타입 유지
const CONFIG = {
  apiUrl: 'https://api.example.com',
  timeout: 5000,
} as const;

// typeof로 타입 추출
type Config = typeof CONFIG;
// { readonly apiUrl: "https://api.example.com"; readonly timeout: 5000 }
```

### 7. 함수 오버로딩

```typescript
// 함수 오버로딩
function parse(value: string): number;
function parse(value: number): string;
function parse(value: string | number): string | number {
  if (typeof value === 'string') {
    return parseInt(value, 10);
  }
  return value.toString();
}

// 제네릭으로 대체 (더 유연)
function parseGeneric<T extends string | number>(
  value: T,
): T extends string ? number : string {
  if (typeof value === 'string') {
    return parseInt(value, 10) as any;
  }
  return value.toString() as any;
}
```

### 8. 타입 단언 vs 타입 가드

```typescript
// ❌ 타입 단언 (피해야 함)
const user = response.data as User; // 런타임 검증 없음

// ✅ 타입 가드 (권장)
function isUser(data: unknown): data is User {
  return (
    typeof data === 'object' &&
    data !== null &&
    'id' in data &&
    'email' in data
  );
}

const data = response.data;
if (isUser(data)) {
  // 안전하게 User 타입으로 사용
  console.log(data.email);
}
```

## strict 컴파일러 옵션

```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "strictBindCallApply": true,
    "strictPropertyInitialization": true,
    "noImplicitThis": true,
    "useUnknownInCatchVariables": true,
    "alwaysStrict": true
  }
}
```

## 검토 체크리스트

- [ ] any 타입 사용 최소화
- [ ] unknown 대신 적절한 타입 가드 사용
- [ ] null/undefined 안전하게 처리
- [ ] 제네릭으로 재사용성 확보
- [ ] 유틸리티 타입 적절히 활용

## 연동 Agent/Skill

- **bug-fix-pattern**: 타입 에러 수정
- **implementer-unified**: 타입 안전한 구현
- **reviewer-unified**: 타입 검토

## 사용 예시

```
사용자: "이 함수에서 타입 에러가 나요"

1. 에러 메시지 분석
2. typescript-strict 패턴 참조
3. 타입 가드 또는 유틸리티 타입 적용
4. 타입 안전한 코드 제안
```
