# Minor 워크플로우 - 문서 템플릿

## 개요

Minor 워크플로우가 생성하는 문서는 **fix-analysis.md** 단일 파일입니다.

**생성 위치**: `.specify/fixes/<NNN-issue-name>/fix-analysis.md`

---

## fix-analysis.md - 수정 분석서

### 목적

- 버그의 근본 원인 식별
- 재사용 가능한 솔루션 제시
- 수정할 파일 목록
- 관련 테스트 식별
- 검증 단계 정의

---

### 템플릿 구조

```markdown
# Fix Analysis: [Issue Name]

## Issue
[문제 한 줄 요약]

**심각도**: [Low/Medium/High/Critical]
**복잡도**: [N/15]
**예상 시간**: [N 시간]

## Root Cause
파일: [file_path]
라인: [line_number]

문제:
- [구체적인 문제점 1]
- [구체적인 문제점 2]
- [구체적인 문제점 3]

## Solution
권장 접근법:
1. [해결 단계 1]
2. [해결 단계 2]
3. [해결 단계 3]

**재사용 가능 컴포넌트:**
- [기존 유틸리티/컴포넌트 1] ✓
- [기존 패턴 참고처]

## Tasks
- [ ] Task 1 설명
- [ ] Task 2 설명
- [ ] Task 3 설명
- [ ] Task 4 설명
- [ ] Task 5 설명

## Files to Change
1. [file_path_1]
   - [수정 내용 1]
   - [수정 내용 2]

2. [file_path_2]
   - [수정 내용 1]

## Related Tests
- [test_file_1] ([N개 기존 테스트])
- [test_file_2]

추가할 테스트:
- [ ] [테스트 케이스 1]
- [ ] [테스트 케이스 2]
- [ ] [테스트 케이스 3]

## Verification Steps
1. [검증 단계 1]
2. [검증 단계 2]
3. [검증 단계 3]
4. [검증 단계 4]
5. [검증 단계 5]

## Consistency Check
✓ [일관성 항목 1]
✓ [일관성 항목 2]
✓ [일관성 항목 3]
✓ [일관성 항목 4]
✓ [일관성 항목 5]

## Quality Metrics
- 수정할 파일: [N개]
- 변경할 라인: ~[N줄]
- 추가할 테스트: [N개]
- 재사용성: [Low/Medium/High]

## Constitution Compliance
✓ [아키텍처 규칙 1]
✓ [아키텍처 규칙 2]
✓ [위반사항 없음]

## Recommendations
- [권장사항 1]
- [권장사항 2]
- [권장사항 3]
```

---

### 실제 예시 1: 버그 수정

```markdown
# Fix Analysis: Login Null Pointer

## Issue
이메일이 비어있을 때 로그인 폼 제출 시 null pointer 에러 발생

**심각도**: Medium (사용자 경험에 영향)
**복잡도**: 5/15
**예상 시간**: 2-3시간

## Root Cause
파일: src/features/auth/ui/LoginForm.tsx
라인: 42

문제:
- 이메일 검증이 null 체크 없이 .toLowerCase() 호출
- 입력 검증을 위한 가드 절 누락
- 이메일 검증이 항상 문자열 입력을 가정

## Solution
권장 접근법:
1. shared/lib에서 emailValidator import
2. 인라인 검증을 재사용 가능한 함수로 교체 (42-45줄)
3. null/빈 값에 대한 early return 추가

**재사용 가능 컴포넌트:**
- shared/lib/validation/emailValidator.ts ✓
- features/register/ui/RegisterForm.tsx의 패턴 참고

## Tasks
- [ ] shared/lib에서 emailValidator import 추가
- [ ] LoginForm.tsx 42-45줄 인라인 검증 교체
- [ ] null/빈 값 early return 추가
- [ ] LoginForm.test.tsx에 테스트 3개 추가
- [ ] 테스트 실행 및 통과 확인

## Files to Change
1. src/features/auth/ui/LoginForm.tsx
   - emailValidator import 추가
   - 인라인 검증 교체 (42-45줄)
   - null 체크 추가

2. src/features/auth/ui/LoginForm.test.tsx
   - 빈 이메일 테스트 추가
   - null 이메일 테스트 추가
   - 에러 메시지 검증

## Related Tests
- LoginForm.test.tsx (기존 테스트 2개)
- emailValidator.test.ts (재사용 유틸리티)

추가할 테스트:
- [ ] 빈 이메일 제출 테스트
- [ ] null 이메일 처리 테스트
- [ ] 에러 메시지 표시 테스트

## Verification Steps
1. 테스트 실행: npm test LoginForm
2. 수동 테스트: 빈 이메일로 폼 제출
3. 에러 메시지 확인: "Email is required"
4. 콘솔 에러 없음 확인
5. 기존 플로우 회귀 없음 확인

## Consistency Check
✓ 기존 emailValidator 사용
✓ RegisterForm 패턴 따름
✓ FSD 레이어 구조 유지
✓ Breaking changes 없음
✓ 에러 메시지 일관성 유지

## Quality Metrics
- 수정할 파일: 2개
- 변경할 라인: ~10줄
- 추가할 테스트: 3개
- 재사용성: High (공유 validator 사용)

## Constitution Compliance
✓ FSD: Features 레이어만 (cross-feature import 없음)
✓ Public API: shared/lib를 index.ts를 통해 사용
✓ 아키텍처 위반 감지 안됨

## Recommendations
- 클라이언트 사이드 검증 라이브러리 고려 (예: Zod)
- 모든 필수 필드에 폼 레벨 검증 추가
- Constitution에 검증 패턴 문서화
```

