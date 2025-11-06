# Zod 스키마 템플릿 모음

자주 사용하는 Zod 검증 패턴 모음입니다.

## 한국 특화 검증

### 차량번호

```typescript
plateNumber: z.string().regex(
  /^\d{2}[가-힣]\d{4}$/,
  '올바른 차량번호를 입력하세요 (예: 12가3456)'
),
```

### 휴대폰 번호

```typescript
phone: z.string().regex(
  /^010-?\d{4}-?\d{4}$/,
  '올바른 휴대폰 번호를 입력하세요 (예: 010-1234-5678)'
),
```

### 사업자등록번호

```typescript
businessNumber: z.string().regex(
  /^\d{3}-?\d{2}-?\d{5}$/,
  '올바른 사업자등록번호를 입력하세요 (예: 123-45-67890)'
),
```

### 주민등록번호 (앞자리)

```typescript
residentNumber: z.string().regex(
  /^\d{6}$/,
  '주민등록번호 앞 6자리를 입력하세요'
),
```

## 날짜/시간 검증

### 날짜 (YYYY-MM-DD)

```typescript
date: z.string().regex(
  /^\d{4}-\d{2}-\d{2}$/,
  '날짜 형식: YYYY-MM-DD'
),
```

### 시간 (HH:MM)

```typescript
time: z.string().regex(
  /^\d{2}:\d{2}$/,
  '시간 형식: HH:MM'
),
```

### 미래 날짜만

```typescript
futureDate: z.string().refine(
  (dateStr) => new Date(dateStr) > new Date(),
  '미래 날짜를 선택하세요'
),
```

### 영업일 (평일)

```typescript
workday: z.string().refine(
  (dateStr) => {
    const day = new Date(dateStr).getDay();
    return day !== 0 && day !== 6; // 일요일(0), 토요일(6) 제외
  },
  '평일을 선택하세요'
),
```

## 비즈니스 로직 검증

### 톤수 선택

```typescript
ton: z.enum(['1톤', '2.5톤', '5톤', '11톤'], {
  required_error: '톤수를 선택하세요',
}),
```

### 차량 종류

```typescript
vehicleType: z.enum(['냉장', '냉동', '건식', '탑차'], {
  required_error: '차량 종류를 선택하세요',
}),
```

### 가격 범위

```typescript
price: z.number()
  .min(10000, '최소 10,000원 이상')
  .max(10000000, '최대 10,000,000원 이하'),
```

### 할인율

```typescript
discountRate: z.number()
  .min(0, '0% 이상')
  .max(100, '100% 이하'),
```

## 복잡한 검증

### 비밀번호 강도

```typescript
password: z.string()
  .min(8, '8자 이상')
  .max(20, '20자 이하')
  .regex(
    /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])/,
    '영문 대소문자, 숫자, 특수문자를 포함해야 합니다'
  ),

confirmPassword: z.string(),
}).refine(
  (data) => data.password === data.confirmPassword,
  {
    message: '비밀번호가 일치하지 않습니다',
    path: ['confirmPassword'],
  }
);
```

### 주소 입력

```typescript
const addressSchema = z.object({
  zipCode: z.string().regex(/^\d{5}$/, '우편번호 5자리를 입력하세요'),
  address: z.string().min(1, '주소를 입력하세요'),
  detailAddress: z.string().optional(),
});
```

### 파일 업로드

```typescript
file: z
  .instanceof(File)
  .refine((file) => file.size <= 5 * 1024 * 1024, '파일 크기는 5MB 이하')
  .refine(
    (file) => ['image/jpeg', 'image/png'].includes(file.type),
    'JPG 또는 PNG 파일만 가능'
  ),
```

### 배열 (최소/최대 개수)

```typescript
items: z.array(z.string())
  .min(1, '항목을 1개 이상 추가하세요')
  .max(10, '최대 10개까지 가능'),
```

### 조건부 필수

```typescript
const schema = z.object({
  type: z.enum(['개인', '사업자']),
  businessNumber: z.string().optional(),
}).refine(
  (data) => data.type !== '사업자' || !!data.businessNumber,
  {
    message: '사업자등록번호를 입력하세요',
    path: ['businessNumber'],
  }
);
```

### 중복 검사 (비동기)

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

## 선택적 필드

### 기본 선택

```typescript
nickname: z.string().optional(),
```

### null 허용

```typescript
memo: z.string().nullable(),
```

### 빈 문자열을 null로

```typescript
memo: z.string().transform((val) => val || null),
```

### undefined를 빈 문자열로

```typescript
nickname: z.string().default(''),
```

## 변환 (transform)

### 문자열을 숫자로

```typescript
age: z.string().transform((val) => parseInt(val, 10)),
```

### 대문자로 변환

```typescript
code: z.string().transform((val) => val.toUpperCase()),
```

### trim 적용

```typescript
name: z.string().transform((val) => val.trim()),
```

## 재사용 가능한 스키마

### 기본 스키마 확장

```typescript
const baseVehicleSchema = z.object({
  type: z.enum(['냉장', '냉동', '건식']),
  ton: z.enum(['1톤', '2.5톤', '5톤']),
});

const createVehicleSchema = baseVehicleSchema.extend({
  plateNumber: z.string().regex(/^\d{2}[가-힣]\d{4}$/),
});

const updateVehicleSchema = baseVehicleSchema.partial().extend({
  id: z.string(),
});
```

### 공통 필드 merge

```typescript
const timestampSchema = z.object({
  createdAt: z.string(),
  updatedAt: z.string(),
});

const userSchema = z.object({
  id: z.string(),
  name: z.string(),
}).merge(timestampSchema);
```
