---
name: form-validation
description: React Hook Form + Zod 기반 폼 검증 패턴을 제공합니다. 필드 레벨 및 폼 레벨 검증, 에러 처리, 비동기 검증을 자동화하며 재사용 가능한 폼 컴포넌트 생성을 지원합니다. Major/Minor 워크플로우에서 사용됩니다.
allowed-tools: Read, Write, Grep
---

# Form Validation Skill

React Hook Form + Zod를 활용한 폼 검증 패턴을 자동화합니다.

## 실행 조건

다음 요청 시 자동으로 실행됩니다:
- "폼 검증 추가해줘"
- "React Hook Form 설정"
- "Zod 스키마 만들어줘"
- 폼 입력이 포함된 기능 개발

## 폼 검증 레벨

프로젝트는 두 가지 검증 레벨을 지원합니다:

### 1. 필드 레벨 검증 (Field-level)

**적합한 경우**:
- 필드 간 의존성이 적음
- 즉시 피드백이 중요
- 간단한 폼

**장점**:
- 빠른 피드백
- 독립적인 필드 검증

### 2. 폼 레벨 검증 (Form-level)

**적합한 경우**:
- 필드 간 의존성이 많음
- 복잡한 비즈니스 규칙
- 제출 시점 검증이 중요

**장점**:
- 일관된 검증 시점
- 복잡한 규칙 처리 용이

## 기본 패턴

### Step 1: Zod 스키마 정의

```typescript
// features/{feature}/model/schema.ts
import { z } from 'zod';

export const {feature}Schema = z.object({
  field1: z.string().min(1, '필드1을 입력하세요'),
  field2: z.number().positive('양수를 입력하세요'),
  field3: z.enum(['옵션1', '옵션2'], {
    required_error: '옵션을 선택하세요',
  }),
});

export type {Feature}Input = z.infer<typeof {feature}Schema>;
```

### Step 2: React Hook Form 통합

```typescript
// features/{feature}/ui/{Feature}Form.tsx
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { {feature}Schema } from '../model/schema';
import type { {Feature}Input } from '../model/schema';

export function {Feature}Form() {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<{Feature}Input>({
    resolver: zodResolver({feature}Schema),
  });

  const onSubmit = async (data: {Feature}Input) => {
    // API 호출 등
    console.log(data);
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <div>
        <input {...register('field1')} />
        {errors.field1 && <span>{errors.field1.message}</span>}
      </div>

      <button type="submit" disabled={isSubmitting}>
        제출
      </button>
    </form>
  );
}
```

## 일반 검증 패턴

### 1. 문자열 검증

```typescript
// 필수 문자열
name: z.string().min(1, '이름을 입력하세요'),

// 길이 제한
password: z.string().min(8, '8자 이상 입력하세요').max(20, '20자 이하로 입력하세요'),

// 정규식
plateNumber: z.string().regex(/^\d{2}[가-힣]\d{4}$/, '올바른 차량번호를 입력하세요'),

// 이메일
email: z.string().email('올바른 이메일을 입력하세요'),

// URL
website: z.string().url('올바른 URL을 입력하세요'),

// 선택 (optional)
nickname: z.string().optional(),
```

### 2. 숫자 검증

```typescript
// 양수
age: z.number().positive('양수를 입력하세요'),

// 범위
score: z.number().min(0, '0 이상').max(100, '100 이하'),

// 정수
quantity: z.number().int('정수를 입력하세요'),
```

### 3. 날짜 검증

```typescript
// 날짜 문자열
scheduledDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, '날짜 형식: YYYY-MM-DD'),

// Date 객체
birthDate: z.date(),

// 미래 날짜
futureDate: z.date().refine(
  (date) => date > new Date(),
  '미래 날짜를 선택하세요'
),
```

### 4. 선택 (enum)

```typescript
vehicleType: z.enum(['냉장', '냉동', '건식'], {
  required_error: '차량 종류를 선택하세요',
}),

// 또는 union
status: z.union([
  z.literal('pending'),
  z.literal('confirmed'),
  z.literal('rejected'),
]),
```

### 5. 조건부 필드