---

### 실제 예시 2: 리팩토링

```markdown
# Fix Analysis: Extract Date Formatting Utility

## Issue
여러 컴포넌트에 중복된 날짜 포맷팅 로직 존재

**심각도**: Low (기술 부채)
**복잡도**: 6/15
**예상 시간**: 2-3시간

## Root Cause
파일:
- src/features/posts/ui/PostCard.tsx (3곳)
- src/features/comments/ui/Comment.tsx (2곳)
- src/features/notifications/ui/NotificationItem.tsx (1곳)

문제:
- 동일한 날짜 포맷팅 로직이 6곳에 중복
- 포맷 변경 시 모든 곳을 수정해야 함
- 일관성 유지 어려움
- 테스트 중복

발견된 패턴:
```typescript
new Date(timestamp).toLocaleDateString('en-US', {
  year: 'numeric',
  month: 'short',
  day: 'numeric'
})
```

## Solution
권장 접근법:
1. shared/lib/date/formatDate.ts 확장
   - formatRelativeDate 함수 추가
   - 기존 API 유지 (breaking changes 없음)

2. 6곳의 중복 교체
   - shared/lib에서 formatDate import
   - 인라인 포맷팅을 함수 호출로 교체

3. 테스트 업데이트
   - formatRelativeDate에 대한 테스트 추가
   - 컴포넌트 테스트에서 유틸리티 사용

**재사용 가능 컴포넌트:**
- shared/lib/date/formatDate.ts (이미 존재!) ✓
- 새 formatRelativeDate 함수 추가만 하면 됨

## Tasks
- [ ] formatDate.ts에 formatRelativeDate 함수 추가
- [ ] formatRelativeDate 테스트 6개 작성
- [ ] PostCard.tsx의 3곳 인라인 포맷팅 교체
- [ ] Comment.tsx의 2곳 인라인 포맷팅 교체
- [ ] NotificationItem.tsx의 1곳 인라인 포맷팅 교체
- [ ] 각 컴포넌트 테스트 업데이트
- [ ] 전체 테스트 실행 및 통과 확인
- [ ] 각 페이지 시각적 확인

## Files to Change
1. src/shared/lib/date/formatDate.ts
   - formatRelativeDate 함수 추가
   - 타입 정의 확장
   - 기존 함수 수정 없음

2. src/shared/lib/date/formatDate.test.ts
   - formatRelativeDate 테스트 추가
   - Edge cases 커버

3. src/features/posts/ui/PostCard.tsx
   - formatDate import 추가
   - 3곳의 인라인 포맷팅 교체

4. src/features/comments/ui/Comment.tsx
   - formatDate import 추가
   - 2곳의 인라인 포맷팅 교체

5. src/features/notifications/ui/NotificationItem.tsx
   - formatDate import 추가
   - 1곳의 인라인 포맷팅 교체

6. 각 컴포넌트의 테스트 파일
   - 포맷팅 모킹 제거 가능
   - 유틸리티 함수 테스트로 대체

## Related Tests
- formatDate.test.ts (기존)
- PostCard.test.tsx (3개 테스트 영향)
- Comment.test.tsx (2개 테스트 영향)
- NotificationItem.test.tsx (1개 테스트 영향)

추가할 테스트:
- [ ] formatRelativeDate: 오늘 날짜
- [ ] formatRelativeDate: 어제 날짜
- [ ] formatRelativeDate: 이번 주
- [ ] formatRelativeDate: 이번 달
- [ ] formatRelativeDate: 작년
- [ ] formatRelativeDate: edge cases

## Verification Steps
1. 모든 테스트 실행: npm test
2. 각 페이지 시각적 확인:
   - 게시글 목록 (PostCard)
   - 댓글 섹션 (Comment)
   - 알림 목록 (NotificationItem)
3. 날짜 포맷이 동일한지 확인
4. 타임존 처리 확인
5. 회귀 테스트 전체 실행

## Consistency Check
✓ shared/lib에 유틸리티 배치
✓ 모든 날짜 포맷팅이 하나의 소스에서
✓ 테스트 커버리지 향상
✓ Breaking changes 없음 (기존 API 유지)
✓ FSD 레이어 분리 준수

## Quality Metrics
- 수정할 파일: 7개 (1 유틸리티 + 6 컴포넌트)
- 삭제할 라인: ~30줄 (중복 제거)
- 추가할 라인: ~20줄 (유틸리티 + import)
- 추가할 테스트: 6개
- 재사용성: Very High (프로젝트 전체 사용 가능)

## Constitution Compliance
✓ FSD: 공유 로직을 shared/lib에 배치
✓ DRY 원칙 준수
✓ 단일 책임 원칙 (유틸리티 = 날짜 포맷팅만)
✓ 아키텍처 위반 없음

## Recommendations
- 다른 중복 패턴도 조사 (color 포맷팅, 숫자 포맷팅 등)
- 유틸리티 문서에 사용 예시 추가
- TypeScript strict 모드 활성화 (타입 안정성)
- 향후 i18n 고려 (다국어 날짜 포맷)
```

