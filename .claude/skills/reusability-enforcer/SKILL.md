---
name: reusability-enforcer
description: 코드 작성 전 기존 재사용 가능 모듈을 자동 검색하고 제안합니다. Major/Minor 워크플로우 시작 시 자동 실행되어 재사용성을 강제합니다.
allowed-tools: [Read, Grep, Glob]
activation: |
  - /triage 실행 후 Major/Minor 워크플로우 진입 시
  - 새 컴포넌트/기능 구현 전
  - "재사용 가능한 모듈이 있는지" 질문 시
---

# Reusability Enforcer Skill

## 핵심 목표
코드 작성 **전에** 기존 재사용 가능 모듈을 찾아 활용하도록 강제하는 시스템

## 실행 프로세스

### 1. 작업 분석 단계
```bash
# 작업 요구사항 파싱
- 구현하려는 기능 타입 식별
- 유사한 기능이 이미 있을 가능성 평가
- 필요한 패턴 종류 파악 (API, 상태관리, UI 등)
```

### 2. 기존 패턴 검색 단계

#### 2.1 API 호출 패턴 검색
```bash
# API 호출 방식 파악
grep -r "fetch\|axios\|XMLHttpRequest" src/ | head -10
grep -r "async.*function.*api\|async.*function.*get\|async.*function.*post" src/

# 에러 처리 패턴
grep -r "catch\|.error\|handleError" src/ | head -10

# 응답 처리 패턴
grep -r "response\.json\|response\.data" src/ | head -10
```

#### 2.2 상태 관리 패턴 검색
```bash
# 상태 관리 도구 파악
grep -r "useState\|useReducer\|zustand\|redux\|mobx\|recoil" src/ | head -10

# 전역 상태 패턴
grep -r "createStore\|Provider\|useStore" src/ | head -10
```

#### 2.3 폼 처리 패턴 검색
```bash
# 폼 라이브러리 사용 여부
grep -r "react-hook-form\|formik\|handleSubmit" src/ | head -10

# 검증 패턴
grep -r "validate\|validation\|schema\|yup\|zod" src/ | head -10
```

#### 2.2 Entities 레이어 검색
```bash
# 도메인 컴포넌트 검색
find src/entities -name "*.tsx" -type f | head -20
grep -r "export.*function.*Card" src/entities/*/ui/
grep -r "export.*function.*Info" src/entities/*/ui/

# 도메인 유틸리티 검색
grep -r "export.*function format" src/entities/*/lib/
grep -r "export.*function validate" src/entities/*/lib/
```

#### 2.3 Features 레이어 검색
```bash
# 유사 기능 패턴 검색
find src/features -name "*Form.tsx" -type f | head -20
find src/features -name "*Modal.tsx" -type f | head -20
grep -r "useForm\|useQuery\|useMutation" src/features/
```

#### 2.4 NestJS Backend 패턴 검색

**중요:** 백엔드 경로는 자동 감지됩니다 (apps/api/src, backend/src, server/src 등)

**통합 CLI 사용:**
```bash
# 재사용성 검사 메인 스크립트
bash .claude/lib/reusability/reusability-checker.sh -e backend -t all "<검색어>"

# 백엔드만 검색
bash .claude/lib/reusability/reusability-checker.sh -e backend -t service "Auth"
bash .claude/lib/reusability/reusability-checker.sh -e backend -t prisma "User"
```

**수동 검색 (필요시):**
```bash
# 백엔드 경로 자동 감지
source .claude/lib/reusability/detect-architecture.sh
BACKEND_PATH=$(detect_backend_path 2>/dev/null)

# @Injectable 서비스 검색
grep -r "@Injectable()" "$BACKEND_PATH" --include="*.service.ts"

# @Controller 검색
grep -r "@Controller(" "$BACKEND_PATH" --include="*.controller.ts"

# 서비스 메서드 검색
grep -r "async.*function" "$BACKEND_PATH" --include="*.service.ts"

# DTO 클래스 검색
find "$BACKEND_PATH" -name "*.dto.ts" -type f

# class-validator 데코레이터
grep -r "@Is(String|Number|Email|Optional)" "$BACKEND_PATH" --include="*.dto.ts"

# Prisma Schema model 검색
find . -name "schema.prisma" -type f
grep "^model " prisma/schema.prisma 2>/dev/null

# Prisma Client 사용
grep -r "prisma\." "$BACKEND_PATH" --include="*.service.ts" | grep -E "(findMany|findUnique|create|update)"

# PrismaService injection
grep -r "constructor.*PrismaService" "$BACKEND_PATH" --include="*.service.ts"
```

#### 2.5 Capacitor 플러그인 검색

**통합 CLI 사용:**
```bash
# Capacitor 플러그인 검색
bash .claude/lib/reusability/reusability-checker.sh -e mobile -t function "Camera"
```