```typescript
const schema = z.object({
  hasVehicle: z.boolean(),
  vehicleNumber: z.string().optional(),
}).refine(
  (data) => !data.hasVehicle || !!data.vehicleNumber,
  {
    message: '차량번호를 입력하세요',
    path: ['vehicleNumber'],
  }
);
```

## 복잡한 검증

### 1. 필드 간 의존성

```typescript
const passwordSchema = z.object({
  password: z.string().min(8, '8자 이상'),
  confirmPassword: z.string(),
}).refine(
  (data) => data.password === data.confirmPassword,
  {
    message: '비밀번호가 일치하지 않습니다',
    path: ['confirmPassword'],
  }
);
```

### 2. 비동기 검증

```typescript
const schema = z.object({
  email: z.string().email(),
}).superRefine(async ({ email }, ctx) => {
  const exists = await checkEmailExists(email);
  if (exists) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: '이미 사용 중인 이메일입니다',
      path: ['email'],
    });
  }
});
```

### 3. 배열 검증

```typescript
const schema = z.object({
  items: z.array(
    z.object({
      name: z.string().min(1),
      quantity: z.number().positive(),
    })
  ).min(1, '항목을 1개 이상 추가하세요'),
});
```

## 에러 메시지 커스터마이징

### 1. 한글 메시지

```typescript
import { z } from 'zod';

// 전역 설정
z.setErrorMap((issue, ctx) => {
  if (issue.code === z.ZodIssueCode.invalid_type) {
    return { message: '올바른 형식이 아닙니다' };
  }
  if (issue.code === z.ZodIssueCode.too_small) {
    return { message: `최소 ${issue.minimum}자 이상 입력하세요` };
  }
  return { message: ctx.defaultError };
});
```

### 2. 필드별 메시지

```typescript
const schema = z.object({
  name: z.string({
    required_error: '이름은 필수입니다',
    invalid_type_error: '문자열을 입력하세요',
  }).min(1, '이름을 입력하세요'),
});
```

## 고급 기능

### 1. defaultValues

```typescript
const form = useForm<FormInput>({
  resolver: zodResolver(schema),
  defaultValues: {
    name: '',
    age: 0,
  },
});
```

### 2. watch (값 감시)

```typescript
const hasVehicle = watch('hasVehicle');

// 조건부 렌더링
{hasVehicle && (
  <input {...register('vehicleNumber')} />
)}
```

### 3. setValue (값 설정)

```typescript
const { setValue } = useForm();

const handleAddressSelect = (address: string) => {
  setValue('address', address, {
    shouldValidate: true,
    shouldDirty: true,
  });
};
```

### 4. reset (폼 초기화)

```typescript
const { reset } = useForm();

const onSubmitSuccess = () => {
  reset(); // 폼 초기화
};
```

## 상세 참고 파일

- **templates/zod-schemas.md**: 자주 사용하는 Zod 스키마 템플릿
- **examples/address-form.md**: 주소 입력 폼 예시
- **examples/vehicle-form.md**: 차량 정보 폼 예시

## 보고 형식

```markdown
## ✅ 폼 검증 설정 완료

### Zod 스키마
features/dispatch/model/schema.ts
- createDispatchSchema (8개 필드)

### React Hook Form
features/dispatch/ui/DispatchForm.tsx
- zodResolver 통합
- 필드별 에러 표시
- 제출 중 상태 처리

### 검증 규칙
- vehicleType: enum (냉장/냉동/건식/탑차)
- plateNumber: regex (차량번호 형식)
- scheduledDate: date (YYYY-MM-DD)
- 필드 간 의존성: 없음

### 다음 단계
1. API 통합 (useCreateDispatch)
2. 에러 처리 개선
3. 테스트 작성
```

## 주의 사항

1. **Zod 우선**: 항상 Zod 스키마를 먼저 정의
2. **타입 안전성**: `z.infer`로 타입 추출
3. **에러 메시지**: 사용자 친화적인 한글 메시지
4. **비동기 검증**: superRefine 사용
5. **성능**: 복잡한 검증은 debounce 적용

## 통합

이 Skill은 다음과 함께 사용됩니다:
- **api-integration** Skill: API 호출 전 Zod 검증
- **fsd-component-creation** Skill: Feature 컴포넌트에 폼 추가
- **test-guardian** Sub-agent: 폼 검증 테스트 작성