---

### 실제 예시 3: 소규모 기능 추가

```markdown
# Fix Analysis: Add Remember Me Checkbox

## Issue
로그인 폼에 "로그인 상태 유지" 체크박스 추가 요청

**심각도**: Low (기능 향상)
**복잡도**: 4/15
**예상 시간**: 3-4시간

## Root Cause
N/A (신규 기능)

현재 상태:
- 로그인 시 항상 24시간 토큰 발급
- 사용자가 로그인 지속 시간 선택 불가
- 브라우저 닫으면 재로그인 필요

요구사항:
- "로그인 상태 유지" 옵션 제공
- 체크 시 토큰 만료 7일로 연장
- 설정을 localStorage에 저장

## Solution
권장 접근법:
1. UI: shared/ui/Checkbox 컴포넌트 사용
2. 상태: LoginForm에 rememberMe state 추가
3. 로직: useAuth 훅 확장
4. 저장소: localStorage에 설정 저장
5. 토큰: 만료 시간 조건부 설정 (24h vs 7d)

**재사용 가능 컴포넌트:**
- shared/ui/Checkbox.tsx ✓
- shared/lib/storage/localStorage.ts ✓
- features/auth/model/useAuth.ts (확장)

## Tasks
- [ ] LoginForm.tsx에 rememberMe state 추가
- [ ] Checkbox 컴포넌트 import 및 렌더링
- [ ] handleSubmit에 rememberMe 전달
- [ ] useAuth.ts에 rememberMe 파라미터 추가
- [ ] 토큰 만료 시간 조건부 설정 로직
- [ ] localStorage에 설정 저장 로직
- [ ] LoginForm.test.tsx 테스트 4개 추가
- [ ] useAuth.test.ts 테스트 4개 추가
- [ ] 전체 테스트 실행 및 통과 확인
- [ ] UI 및 기능 수동 테스트

## Files to Change
1. src/features/auth/ui/LoginForm.tsx
   - rememberMe state 추가
   - Checkbox 컴포넌트 import 및 렌더링
   - handleSubmit에 rememberMe 전달

2. src/features/auth/model/useAuth.ts
   - login 함수에 rememberMe 파라미터 추가
   - 토큰 만료 시간 조건부 설정
   - localStorage에 설정 저장

3. src/features/auth/ui/LoginForm.test.tsx
   - 체크박스 렌더링 테스트
   - 체크박스 상호작용 테스트
   - rememberMe=true로 제출 테스트
   - rememberMe=false로 제출 테스트

4. src/features/auth/model/useAuth.test.ts
   - rememberMe=true 시 7일 토큰 테스트
   - rememberMe=false 시 24시간 토큰 테스트
   - localStorage 저장 테스트
   - 설정 불러오기 테스트

## Related Tests
- LoginForm.test.tsx (기존 5개 테스트)
- useAuth.test.ts (기존 8개 테스트)

추가할 테스트:
- [ ] Checkbox 렌더링 확인
- [ ] Checkbox 체크/해제 동작
- [ ] rememberMe=true로 로그인
- [ ] rememberMe=false로 로그인
- [ ] 7일 토큰 만료 확인
- [ ] 24시간 토큰 만료 확인
- [ ] localStorage 저장 확인
- [ ] 페이지 새로고침 시 설정 유지

## Verification Steps
1. UI 테스트:
   - 체크박스가 폼에 표시되는지 확인
   - 체크박스 클릭 동작 확인
   - 레이블 텍스트 올바른지 확인

2. 기능 테스트:
   - rememberMe 체크하고 로그인
   - localStorage에 설정 저장 확인
   - 브라우저 닫고 다시 열어도 로그인 유지
   - 7일 후 만료 확인 (시간 시뮬레이션)

3. 기본값 테스트:
   - rememberMe 체크 안하고 로그인
   - 브라우저 닫으면 세션 만료
   - 24시간 후 만료 확인

4. 관련 테스트:
   - npm test LoginForm
   - npm test useAuth
   - 모든 인증 관련 테스트 통과

5. 회귀 테스트:
   - 기존 로그인 플로우 동작 확인
   - 로그아웃 동작 확인
   - 토큰 갱신 동작 확인

## Consistency Check
✓ shared/ui/Checkbox 재사용
✓ shared/lib/storage/localStorage 재사용
✓ 기존 useAuth API와 일관성 유지
✓ FSD 레이어 분리 준수
✓ Breaking changes 없음 (선택적 파라미터)

## Quality Metrics
- 수정할 파일: 4개
- 추가할 라인: ~50줄
- 추가할 테스트: 8개
- 재사용성: High (기존 컴포넌트 활용)

## Constitution Compliance
✓ FSD: features/auth 내부에서만 변경
✓ UI: shared/ui 컴포넌트 재사용
✓ Storage: shared/lib 유틸리티 재사용
✓ Public API: 선택적 파라미터로 하위 호환성 유지
✓ 아키텍처 위반 없음

## Recommendations
- 보안 고려사항:
  - Remember me 시 추가 보안 검증 (예: IP 변경 감지)
  - Refresh token 로테이션
  - Suspicious activity 감지

- UX 개선:
  - 첫 로그인 시 remember me 기본 체크 (선택 사항)
  - 툴팁으로 "7일간 로그인 유지" 설명
  - 보안 설정 페이지에서 활성 세션 관리

- 향후 확장:
  - "모든 디바이스에서 로그아웃" 기능
  - 세션 만료 전 알림
  - 멀티 디바이스 동기화
```

