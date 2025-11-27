# Minor 워크플로우 - 문제 해결

## 목차

1. [일반적인 오류](#일반적인-오류)
2. [범위 및 복잡도 문제](#범위-및-복잡도-문제)
3. [재사용성 검증 실패](#재사용성-검증-실패)
4. [Quality Gate 실패](#quality-gate-실패)
5. [문서 생성 문제](#문서-생성-문제)
6. [테스트 관련 문제](#테스트-관련-문제)
7. [Constitution 위반](#constitution-위반)
8. [성능 및 토큰 문제](#성능-및-토큰-문제)

---

## 일반적인 오류

### 1. "Scope too large for Minor"

**증상:**
```
❌ Error: Scope too large for Minor workflow
Complexity: 9/15 (Major threshold: 8+)
Recommendation: Use /plan-major instead
```

**원인:**
- 수정 범위가 8개 이상 파일에 영향
- 아키텍처 변경이 필요한 경우
- 새로운 Entity나 Feature 추가가 필요한 경우

**해결 방법:**

**방법 1: Major 워크플로우 사용**
```bash
/plan-major
# 문서 생성 후
/implement
```
더 큰 범위의 작업에 적합한 Major 워크플로우로 전환

**방법 2: 작업 범위 축소**
문제를 더 작은 단위로 분해:
```bash
# 나쁜 예
"전체 인증 시스템 리팩토링"

# 좋은 예
"로그인 폼 검증 로직 개선"
"비밀번호 재설정 버그 수정"
"토큰 갱신 로직 최적화"
```

**방법 3: Triage로 복잡도 먼저 확인**
```bash
/triage "작업 설명"
# → 복잡도 분석 후 적절한 워크플로우 추천받기
```

---

### 2. "Issue description too vague"

**증상:**
```
⚠️ Warning: Issue description is not specific enough
Please provide:
- Concrete error messages
- Steps to reproduce
- Expected vs actual behavior
```

**원인:**
- 이슈 설명이 너무 추상적
- 구체적인 증상이나 에러 메시지 누락
- 재현 단계 미제공

**해결 방법:**

**좋은 이슈 설명 작성:**
```bash
/plan-minor
```

**대화 과정:**
```
어떤 문제를 수정하시나요?
> 로그인 폼에서 빈 이메일 제출 시 null pointer 에러 발생

증상이나 에러를 설명해주세요:
> 에러 메시지: "Cannot read property 'toLowerCase' of null"
> 발생 위치: LoginForm.tsx:42
> 재현 단계:
> 1. 로그인 페이지 접속
> 2. 이메일 필드를 비운 상태로 제출
> 3. 콘솔에 에러 발생
> 예상 동작: "Email is required" 검증 메시지 표시
> 실제 동작: 앱 크래시
```

**나쁜 예:**
```
어떤 문제를 수정하시나요?
> 로그인이 안돼요

증상이나 에러를 설명해주세요:
> 그냥 안돼요
```

---

### 3. "Cannot find root cause"

**증상:**
```
⚠️ Warning: Unable to identify root cause
Please verify:
- Correct file paths mentioned
- Error stack trace provided
- Recent changes described
```

**원인:**
- 코드베이스에서 관련 파일을 찾지 못함
- 에러 스택 트레이스 미제공
- 잘못된 파일 경로 제공

**해결 방법:**

**방법 1: 정확한 파일 경로 제공**
```bash
# 나쁜 예
"LoginForm에서 에러 발생"

# 좋은 예
"src/features/auth/ui/LoginForm.tsx:42에서 에러 발생"
```

**방법 2: 전체 스택 트레이스 제공**
```
에러 스택:
TypeError: Cannot read property 'toLowerCase' of null
    at LoginForm.tsx:42:28
    at handleSubmit (LoginForm.tsx:38:5)
    at onClick (Button.tsx:12:3)
```

**방법 3: 최근 변경사항 언급**
```
최근 변경:
- 어제 이메일 검증 로직 수정함
- formik에서 react-hook-form으로 마이그레이션 중
```

---

## 범위 및 복잡도 문제

### 4. "Too many files affected"

**증상:**
```
⚠️ Warning: 12 files will be affected
Minor workflow is optimized for 1-4 files
Consider using /plan-major for better organization
```

**원인:**
- 변경이 여러 파일에 걸쳐 있음
- 크로스 레이어 변경 필요
- 여러 Feature에 영향

**해결 방법:**

**방법 1: 핵심 파일만 수정**
```markdown
# 현재 계획 (12개 파일)
- LoginForm.tsx
- RegisterForm.tsx
- ProfileForm.tsx
- SettingsForm.tsx
- ... 8 more files

# 축소된 계획 (2개 파일)
- LoginForm.tsx (핵심 수정)
- LoginForm.test.tsx (테스트)

# 나머지는 별도 Minor 작업으로
```

**방법 2: Major 워크플로우로 전환**
```bash
/plan-major
# 여러 파일에 걸친 체계적인 리팩토링 계획
/implement
# 계획에 따라 구현
```

**방법 3: 여러 Minor 작업으로 분할**
```bash
# 작업 1: 로그인 폼
/plan-minor "로그인 폼 검증 개선"
/implement

# 작업 2: 회원가입 폼
/plan-minor "회원가입 폼 검증 개선"
/implement

# 작업 3: 공통 유틸리티
/plan-minor "폼 검증 유틸리티 추출"
/implement
```

---

### 5. "Breaking changes detected"

**증상:**
```
❌ Error: Breaking changes not allowed in Minor workflow
Detected:
- Function signature changed: validateEmail(email) → validateEmail(email, options)
- Public API modified: AuthService.login()
- Interface changed: User.email type
```

**원인:**
- 기존 함수의 시그니처 변경
- Public API 수정
- 인터페이스 또는 타입 변경
- 하위 호환성 깨짐

**해결 방법:**

**방법 1: 하위 호환성 유지**
```typescript
// ❌ Breaking change
function validateEmail(email: string, options: ValidateOptions) {
  // 기존 호출: validateEmail(email) - 에러 발생!
}

// ✅ 하위 호환
function validateEmail(email: string, options?: ValidateOptions) {
  // 기존 호출: validateEmail(email) - 정상 작동
  // 새 호출: validateEmail(email, {...}) - 정상 작동
}
```

**방법 2: 새 함수 추가 (Deprecation 패턴)**
```typescript
// ✅ 기존 함수 유지
/** @deprecated Use validateEmailWithOptions instead */
function validateEmail(email: string) {
  return validateEmailWithOptions(email);
}

// ✅ 새 함수 추가
function validateEmailWithOptions(email: string, options?: ValidateOptions) {
  // 새로운 로직
}
```

**방법 3: Major 워크플로우로 전환**
```bash
# Breaking change가 정말 필요한 경우
/major
# Major에서는 Breaking change 허용 (적절한 마이그레이션 계획과 함께)
```

---

### 6. "Feature addition requires Major"

**증상:**
```
⚠️ Detected: New feature addition
Recommendation: Use /major for:
- New page/route
- New entity/model
- New API endpoint
```

**원인:**
- 완전히 새로운 기능 추가
- 새 페이지나 라우트 생성
- 새 Entity 정의
- 새 API 엔드포인트

**해결 방법:**

**Minor에 적합한 기능:**
```bash
# ✅ Minor 적합
- 기존 폼에 필드 추가
- 기존 페이지에 버튼 추가
- 기존 리스트에 필터 추가
- 기존 데이터에 정렬 기능
```

**Major가 필요한 기능:**
```bash
# ❌ Minor 부적합 → /major 사용
- 새 사용자 프로필 페이지
- 새 결제 시스템
- 새 채팅 기능
- 새 알림 시스템
```

---

## 재사용성 검증 실패

### 7. "Reusability check failed"

**증상:**
```
❌ Reusability Enforcement Failed
Found existing utilities that should be reused:
✗ Creating new emailValidator
  → Use: src/shared/lib/validation/emailValidator.ts

✗ Implementing custom date formatter
  → Use: src/shared/lib/date/formatDate.ts
```

**원인:**
- 기존 유틸리티를 재사용하지 않고 새로 작성
- reusability-enforcer가 발견한 패턴 무시
- 중복 코드 생성

**해결 방법:**

**방법 1: 제안된 유틸리티 사용**
```typescript
// ❌ 재사용 실패 (새로 작성)
const validateEmail = (email: string) => {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
};

// ✅ 재사용 성공
import { validateEmail } from '@/shared/lib/validation';

// 기존 유틸리티 활용
```

**방법 2: 기존 유틸리티 확장**
```typescript
// ✅ 기존 유틸리티에 새 기능 추가
// src/shared/lib/validation/emailValidator.ts
export function validateEmail(email: string): boolean {
  // 기존 로직
}

// 새로운 옵션 추가 (하위 호환)
export function validateEmailStrict(email: string, options?: StrictOptions): boolean {
  // 확장된 검증
}
```

**방법 3: 정당한 이유 문서화**
기존 유틸리티를 사용할 수 없는 명확한 이유가 있는 경우:
```markdown
## Why not reuse existing emailValidator?

기존 emailValidator는 RFC 5322 표준을 완전히 구현하지 않음
이번 기능은 엔터프라이즈 고객용으로 완전한 RFC 5322 준수 필요

→ 새로운 emailValidatorRFC5322 구현 (기존과 별도)
```

---

### 8. "Pattern not followed"

**증상:**
```
⚠️ Pattern inconsistency detected
Similar code in RegisterForm uses:
  → formik + Zod validation

Your implementation uses:
  → react-hook-form + custom validation

Recommendation: Follow existing pattern
```

**원인:**
- 기존 코드베이스의 패턴과 다른 접근 방식 사용
- 일관성 없는 라이브러리 선택
- 다른 팀원의 코드와 스타일 불일치

**해결 방법:**

**방법 1: 기존 패턴 따르기**
```typescript
// ✅ RegisterForm 패턴 참고
// RegisterForm.tsx에서 사용하는 것과 동일한 방식
import { useFormik } from 'formik';
import { loginSchema } from '../model/schemas';

const formik = useFormik({
  validationSchema: loginSchema,
  // ...
});
```

**방법 2: Constitution 확인**
```bash
# 프로젝트 규칙 확인
cat .specify/memory/constitution.md

# Form handling 섹션 찾기
# "모든 폼은 formik + Zod 사용" 같은 규칙 확인
```

**방법 3: 팀 컨벤션 문서화**
새로운 패턴이 정말 더 나은 경우:
```markdown
# RFC: FormHandler 패턴 변경 제안

## 현재 패턴
- formik + Zod (5개 폼에서 사용)

## 제안 패턴
- react-hook-form + Zod (더 나은 성능, 작은 번들 크기)

## 마이그레이션 계획
1. 새 폼부터 적용
2. 기존 폼 점진적 마이그레이션
3. Constitution 업데이트

→ 이 경우 /major 사용 권장
```

---

## Quality Gate 실패

### 9. "Related tests must pass"

**증상:**
```
❌ Quality Gate Failed: Related tests
Failed tests:
✗ LoginForm.test.tsx: should validate email
✗ LoginForm.test.tsx: should show error on invalid input
✗ authService.test.tsx: should handle login

2/5 tests failed
```

**원인:**
- 수정으로 인해 기존 테스트 깨짐
- 테스트 업데이트 누락
- 예상치 못한 부작용

**해결 방법:**

**방법 1: 테스트 업데이트**
```typescript
// ❌ 깨진 테스트
it('should validate email', () => {
  // 이전: validateEmail(email)
  expect(validateEmail('test@example.com')).toBe(true);
});

// ✅ 수정된 테스트
it('should validate email', () => {
  // 새로운 API: validateEmail(email, options)
  expect(validateEmail('test@example.com')).toBe(true);
  expect(validateEmail('test@example.com', { strict: true })).toBe(true);
});
```

**방법 2: 테스트 실행 및 디버깅**
```bash
# 관련 테스트만 실행
npm test -- LoginForm.test.tsx

# Watch 모드로 실행
npm test -- --watch LoginForm.test.tsx

# 디버그 모드
npm test -- --inspect-brk LoginForm.test.tsx
```

**방법 3: 회귀 테스트 추가**
```typescript
// 새로운 테스트 추가
describe('Email validation edge cases', () => {
  it('should handle null email', () => {
    expect(validateEmail(null)).toBe(false);
  });

  it('should handle empty string', () => {
    expect(validateEmail('')).toBe(false);
  });

  it('should handle undefined', () => {
    expect(validateEmail(undefined)).toBe(false);
  });
});
```

---

### 10. "Constitution compliance failed"

**증상:**
```
❌ Constitution Compliance Failed

Violations detected:
✗ FSD Layer violation
  features/auth/ui importing from features/profile/model

✗ Public API bypass
  Direct import: features/auth/model/types
  Should use: features/auth (index.ts)

✗ Wrong layer
  Business logic in UI component
  Should be in: model/ layer
```

**원인:**
- FSD 레이어 규칙 위반
- 잘못된 import 경로
- 레이어 책임 분리 미준수

**해결 방법:**

**방법 1: Public API 사용**
```typescript
// ❌ 잘못된 import
import { User } from '@/features/auth/model/types';

// ✅ 올바른 import
import { User } from '@/features/auth';
// features/auth/index.ts에서 export된 것 사용
```

**방법 2: 올바른 레이어에 코드 배치**
```typescript
// ❌ UI에 비즈니스 로직
// LoginForm.tsx
const LoginForm = () => {
  const handleLogin = (email, password) => {
    // 복잡한 검증 로직 (비즈니스 로직)
    if (!email.match(/regex/)) { ... }
    if (password.length < 8) { ... }
    // API 호출
    await api.login(email, password);
  };
};

// ✅ model 레이어로 이동
// model/useLogin.ts
export const useLogin = () => {
  const login = async (email: string, password: string) => {
    // 검증 로직
    // API 호출
  };
  return { login };
};

// ui/LoginForm.tsx
const LoginForm = () => {
  const { login } = useLogin();
  const handleLogin = () => login(email, password);
};
```

**방법 3: Cross-Feature Import 수정**
```typescript
// ❌ Feature 간 직접 import (로직)
import { getUserProfile } from '@/features/profile/model';

// ✅ Type-only import는 허용 (Custom FSD)
import type { UserProfile } from '@/features/profile';

// ✅ 로직은 shared로 추출
// shared/lib/user/getUserProfile.ts
export const getUserProfile = () => { ... };

// 또는 API를 통해 통신
import { api } from '@/shared/api';
const profile = await api.users.getProfile(userId);
```

---

### 11. "No breaking changes allowed"

**증상:**
```
❌ Breaking Changes Detected

Public API changes:
✗ authService.login(email, password)
  → authService.login(credentials)
  Impact: 15 files using this API

✗ User.email: string
  → User.email: Email (custom type)
  Impact: 23 files
```

**원인:**
- Minor에서 Breaking change 시도
- API 시그니처 변경
- 타입 변경

**해결 방법:**

**방법 1: 오버로드 사용**
```typescript
// ✅ 하위 호환 유지
interface AuthService {
  // 기존 시그니처 유지
  login(email: string, password: string): Promise<User>;

  // 새 시그니처 추가
  login(credentials: LoginCredentials): Promise<User>;
}

// 구현
login(emailOrCredentials: string | LoginCredentials, password?: string) {
  if (typeof emailOrCredentials === 'string') {
    // 기존 방식 (deprecated but working)
    return this._login(emailOrCredentials, password!);
  } else {
    // 새 방식
    return this._login(emailOrCredentials.email, emailOrCredentials.password);
  }
}
```

**방법 2: Adapter 패턴**
```typescript
// ✅ 기존 함수를 wrapper로 유지
export function login(email: string, password: string) {
  return loginWithCredentials({ email, password });
}

export function loginWithCredentials(credentials: LoginCredentials) {
  // 새로운 구현
}
```

**방법 3: Major로 전환**
Breaking change가 정말 필요한 경우:
```bash
/major
# Major에서는 Breaking change 허용
# 단, 마이그레이션 가이드 필수
```

---

## 문서 생성 문제

### 12. "fix-analysis.md too brief"

**증상:**
```
⚠️ Generated fix-analysis.md seems incomplete

Missing sections:
- Root cause analysis
- Reusability recommendations
- Related tests
```

**원인:**
- 이슈 설명이 너무 짧음
- 충분한 컨텍스트 미제공
- 에러 정보 부족

**해결 방법:**

**방법 1: 더 상세한 이슈 설명**
```bash
/minor
```

**최소 정보:**
```
어떤 문제를 수정하시나요?
> [문제 한 줄 요약]

증상이나 에러를 설명해주세요:
> 에러 메시지: [전체 에러 텍스트]
> 발생 파일: [파일 경로:라인]
> 재현 단계: [1, 2, 3...]
> 예상 동작: [what should happen]
> 실제 동작: [what actually happens]
> 영향 범위: [어떤 기능이 영향받는지]
```

**방법 2: 수동으로 fix-analysis.md 보완**
```bash
# 생성된 문서 확인
cat .specify/fixes/issue-name/fix-analysis.md

# 직접 편집
code .specify/fixes/issue-name/fix-analysis.md

# 누락된 섹션 추가
```

---

### 13. "Incorrect file paths in analysis"

**증상:**
```
⚠️ fix-analysis.md references non-existent files:
✗ src/components/LoginForm.tsx (not found)
✗ src/utils/validation.ts (not found)
```

**원인:**
- 잘못된 파일 경로 제공
- 프로젝트 구조 오해
- 파일 이동 후 경로 미업데이트

**해결 방법:**

**방법 1: 정확한 경로 확인**
```bash
# 파일 찾기
find . -name "LoginForm.tsx"

# 또는
fd LoginForm.tsx

# 결과 예:
# ./src/features/auth/ui/LoginForm.tsx
```

**방법 2: 프로젝트 구조 확인**
```bash
# Custom FSD 구조 확인
tree src/ -L 3

# 예상 구조:
# src/
# ├── app/
# ├── pages/
# ├── features/
# │   ├── auth/
# │   │   ├── ui/
# │   │   ├── model/
# │   │   └── api/
# ├── entities/
# └── shared/
```

**방법 3: fix-analysis.md 수정**
```markdown
# ❌ 잘못된 경로
Files to Change:
- src/components/LoginForm.tsx

# ✅ 올바른 경로
Files to Change:
- src/features/auth/ui/LoginForm.tsx
```

---

## 테스트 관련 문제

### 14. "Related tests not found"

**증상:**
```
⚠️ Warning: No related tests found for:
- src/features/auth/ui/LoginForm.tsx

Recommendation:
- Add tests before fixing
- Or use /micro if tests not needed
```

**원인:**
- 수정할 파일에 테스트가 없음
- 테스트 파일 명명 규칙 불일치
- 테스트가 다른 위치에 있음

**해결 방법:**

**방법 1: 테스트 먼저 작성 (TDD)**
```bash
# 1. 테스트 작성
code src/features/auth/ui/LoginForm.test.tsx

# 2. 테스트 실행 (실패 확인)
npm test LoginForm.test.tsx

# 3. 수정 구현
code src/features/auth/ui/LoginForm.tsx

# 4. 테스트 통과 확인
npm test LoginForm.test.tsx
```

**방법 2: fix-analysis.md에 테스트 계획 명시**
```markdown
## Related Tests

현재: 테스트 없음

추가할 테스트:
- [ ] LoginForm.test.tsx 생성
- [ ] 빈 이메일 제출 테스트
- [ ] null 이메일 처리 테스트
- [ ] 에러 메시지 표시 테스트
```

**방법 3: Micro 워크플로우 사용**
테스트가 정말 불필요한 경우 (설정 파일, 스타일 등):
```bash
/micro
# Micro는 테스트 요구사항 없음
```

---

### 15. "Test coverage below threshold"

**증상:**
```
⚠️ Note: Minor workflow doesn't require full coverage

Current coverage: 45%
Only related tests must pass
```

**설명:**
- Minor는 전체 커버리지 요구 없음 (Major는 80%+)
- 관련 테스트만 통과하면 됨
- 이것은 에러가 아니라 정보성 메시지

**확인 사항:**

**관련 테스트 확인:**
```bash
# 수정한 파일의 테스트만 실행
npm test LoginForm.test.tsx

# 통과하면 OK
✓ LoginForm › should validate email
✓ LoginForm › should show error
```

**필요시 테스트 추가:**
```typescript
// 수정 관련 테스트만 추가
describe('LoginForm - Email validation', () => {
  it('should handle null email', () => { ... });
  it('should handle empty email', () => { ... });
});
```

---

## Constitution 위반

### 16. "FSD layer violation"

**증상:**
```
❌ FSD Layer Violation

features/auth/ui/LoginForm.tsx
→ importing from features/profile/model

Cross-feature imports not allowed
(except type-only imports in Custom FSD)
```

**원인:**
- Feature 간 로직 import 시도
- Custom FSD 규칙 위반

**해결 방법:**

**방법 1: Type-only import로 변경**
```typescript
// ❌ 로직 import
import { getUserProfile } from '@/features/profile/model';

// ✅ Type-only import (Custom FSD에서 허용)
import type { UserProfile } from '@/features/profile';
```

**방법 2: shared로 로직 이동**
```typescript
// ✅ 공통 로직은 shared/lib로
// shared/lib/user/profile.ts
export const getUserProfile = (userId: string) => {
  // 프로필 가져오기 로직
};

// features/auth/ui/LoginForm.tsx
import { getUserProfile } from '@/shared/lib/user';
```

**방법 3: API 통신으로 변경**
```typescript
// ✅ Feature 간 통신은 API를 통해
import { api } from '@/shared/api';

const profile = await api.users.getProfile(userId);
```

---

### 17. "Public API bypass"

**증상:**
```
❌ Public API Bypass Detected

Direct import:
import { LoginFormProps } from '@/features/auth/ui/LoginForm'

Should use:
import { LoginFormProps } from '@/features/auth'
```

**원인:**
- 내부 모듈 직접 import
- index.ts 우회

**해결 방법:**

**방법 1: Public API 사용**
```typescript
// ❌ 내부 직접 접근
import { User } from '@/features/auth/model/types';
import { loginApi } from '@/features/auth/api/login';

// ✅ Public API 사용
import { User, loginApi } from '@/features/auth';
```

**방법 2: index.ts 확인 및 추가**
```typescript
// features/auth/index.ts
// export 누락된 항목 추가

export { User } from './model/types';
export { loginApi } from './api/login';
export { LoginForm } from './ui/LoginForm';
export type { LoginFormProps } from './ui/LoginForm';
```

---

### 18. "Wrong layer responsibility"

**증상:**
```
❌ Layer Responsibility Violation

Business logic found in UI component:
src/features/auth/ui/LoginForm.tsx:42-67

Should be moved to:
src/features/auth/model/
```

**원인:**
- UI 컴포넌트에 비즈니스 로직 포함
- 레이어 책임 분리 미준수

**해결 방법:**

**방법 1: 비즈니스 로직을 model로 이동**
```typescript
// ❌ UI에 로직
// ui/LoginForm.tsx
const LoginForm = () => {
  const handleLogin = async (email: string, password: string) => {
    // 검증
    if (!email.includes('@')) {
      setError('Invalid email');
      return;
    }

    // API 호출
    const response = await fetch('/api/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    });

    // 상태 업데이트
    if (response.ok) {
      setUser(await response.json());
    }
  };
};

// ✅ model로 분리
// model/useLogin.ts
export const useLogin = () => {
  const [error, setError] = useState('');
  const [user, setUser] = useState(null);

  const login = async (email: string, password: string) => {
    if (!email.includes('@')) {
      setError('Invalid email');
      return;
    }

    const response = await loginApi(email, password);
    if (response.ok) {
      setUser(response.data);
    }
  };

  return { login, error, user };
};

// ui/LoginForm.tsx
const LoginForm = () => {
  const { login, error, user } = useLogin();
  return (
    <form onSubmit={() => login(email, password)}>
      {/* UI only */}
    </form>
  );
};
```

---

## 성능 및 토큰 문제

### 19. "Token usage higher than expected"

**증상:**
```
⚠️ Token usage: 35,000
Expected for Minor: ~15,000

Possible reasons:
- Large file analysis
- Multiple reusability searches
- Complex codebase scanning
```

**원인:**
- 분석할 파일이 너무 큼
- 불필요한 재사용성 검색
- 코드베이스가 매우 큼

**해결 방법:**

**방법 1: 범위 좁히기**
```bash
# 문제가 명확하면 정확한 파일 지정
/minor

어떤 문제를 수정하시나요?
> src/features/auth/ui/LoginForm.tsx의 null pointer 버그
  (파일 경로 명시로 검색 범위 축소)
```

**방법 2: Smart-cache 활용**
```bash
# 반복 실행 시 캐시 활용
# 첫 실행: 35,000 토큰
# 두 번째: 8,000 토큰 (캐시 히트)
```

**방법 3: 간단한 수정은 Micro 사용**
```bash
# 정말 간단한 수정 (1-2줄)
/micro
# 재사용성 검색 없이 빠르게 수정
```

---

### 20. "Slow reusability search"

**증상:**
```
⏳ Reusability search taking longer than expected...
Searching codebase: 45 seconds
```

**원인:**
- 코드베이스가 매우 큼
- node_modules 포함된 검색
- 캐시 미스

**해결 방법:**

**방법 1: .gitignore 확인**
```bash
# .gitignore에 제외할 디렉토리 추가
node_modules/
dist/
build/
.next/
.cache/
```

**방법 2: 첫 실행 후 대기**
```
# 첫 실행은 느릴 수 있음 (캐시 생성)
# 이후 실행은 빠름 (70% 캐시 히트율)
```

---

### 21. "Cache not working"

**증상:**
```
⚠️ Cache miss rate: 85%
Expected: 70% hit rate

Token usage not decreasing on repeated runs
```

**원인:**
- 캐시 디렉토리 권한 문제
- 파일 경로 변경
- 캐시 무효화됨

**해결 방법:**

**방법 1: 캐시 디렉토리 확인**
```bash
# 캐시 위치 확인
ls -la .claude/cache/

# 권한 확인
ls -la .claude/cache/metrics/
ls -la .claude/cache/files/

# 권한 문제 시
chmod -R 755 .claude/cache/
```

**방법 2: 캐시 재생성**
```bash
# 캐시 삭제 및 재생성
rm -rf .claude/cache/
mkdir -p .claude/cache/{metrics,files,tests}

# 다음 실행 시 캐시 재생성됨
```

---

## 빠른 참조

### 에러 해결 체크리스트

**"Scope too large" 에러:**
```bash
□ 파일 개수 8개 미만인가?
□ 아키텍처 변경 없는가?
□ 새 Entity 추가 안하는가?
→ 아니면 /major 사용
```

**"Breaking changes" 에러:**
```bash
□ 함수 시그니처 유지했는가?
□ 타입 변경 없는가?
□ Public API 수정 없는가?
→ 하위 호환성 유지 또는 /major
```

**"Reusability failed" 에러:**
```bash
□ fix-analysis.md의 재사용 권장사항 확인했는가?
□ 기존 유틸리티 사용했는가?
□ 새 코드 작성 전 검색했는가?
→ 재사용 우선
```

**"Tests failed" 에러:**
```bash
□ 관련 테스트 업데이트했는가?
□ 새 테스트 케이스 추가했는가?
□ 회귀 테스트 통과하는가?
→ 테스트 수정/추가
```

**"Constitution violation" 에러:**
```bash
□ FSD 레이어 규칙 준수했는가?
□ Public API 사용했는가?
□ Cross-feature import 없는가?
→ Constitution 규칙 따르기
```

---

**Version**: 4.0.0
**Last Updated**: 2025-11-18
**See Also**: [minor.md](../minor.md), [minor-examples.md](minor-examples.md), [minor-document-templates.md](minor-document-templates.md)