**수동 검색 (필요시):**
```bash
# Capacitor 플러그인 import 검색
grep -r "from '@capacitor" src/ --include="*.ts" --include="*.tsx" -n | head -20

# Capacitor API 사용
grep -r "Capacitor\.\|Plugins\." src/ --include="*.ts" --include="*.tsx" -n | head -20

# 커스텀 플러그인 훅
grep -r "use.*Camera\|use.*Filesystem" src/ --include="*.ts" --include="*.tsx" | grep -i "capacitor"

# 플러그인 래퍼 함수
grep -r "export.*function" src/shared/lib/capacitor --include="*.ts" -n
```

### 3. 유사도 분석 단계

#### 3.1 컴포넌트 유사도 (80% 이상 일치 시 재사용)
```markdown
## 유사도 체크리스트
- [ ] Props 구조 60% 이상 일치
- [ ] 렌더링 패턴 유사
- [ ] 이벤트 핸들러 유사
- [ ] 스타일링 방식 동일
```

#### 3.2 함수 유사도
```markdown
## 함수 재사용 기준
- [ ] 입력 파라미터 타입 호환
- [ ] 반환 타입 일치
- [ ] 로직 80% 이상 동일
- [ ] 사이드 이펙트 없음 (순수 함수)
```

### 4. 패턴 분석 리포트 생성

```markdown
# 기존 패턴 분석 리포트

## 🔍 발견된 패턴들

### API 호출 패턴
- **사용 중인 도구**: fetch (또는 axios, 프로젝트에 따라 다름)
- **에러 처리**: try-catch 블록 사용
- **응답 변환**: response.json() 사용
- **예시 코드**:
  ```typescript
  // 기존 패턴 발견 - 이 방식을 그대로 따라야 함
  async function fetchData() {
    try {
      const response = await fetch('/api/data');
      return await response.json();
    } catch (error) {
      console.error('API Error:', error);
    }
  }
  ```

### 상태 관리 패턴
- **사용 중인 방식**: useState + Context (또는 zustand, redux 등)
- **패턴**: 로컬 상태는 useState, 전역은 Context
- **네이밍**: useXXXStore 형식

### 폼 처리 패턴
- **사용 중인 도구**: 수동 처리 (또는 react-hook-form, formik 등)
- **검증 방식**: 커스텀 validation 함수
- **제출 패턴**: handleSubmit 함수명 사용

## 📋 적용 가이드

✅ **필수: 위 패턴들을 정확히 따라 구현**
- API 호출은 발견된 패턴과 동일하게
- 상태 관리도 기존 방식 그대로
- 새로운 "더 나은" 방법 도입 금지

⚠️ **주의: 일관성이 최우선**
- 성능 개선보다 일관성이 중요
- 최신 트렌드보다 기존 패턴이 중요
```

### 5. 재사용성 체크리스트 적용

새 모듈 작성이 필요한 경우:

```markdown
## 재사용성 설계 체크리스트

### 필수 확인 사항
- [ ] 2회 이상 사용 예상되는가?
- [ ] 도메인 독립적으로 설계 가능한가?
- [ ] Props/파라미터 10개 이하인가?
- [ ] 테스트 독립적으로 가능한가?
- [ ] 단일 책임 원칙을 따르는가?

### 배치 결정
- 3+ features 사용 → `shared/`
- 도메인 독립적 → `shared/lib/`
- 도메인 특정 (순수) → `entities/{domain}/`
- 비즈니스 로직 → `features/{action}/`

### 문서화 요구사항
- [ ] JSDoc 주석 작성
- [ ] @example 태그 포함
- [ ] Props/파라미터 설명
- [ ] 반환값 설명
```

## 실행 예시

### 시나리오 1: Button 컴포넌트 필요
```bash
User: "제출 버튼을 만들어줘"

[자동 실행]
1. Searching shared/ui for existing button components...
   ✓ Found: shared/ui/Button/Button.tsx

2. Analyzing compatibility...
   - Props match: 100%
   - Can use variant="primary"

3. Recommendation:
   ```tsx
   import { Button } from '@/shared/ui/Button';

   <Button variant="primary" onClick={handleSubmit}>
     제출
   </Button>
   ```
```

### 시나리오 2: Date formatting 필요
```bash
User: "날짜를 'YYYY년 MM월 DD일' 형식으로 표시해줘"

[자동 실행]
1. Searching shared/lib for date utilities...
   ✓ Found: shared/lib/dates/formatDate.ts

2. Checking format support...
   - Current formats: 'YYYY-MM-DD', 'MM/DD/YYYY'
   - Needed format: Custom Korean format

3. Recommendation:
   - Extend formatDate function with new format
   - Or create formatKoreanDate wrapper
   ```tsx
   import { formatDate } from '@/shared/lib/dates';

   export const formatKoreanDate = (date: Date) => {
     return formatDate(date, 'YYYY년 MM월 DD일');
   };
   ```
```