---

## 문서 작성 가이드라인

### 1. 명확한 문제 정의

**좋은 예:**
```markdown
## Issue
로그인 폼에서 빈 이메일 제출 시 null pointer 에러 발생

**심각도**: Medium
**복잡도**: 5/15
```

**나쁜 예:**
```markdown
## Issue
로그인 에러

**심각도**: 보통
**복잡도**: 높음
```

---

### 2. 구체적인 근본 원인

**좋은 예:**
```markdown
## Root Cause
파일: src/features/auth/ui/LoginForm.tsx
라인: 42

문제:
- 이메일 검증이 null 체크 없이 .toLowerCase() 호출
- 입력 검증을 위한 가드 절 누락
- 이메일 검증이 항상 문자열 입력을 가정
```

**나쁜 예:**
```markdown
## Root Cause
코드에 버그가 있음
```

---

### 3. 재사용성 강조

**좋은 예:**
```markdown
**재사용 가능 컴포넌트:**
- shared/lib/validation/emailValidator.ts ✓
  → 이미 null-safe 검증이 있으니 재사용
- features/register/ui/RegisterForm.tsx의 패턴 참고
  → 유사한 가드 절 구현
```

**나쁜 예:**
```markdown
**재사용:**
- 기존 코드 참고
```

---

### 4. 실행 가능한 솔루션

