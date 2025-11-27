# Micro 워크플로우 - 문제 해결

## 목차

1. [자동 전환 문제](#자동-전환-문제)
2. [범위 판단 오류](#범위-판단-오류)
3. [문서 및 테스트 관련](#문서-및-테스트-관련)
4. [Breaking Changes](#breaking-changes)
5. [성능 문제](#성능-문제)
6. [일반적인 오해](#일반적인-오해)

---

## 자동 전환 문제

### 1. "자꾸 /plan-minor로 전환돼요"

**증상:**
```
⚠️ Auto-upgrading to /plan-minor
Reason: Complexity too high (4/15)
```

**원인:**
- 변경이 생각보다 복잡함
- 로직 변경이 감지됨
- 여러 파일에 영향

**해결 방법:**

**방법 1: 실제로 Minor가 맞는 경우**
```
변경이 다음 중 하나라면 Minor가 적합:
- 로직 변경
- 버그 수정
- 여러 파일 수정 (5개+)
- 테스트 필요

→ /plan-minor 사용 후 /implement 실행
```

**방법 2: 변경 범위 축소**
```bash
# ❌ Micro로 시도 (너무 넓음)
/micro
> "모든 console.log 제거하고 import 정리"

# ✅ Micro로 분할 (각각 실행)
/micro
> "console.log 제거"

/micro
> "import 정리"
```

**방법 3: 정말 trivial한지 재평가**
```bash
# ❌ Micro 부적합
"로그인 검증 개선"
→ 로직 변경이므로 /plan-minor

# ✅ Micro 적합
"로그인 폼 버튼 색상 변경"
→ 코스메틱 변경
```

---

### 2. "Minor 전환이 너무 느슨해요"

**증상:**
```
Expected: Micro로 처리
Actual: Minor로 자동 전환됨
```

**원인:**
- 복잡도 임계값이 낮게 설정됨 (3/15)
- 안전을 위한 보수적 판단

**해결 방법:**

**이해하기:**
```
Micro → Minor 자동 전환은 안전장치:
- 복잡도 > 3/15
- 로직 변경 감지
- 파일 5개 이상
- 테스트 필요

→ 이는 의도된 동작
```

**정말 Micro로 처리하려면:**
```bash
# 1. 변경 범위 명확히 하기
/micro
> "README.md 23번 라인 오타 수정만"
  (구체적으로 명시)

# 2. 한 번에 하나씩
/micro
> "config.ts timeout 값만 변경"
```

---

### 3. "Major로 전환되는 이유는?"

**증상:**
```
⚠️ Auto-upgrading to /major
Reason: Complexity too high (9/15)
```

**원인:**
- 복잡도가 Major 수준 (8+)
- 새로운 기능 추가 시도
- 아키텍처 변경 감지

**해결 방법:**

**Major가 필요한 경우:**
```bash
# ✅ 올바른 워크플로우 사용
/major

# 예시:
- 새 페이지 추가
- 새 Entity 생성
- API 엔드포인트 추가
- 대규모 리팩토링
```

**Micro/Minor로 분할 가능한 경우:**
```bash
# 큰 작업을 작은 단위로 분해

# Phase 1: 준비 작업 (Micro)
/micro
> "설정 파일 생성"

# Phase 2: 코어 구현 (Major)
/major
> "새 기능 구현"

# Phase 3: 정리 (Micro)
/micro
> "import 정리 및 주석 추가"
```

---

## 범위 판단 오류

### 4. "Micro 범위라고 생각했는데 아니었어요"

**증상:**
```
Thought: Micro (trivial change)
Reality: Minor (requires tests)
```

**원인:**
- 변경의 영향을 과소평가
- "간단해 보이는" 로직 변경
- 숨겨진 의존성

**해결 방법:**

**Micro 적합성 체크리스트:**
```
□ 코스메틱 변경인가? (로직 변경 없음)
□ 1-3개 파일만 영향?
□ 테스트 불필요?
□ 5분 이내 완료 가능?
□ 되돌리기 쉬운가?

모두 ✓ → Micro 적합
하나라도 ✗ → Minor 이상 사용
```

**일반적인 오판 사례:**

**사례 1: "간단한" 로직 변경**
```typescript
// "간단해 보이지만" Micro 부적합
// ❌ Micro 시도
const validateEmail = (email) => {
  // return email.includes('@');  // 기존
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);  // 변경
};

// 이유:
// - 검증 로직 변경 (로직 변경)
// - 버그 가능성 (테스트 필요)
// - 여러 곳에서 사용 (영향 범위 큼)

// ✅ Minor 사용
/minor "이메일 검증 로직 개선"
```

**사례 2: "단순" 설정 변경**
```javascript
// ❌ Micro 시도
// config.ts
export const CONFIG = {
  // timeout: 5000,  // 기존
  timeout: 0,  // "타임아웃 없애기"
};

// 이유:
// - 동작 변경 (무한 대기 가능)
// - 프로덕션 영향 큼
// - 테스트 필요

// ✅ Minor 사용
/minor "타임아웃 정책 변경"
```

---

### 5. "여러 파일 수정은 항상 Minor?"

**질문**: 3개 파일 수정하면 자동으로 Minor인가요?

**답변**: 아니오, 파일 개수만으로 결정되지 않음

**Micro 가능한 경우:**
```bash
# ✅ 3개 파일이지만 Micro 적합
/micro
> "3개 파일에서 오타 수정"

이유:
- 각 파일에서 독립적인 코스메틱 변경
- 로직 변경 없음
- 상호 의존성 없음
```

**Minor 필요한 경우:**
```bash
# ❌ 2개 파일이지만 Minor 필요
/minor
> "LoginForm과 AuthService 연동 로직 수정"

이유:
- 로직 변경
- 파일 간 의존성 있음
- 테스트 필요
```

**기준:**
```
Micro 적합:
- 파일 수 < 5개
- 각 파일에서 독립적인 코스메틱 변경
- 로직 변경 없음

Minor 이상:
- 파일 간 로직 연결
- 동작 변경
- 테스트 필요
```

---

## 문서 및 테스트 관련

### 6. "문서가 생성 안 돼요"

**증상:**
```
Expected: fix-analysis.md 생성
Actual: No documentation generated
```

**원인:**
Micro는 문서를 생성하지 않음 (의도된 동작)

**해결 방법:**

**이해하기:**
```
Micro의 철학:
- 즉시 실행 (No planning)
- 최소 오버헤드
- 문서 불필요한 trivial 변경

→ 문서 생성 없음은 정상
```

**문서가 필요한 경우:**
```bash
# ✅ Minor 사용
/minor
> "버그 수정 및 분석 문서 필요"

# 결과:
# .specify/fixes/issue-name/fix-analysis.md 생성
```

**Micro 변경 기록 방법:**
```bash
# 1. Git 커밋 메시지로 기록
/micro
> "Fix typo in README"

/commit
# 커밋 메시지에 자동 반영

# 2. 별도 changelog (선택)
echo "$(date): Fixed typo in README" >> CHANGELOG.md
```

---

### 7. "테스트 실행이 안 돼요"

**증상:**
```
Expected: Tests run automatically
Actual: Tests skipped
```

**원인:**
Micro는 테스트를 실행하지 않음 (의도된 동작)

**해결 방법:**

**이해하기:**
```
Micro의 Quality Gates:
✗ No test coverage required
✗ No test execution
✗ No architecture review
✓ Only: No breaking changes

→ 테스트 스킵은 정상
```

**테스트가 필요한 경우:**
```bash
# ✅ Minor 사용
/minor
> "로직 변경으로 테스트 필요"

# 결과:
# - 관련 테스트 자동 식별
# - 테스트 실행 요구
# - 검증 단계 포함
```

**수동 테스트:**
```bash
# Micro 실행 후 필요시 수동 테스트
/micro
> "설정 값 변경"

# 수동으로 테스트 실행
npm test

# 또는 특정 테스트만
npm test -- LoginForm.test.tsx
```

---

### 8. "변경 후 앱이 깨졌어요"

**증상:**
```
After Micro:
- Build fails
- App crashes
- Tests fail (if run manually)
```

**원인:**
- Micro가 부적합한 변경이었음
- 로직 영향을 과소평가
- Breaking change 발생

**해결 방법:**

**즉시 되돌리기:**
```bash
# Git으로 되돌리기
git status
# modified: src/features/auth/ui/LoginForm.tsx

git checkout -- src/features/auth/ui/LoginForm.tsx

# 또는 마지막 커밋 전체 되돌리기
git reset --hard HEAD
```

**올바른 워크플로우로 재실행:**
```bash
# ✅ Minor 또는 Major 사용
/minor
> "로그인 폼 수정 (테스트 포함)"

# 또는
/major
> "대규모 변경 (계획 필요)"
```

**예방책:**
```
Micro 실행 전 체크:
1. 정말 코스메틱 변경?
2. 로직 영향 없음?
3. 빌드 영향 없음?
4. 되돌리기 쉬움?

의심스러우면 → /minor 사용
```

---

## Breaking Changes

### 9. "Breaking change detected"

**증상:**
```
❌ Breaking change detected
- Public API modified
- Interface changed
```

**원인:**
- Micro에서 API 변경 시도
- 인터페이스 수정
- 타입 변경

**해결 방법:**

**Micro에서 금지된 변경:**
```typescript
// ❌ Micro로 시도 (Breaking change)
export interface User {
  email: string;
  // password: string;  // 제거 시도
}

// 이유:
// - Public API 변경
// - 기존 코드 깨짐
// - 마이그레이션 필요
```

**올바른 접근:**
```bash
# ✅ Major 사용
/major
> "User 인터페이스 리팩토링"

# Major에서:
# - Breaking change 허용
# - 마이그레이션 계획
# - 전체 테스트
```

**Micro에서 안전한 변경:**
```typescript
// ✅ Micro 적합 (Non-breaking)
export interface User {
  email: string;
  password: string;
  // 새 optional 필드 추가는 OK
  avatarUrl?: string;  // Non-breaking
}
```

---

### 10. "타입 변경이 Breaking인지 모르겠어요"

**질문**: 어떤 타입 변경이 Breaking change인가요?

**Breaking Changes:**
```typescript
// ❌ 모두 Breaking change
interface User {
  // 1. 필수 필드 제거
  // email: string;  // Breaking!

  // 2. 필수 필드 추가
  password: string;  // 기존에 없었다면 Breaking!

  // 3. 타입 변경
  // age: number;  // 기존
  age: string;  // Breaking!
}

// 4. 함수 시그니처 변경
// login(email: string): Promise<User>  // 기존
login(credentials: {email: string; password: string}): Promise<User>;  // Breaking!
```

**Non-breaking Changes:**
```typescript
// ✅ 모두 Non-breaking
interface User {
  email: string;
  password: string;

  // 1. Optional 필드 추가
  avatarUrl?: string;  // OK

  // 2. Optional 필드 제거
  // middleName?: string;  // OK (optional이었으면)

  // 3. 타입 확장 (Union에 추가)
  // status: 'active' | 'inactive';  // 기존
  status: 'active' | 'inactive' | 'pending';  // OK
}

// 4. 함수 오버로드 추가
login(email: string): Promise<User>;  // 기존
login(credentials: LoginCredentials): Promise<User>;  // 추가 OK
```

**Micro 가이드라인:**
```
✅ Micro 가능:
- Optional 필드 추가
- 내부 구현 변경 (인터페이스 유지)
- 주석 추가/수정
- 타입 alias 추가

❌ Micro 불가:
- 필수 필드 변경
- 함수 시그니처 변경
- Public API 수정
```

---

## 성능 문제

### 11. "Micro인데 토큰을 많이 써요"

**증상:**
```
Expected: ~2,000 tokens
Actual: 8,000 tokens
```

**원인:**
- 큰 파일 분석
- 여러 파일 검색
- 캐시 미스

**해결 방법:**

**방법 1: 구체적으로 명시**
```bash
# ❌ 모호함 (많은 검색 필요)
/micro
> "console.log 제거"

# ✅ 구체적 (검색 최소화)
/micro
> "src/features/auth/ui/LoginForm.tsx 42번 라인 console.log 제거"
```

**방법 2: 캐시 활용**
```bash
# 첫 실행: 8,000 tokens
/micro
> "오타 수정"

# 같은 파일 재실행: 1,500 tokens (캐시 히트)
/micro
> "또 다른 오타 수정"
```

**방법 3: 파일 크기 확인**
```bash
# 매우 큰 파일은 토큰 많이 사용
ls -lh src/features/auth/ui/LoginForm.tsx
# -rw-r--r--  1 user  staff   15K  (작은 파일: OK)
# -rw-r--r--  1 user  staff  150K  (큰 파일: 토큰 많이 사용)
```

---

### 12. "Micro가 느려요"

**증상:**
```
Expected: < 1 minute
Actual: 3-5 minutes
```

**원인:**
- 코드베이스가 매우 큼
- 파일 검색 범위 넓음
- 캐시 미작동

**해결 방법:**

**방법 1: .gitignore 확인**
```bash
# 불필요한 디렉토리 제외
cat .gitignore

# 추가:
node_modules/
dist/
build/
.next/
coverage/
```

**방법 2: 파일 직접 지정**
```bash
# ❌ 느림 (전체 검색)
/micro
> "오타 수정"

# ✅ 빠름 (파일 지정)
/micro
> "README.md 오타 수정"
```

**방법 3: 캐시 확인**
```bash
# 캐시 디렉토리 확인
ls -la .claude/cache/

# 없으면 생성
mkdir -p .claude/cache/{files,metrics}
```

---

## 일반적인 오해

### 13. "Micro는 항상 1개 파일만?"

**질문**: Micro는 반드시 1개 파일만 수정해야 하나요?

**답변**: 아니오

**1개 파일 (일반적):**
```bash
# ✅ 가장 일반적인 Micro
/micro
> "README.md 오타 수정"
```

**여러 파일 (가능):**
```bash
# ✅ 여러 파일이지만 Micro 적합
/micro
> "3개 파일에서 console.log 제거"

조건:
- 각 파일에서 독립적인 변경
- 모두 코스메틱 변경
- 파일 개수 < 5개
- 상호 의존성 없음
```

**기준:**
```
파일 개수가 아니라 변경의 성격:
- 코스메틱? → Micro 가능
- 로직 변경? → Minor 이상
- 서로 연관? → Minor 이상
```

---

### 14. "Micro에서 새 파일 생성 불가?"

**질문**: Micro로 새 파일을 만들 수 없나요?

**답변**: 가능하지만 매우 제한적

**가능한 경우:**
```bash
# ✅ Micro 적합
/micro
> ".env.example 파일 생성"

조건:
- 설정/문서 파일
- 로직 없음
- 템플릿/예제
```

**불가능한 경우:**
```bash
# ❌ Micro 부적합
/micro
> "새 컴포넌트 파일 생성"

이유:
- 로직 포함
- 테스트 필요
- 통합 필요

# ✅ Minor 사용
/minor
> "새 컴포넌트 추가"
```

---

### 15. "Micro는 품질이 낮은 거 아닌가요?"

**오해**: Micro는 품질 검증을 건너뛰므로 위험하다

**사실**: Micro는 **적절한 작업에 대해** 안전함

**Micro의 품질 보장:**
```
✓ Breaking change 방지 (유일한 gate)
✓ 개발자 판단 신뢰
✓ 빠른 되돌리기 가능
✓ 영향 범위 최소화

→ Trivial 변경에는 충분
```

**언제 안전한가:**
```
✅ 안전:
- 오타 수정
- 주석 변경
- 로그 제거
- CSS 조정
- 설정 값 (리스크 낮음)

❌ 위험:
- 로직 변경
- API 수정
- 데이터베이스 스키마
- 보안 관련
```

**적절한 워크플로우 선택이 핵심:**
```
작업 성격에 맞게:
- Trivial → Micro (안전)
- 일반 → Minor (테스트 포함)
- 복잡 → Major (완전한 계획)
```

---

## 빠른 참조

### Micro 적합성 체크리스트

```
변경 전 확인:
□ 로직 변경 없음 (코스메틱만)?
□ 파일 < 5개?
□ 테스트 불필요?
□ Breaking change 없음?
□ 5분 이내 완료 가능?
□ 쉽게 되돌릴 수 있음?

모두 ✓ → Micro 사용
하나라도 ✗ → Minor/Major 사용
```

---

### 자동 전환 기준

```
Micro → Minor:
- 복잡도 > 3/15
- 로직 변경 감지
- 파일 5개 이상
- 테스트 필요

Micro → Major:
- 복잡도 > 7/15
- 새 기능 추가
- 아키텍처 변경
```

---

### 일반적인 에러와 해결

**"Auto-upgrading to /plan-minor"**
```
→ 변경이 생각보다 복잡함
→ /plan-minor 사용하거나 범위 축소
```

**"Breaking change detected"**
```
→ API/인터페이스 변경 시도
→ /plan-major 사용 또는 변경 취소
```

**"문서가 생성 안 됨"**
```
→ Micro는 문서 생성 안 함 (정상)
→ 문서 필요하면 /plan-minor 사용
```

**"테스트가 실행 안 됨"**
```
→ Micro는 테스트 안 함 (정상)
→ 테스트 필요하면 /plan-minor 사용
```

---

**Version**: 4.0.0
**Last Updated**: 2025-11-18
**See Also**: [micro.md](../micro.md), [micro-examples.md](micro-examples.md)