### 시나리오 3: 새 Form 컴포넌트 필요
```bash
User: "주문 생성 폼을 만들어줘"

[자동 실행]
1. Searching for existing form components...
   ✓ Found: shared/ui/Form/Form.tsx (generic)
   ✓ Found: features/user-registration/RegistrationForm.tsx

2. Analyzing reusability...
   - Generic Form: 40% match (too generic)
   - RegistrationForm: 30% match (different domain)

3. Recommendation:
   - Create new: features/order-create/ui/CreateOrderForm.tsx
   - Reuse from shared:
     * Button component
     * Input component
     * DatePicker component
     * Form validation utilities

4. Applying reusability checklist...
   - Will be used 2+ times? No (order-create only)
   - Domain-agnostic? No (order-specific)
   - Decision: Keep in features/order-create/
```

### 시나리오 4: NestJS 서비스 필요
```bash
User: "사용자 인증 서비스를 만들어줘"

[자동 실행]
1. Running reusability check...
   $ bash .claude/lib/reusability/reusability-checker.sh -e backend -t service Auth

2. Found existing patterns:
   ✓ AuthService: backend/src/auth/auth.service.ts (95% match)
   ✓ PrismaService injection pattern
   ✓ JWT token generation pattern

3. Recommendation:
   ✅ REUSE (95%): backend/src/auth/auth.service.ts
   - Already implements login/logout/refresh
   - Uses Prisma for user queries
   - JWT token handling included

4. Action:
   - Use existing AuthService
   - Extend if additional methods needed
```

### 시나리오 5: Prisma Model 필요
```bash
User: "Order 엔티티를 추가해줘"

[자동 실행]
1. Searching Prisma schema...
   $ bash .claude/lib/reusability/reusability-checker.sh -e backend -t prisma Order

2. Analyzing schema.prisma:
   ✓ Found: User, Product models
   ✗ Not found: Order model

3. Pattern analysis:
   - User model pattern: id, createdAt, updatedAt fields
   - Naming: camelCase for fields
   - Relations: @relation decorator

4. Recommendation:
   🆕 CREATE new model following existing pattern:
   ```prisma
   model Order {
     id        String   @id @default(uuid())
     userId    String
     user      User     @relation(fields: [userId], references: [id])
     status    String
     createdAt DateTime @default(now())
     updatedAt DateTime @updatedAt
   }
   ```
```

### 시나리오 6: Capacitor 플러그인 사용
```bash
User: "카메라로 사진을 찍는 기능을 추가해줘"

[자동 실행]
1. Searching Capacitor plugins...
   $ bash .claude/lib/reusability/reusability-checker.sh -e mobile -t function Camera

2. Found existing wrappers:
   ✓ useCameraPlugin: src/shared/lib/capacitor/useCameraPlugin.ts (90% match)
   ✓ Permission handling included
   ✓ Error handling included

3. Recommendation:
   ✅ REUSE (90%): src/shared/lib/capacitor/useCameraPlugin.ts
   ```tsx
   import { useCameraPlugin } from '@/shared/lib/capacitor';

   const { takePhoto, error } = useCameraPlugin();
   const photo = await takePhoto({ quality: 90 });
   ```

4. Action:
   - Use existing hook
   - No new implementation needed
```

## 메트릭 수집

추적할 지표:
```yaml
metrics:
  searches_performed: count
  modules_found: count
  modules_reused: count
  new_modules_created: count
  duplication_prevented: lines_of_code
  reuse_rate: (modules_reused / total_modules) * 100
```

## 통합 포인트

### 1. /triage 명령과 통합
```markdown
/triage 실행 시:
1. 작업 복잡도 분석
2. 워크플로우 선택
3. **[자동] reusability-enforcer 실행**
4. 재사용 가능 모듈 리스트 제공
```

### 2. Agent와 통합
- `test-guardian`: 테스트 유틸리티 재사용
- `api-designer`: httpClient 패턴 재사용
- `fsd-architect`: 컴포넌트 배치 규칙 적용

### 3. 다른 Skill과 연동
- `fsd-component-creation`: 템플릿에 import 자동 추가
- `api-integration`: 기존 API 패턴 활용
- `form-validation`: 검증 스키마 재사용

## 성공 지표

- **재사용률 목표**: 60% 이상
- **중복 코드 감소**: 40% 이상
- **개발 시간 단축**: 30% 이상
- **일관성 향상**: 95% 이상

## 예외 처리

재사용성 검사를 건너뛸 수 있는 경우:
- `prototype` 태그가 있는 코드
- 긴급 hotfix
- 일회성 마이그레이션 스크립트
- 외부 API 특정 어댑터

단, 모든 예외는 문서화되어야 함:
```typescript
/**
 * @prototype
 * @skip-reusability-check
 * Reason: 실험적 기능으로 추후 리팩토링 예정
 */
```