**좋은 예:**
```markdown
## Solution
1. shared/lib에서 emailValidator import
2. 42-45줄의 인라인 검증 교체:
   ```typescript
   // Before
   const email = formData.email.toLowerCase()

   // After
   if (!formData.email) {
     return { error: 'Email is required' }
   }
   const email = emailValidator(formData.email)
   ```
3. null/빈 값에 대한 early return 추가
```

**나쁜 예:**
```markdown
## Solution
검증 추가하기
```

---

### 5. 구체적인 검증 단계

**좋은 예:**
```markdown
## Verification Steps
1. 테스트 실행: npm test LoginForm
2. 수동 테스트: 빈 이메일로 폼 제출
3. 에러 메시지 확인: "Email is required"
4. 콘솔에 에러 없는지 확인
5. 정상 로그인 플로우 회귀 테스트
```

**나쁜 예:**
```markdown
## Verification
테스트 실행
```

---

## 자주하는 실수

### 실수 1: 재사용성 무시

**잘못:**
```markdown
## Solution
새로운 이메일 검증 함수 작성
```

**올바름:**
```markdown
## Solution
shared/lib/validation/emailValidator.ts 재사용
(이미 구현되어 있음 - 새로 작성하지 말 것)
```

---

### 실수 2: 범위가 너무 넓음

**잘못 (Major 수준):**
```markdown
## Files to Change
- src/features/auth/ (전체 리팩토링)
- src/features/profile/
- src/features/settings/
- src/shared/lib/validation/ (새로 작성)
```

**올바름 (Minor 수준):**
```markdown
## Files to Change
1. src/features/auth/ui/LoginForm.tsx
2. src/features/auth/ui/LoginForm.test.tsx
```

---

### 실수 3: 테스트 생략

**잘못:**
```markdown
## Related Tests
없음
```

**올바름:**
```markdown
## Related Tests
- LoginForm.test.tsx (기존 2개 테스트)

추가할 테스트:
- [ ] 빈 이메일 제출 테스트
- [ ] null 이메일 처리 테스트
- [ ] 에러 메시지 표시 테스트
```

---

## 빠른 참조

### 섹션 체크리스트

fix-analysis.md 작성 시 다음 섹션이 모두 있는지 확인:

- [ ] Issue (심각도, 복잡도, 예상 시간)
- [ ] Root Cause (파일, 라인, 구체적 문제)
- [ ] Solution (단계별, 재사용 컴포넌트 명시)
- [ ] Tasks (체크박스로 수행 항목 나열)
- [ ] Files to Change (수정 내용 포함)
- [ ] Related Tests (기존 + 추가할 테스트)
- [ ] Verification Steps (5단계 이상)
- [ ] Consistency Check (5개 항목)
- [ ] Quality Metrics (정량적 지표)
- [ ] Constitution Compliance (아키텍처 규칙)
- [ ] Recommendations (향후 개선사항)

---

**참고**:
- [minor.md](../minor.md) - Minor 워크플로우 메인 문서
- [minor-examples.md](minor-examples.md) - 사용 예시
- [minor-troubleshooting.md](minor-troubleshooting.md) - 문제 해결 가이드
