# 주소 입력 폼 예시

주소 검색 및 입력 기능이 포함된 완전한 폼 예시입니다.

## Zod 스키마

```typescript
// features/address/model/schema.ts
import { z } from 'zod';

export const addressSchema = z.object({
  zipCode: z.string().regex(/^\d{5}$/, '우편번호 5자리를 입력하세요'),
  address: z.string().min(1, '주소를 입력하세요'),
  detailAddress: z.string().optional(),
  latitude: z.number().optional(),
  longitude: z.number().optional(),
});

export type AddressInput = z.infer<typeof addressSchema>;
```

## Feature 컴포넌트

```typescript
// features/address/ui/AddressForm.tsx
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { addressSchema } from '../model/schema';
import type { AddressInput } from '../model/schema';

export function AddressForm({ onSubmit }: { onSubmit: (data: AddressInput) => void }) {
  const {
    register,
    handleSubmit,
    setValue,
    formState: { errors },
  } = useForm<AddressInput>({
    resolver: zodResolver(addressSchema),
  });

  const handleAddressSearch = () => {
    // Kakao 주소 검색 API
    new daum.Postcode({
      oncomplete: (data: any) => {
        setValue('zipCode', data.zonecode);
        setValue('address', data.address);
        // 좌표 변환 API 호출 (선택)
      },
    }).open();
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <div>
        <label>우편번호</label>
        <input {...register('zipCode')} readOnly />
        <button type="button" onClick={handleAddressSearch}>
          주소 검색
        </button>
        {errors.zipCode && <span>{errors.zipCode.message}</span>}
      </div>

      <div>
        <label>주소</label>
        <input {...register('address')} readOnly />
        {errors.address && <span>{errors.address.message}</span>}
      </div>

      <div>
        <label>상세주소</label>
        <input {...register('detailAddress')} placeholder="상세주소를 입력하세요" />
      </div>

      <button type="submit">저장</button>
    </form>
  );
}
```
