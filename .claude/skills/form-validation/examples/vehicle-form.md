# 차량 정보 폼 예시

차량 정보 입력 및 검증 폼 예시입니다.

## Zod 스키마

```typescript
// features/vehicle/model/schema.ts
import { z } from 'zod';

export const vehicleSchema = z.object({
  type: z.enum(['냉장', '냉동', '건식', '탑차'], {
    required_error: '차량 종류를 선택하세요',
  }),
  ton: z.enum(['1톤', '2.5톤', '5톤', '11톤'], {
    required_error: '톤수를 선택하세요',
  }),
  plateNumber: z.string().regex(
    /^\d{2}[가-힣]\d{4}$/,
    '올바른 차량번호를 입력하세요 (예: 12가3456)'
  ),
  hasGPS: z.boolean().default(false),
  gpsDeviceId: z.string().optional(),
}).refine(
  (data) => !data.hasGPS || !!data.gpsDeviceId,
  {
    message: 'GPS 기기 ID를 입력하세요',
    path: ['gpsDeviceId'],
  }
);

export type VehicleInput = z.infer<typeof vehicleSchema>;
```

## Feature 컴포넌트

```typescript
// features/vehicle/ui/VehicleForm.tsx
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { vehicleSchema } from '../model/schema';
import type { VehicleInput } from '../model/schema';

export function VehicleForm({ onSubmit }: { onSubmit: (data: VehicleInput) => void }) {
  const {
    register,
    handleSubmit,
    watch,
    formState: { errors },
  } = useForm<VehicleInput>({
    resolver: zodResolver(vehicleSchema),
    defaultValues: {
      hasGPS: false,
    },
  });

  const hasGPS = watch('hasGPS');

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <div>
        <label>차량 종류</label>
        <select {...register('type')}>
          <option value="">선택</option>
          <option value="냉장">냉장</option>
          <option value="냉동">냉동</option>
          <option value="건식">건식</option>
          <option value="탑차">탑차</option>
        </select>
        {errors.type && <span>{errors.type.message}</span>}
      </div>

      <div>
        <label>톤수</label>
        <select {...register('ton')}>
          <option value="">선택</option>
          <option value="1톤">1톤</option>
          <option value="2.5톤">2.5톤</option>
          <option value="5톤">5톤</option>
          <option value="11톤">11톤</option>
        </select>
        {errors.ton && <span>{errors.ton.message}</span>}
      </div>

      <div>
        <label>차량번호</label>
        <input {...register('plateNumber')} placeholder="12가3456" />
        {errors.plateNumber && <span>{errors.plateNumber.message}</span>}
      </div>

      <div>
        <label>
          <input type="checkbox" {...register('hasGPS')} />
          GPS 장착
        </label>
      </div>

      {hasGPS && (
        <div>
          <label>GPS 기기 ID</label>
          <input {...register('gpsDeviceId')} />
          {errors.gpsDeviceId && <span>{errors.gpsDeviceId.message}</span>}
        </div>
      )}

      <button type="submit">저장</button>
    </form>
  );
}
```
