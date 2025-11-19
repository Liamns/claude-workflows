# Minor 워크플로우 - 사용 예시

## 목차

1. [버그 수정 예시](#버그-수정-예시)
2. [리팩토링 예시](#리팩토링-예시)
3. [소규모 기능 추가](#소규모-기능-추가)
4. [사용 시나리오](#사용-시나리오)
5. [다른 워크플로우와 연계](#다른-워크플로우와-연계)

---

## 버그 수정 예시

### 예시 1: Null Pointer 에러 수정

**시나리오**: 로그인 폼에서 빈 이메일 입력 시 널 포인터 에러 발생

```bash
/minor
```

**대화 과정:**
```
어떤 문제를 수정하시나요?
> 이메일이 비어있을 때 로그인에서 null pointer 에러 발생

증상이나 에러를 설명해주세요:
> 사용자가 "Cannot read property 'toLowerCase' of null" 에러를 받음
> 빈 이메일로 로그인 폼 제출할 때 발생
```

**실행 결과:**
```
🔧 Minor 워크플로우 - 버그 수정
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 이슈 분석
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

이슈: 로그인 이메일 검증에서 null pointer
심각도: Medium (사용자 경험에 영향)
복잡도: 5/15 (Minor 워크플로우 적합)

🔍 근본 원인 분석
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

파일: src/features/auth/ui/LoginForm.tsx
라인: 42
문제: 이메일 검증이 null 체크 없이 .toLowerCase() 호출

근본 원인:
- 입력 검증 누락
- 빈/null 값에 대한 가드 절 없음
- 이메일 검증이 문자열 입력을 가정

📦 재사용성 검색
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

발견된 기존 솔루션:
✓ src/shared/lib/validation/emailValidator.ts
  → 이미 null-safe 이메일 검증 있음
  → 인라인 검증 대신 이것을 재사용

✓ src/features/register/ui/RegisterForm.tsx
  → 적절한 가드 절이 있는 유사 패턴
  → 이 검증 방식 따르기

💡 솔루션
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

권장 접근법:
1. shared/lib에서 emailValidator import
2. 재사용 가능한 함수로 인라인 검증 교체
3. null/빈 값에 대한 early return 추가

수정할 파일:
- src/features/auth/ui/LoginForm.tsx (수정)
- src/features/auth/ui/LoginForm.test.tsx (테스트 업데이트)

관련 테스트:
✓ LoginForm.test.tsx (기존 테스트 2개)
  → 빈 이메일 테스트 케이스 추가
  → 에러 메시지 표시 검증

🎯 Quality Gates
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

workflow-gates.json 기준:
✓ 관련 테스트 통과 필수
✓ Breaking changes 금지
✓ Constitution 준수
✗ 전체 테스트 커버리지 불필요 (Minor만)

📝 다음 단계
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

생성된 문서: .specify/fixes/login-null-pointer/
1. fix-analysis.md 검토
2. 솔루션 구현 (2-3개 파일)
3. 관련 테스트 실행
4. /commit으로 커밋

예상 토큰: ~15,000 (최적화 전: 60,000)
토큰 절감: 75%
```

---

### 예시 2: 타입 에러 수정

**시나리오**: API 응답 타입 불일치로 인한 에러

```bash
/minor
```

**작업 내용:** "사용자 프로필 API가 선택적 필드에 undefined를 반환하여 타입 에러 발생"

**생성되는 분석:**
```markdown
## 근본 원인
파일: src/features/profile/api/getUserProfile.ts
라인: 23

문제:
- API 응답 타입이 선택적 필드를 처리하지 않음
- TypeScript strict 모드가 undefined 값을 감지
- 프론트엔드가 모든 필드가 항상 존재한다고 가정

## 솔루션
1. ProfileResponse 타입을 선택적 필드 포함하도록 업데이트
2. undefined 값에 대한 런타임 체크 추가
3. 적절한 곳에 기본값 제공

## 수정할 파일
- src/features/profile/api/types.ts (인터페이스 업데이트)
- src/features/profile/api/getUserProfile.ts (체크 추가)
- src/features/profile/ui/ProfileCard.tsx (undefined 처리)

## 재사용성
✓ null 체크에 shared/lib/guards/isDefined.ts 사용
✓ features/posts/api/types.ts의 패턴 따르기

## 테스트
- [ ] 선택적 필드 누락된 API 테스트
- [ ] undefined 값으로 UI 렌더링 테스트
- [ ] 기본값이 올바르게 표시되는지 테스트
```

---

### 예시 3: UI 버그 수정

**시나리오**: 버튼이 모바일에서 화면 밖으로 나감

```bash
/minor
```

**작업 내용:** "제출 버튼이 모바일 화면(< 768px)에서 넘침"

**생성되는 분석:**
```markdown
## 근본 원인
파일: src/features/checkout/ui/CheckoutForm.tsx
라인: 156

문제:
- 고정 너비(400px)가 모바일에 맞지 않음
- 반응형 CSS 없음
- 컨테이너가 flexbox 사용 안함

## 솔루션
1. 고정 너비를 반응형 단위로 교체
2. 모바일 우선 미디어 쿼리 추가
3. 기존 반응형 패턴 사용

## 재사용성
✓ src/shared/ui/Button.tsx에 이미 반응형 변형 있음
✓ 커스텀 스타일 대신 Button 컴포넌트 사용
✓ 다른 폼의 모바일 우선 접근법 따르기

## 수정할 파일
- src/features/checkout/ui/CheckoutForm.tsx
  - shared/ui/Button으로 커스텀 버튼 교체
  - 반응형 컨테이너 스타일 추가
  - 모바일 뷰포트에서 테스트

## 검증
- [ ] 모바일에서 테스트 (< 768px)
- [ ] 태블릿에서 테스트 (768px - 1024px)
- [ ] 데스크톱에서 테스트 (> 1024px)
- [ ] 시각적 회귀 없음
```

---

## 리팩토링 예시

### 예시 4: 중복 코드 제거

**시나리오**: 여러 컴포넌트에 중복된 날짜 포맷팅 로직

```bash
/minor
```

**작업 내용:** "중복된 날짜 포맷팅 로직을 공유 유틸리티로 추출"

**실행 결과:**
```
🔧 Minor 워크플로우 - 리팩토링
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 분석
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

중복 코드 발견:
- src/features/posts/ui/PostCard.tsx (3곳)
- src/features/comments/ui/Comment.tsx (2곳)
- src/features/notifications/ui/NotificationItem.tsx (1곳)

발견된 패턴:
new Date(timestamp).toLocaleDateString('en-US', options)

📦 재사용성 확인
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

기존 유틸리티:
✓ src/shared/lib/date/formatDate.ts (이미 있음!)
  → 새 유틸리티 만들지 말고 이것 사용
  → 상대 시간 포맷 포함하도록 업데이트

💡 솔루션
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. shared/lib/date/formatDate.ts 확장
   - formatRelativeDate 함수 추가
   - 기존 API 유지 (breaking changes 없음)

2. 중복 교체 (6곳)
   - shared/lib에서 formatDate import
   - 인라인 포맷팅 교체

3. 테스트 업데이트
   - 새 formatRelativeDate 테스트 추가
   - 컴포넌트 테스트에서 유틸리티 사용하도록 업데이트

수정할 파일:
- src/shared/lib/date/formatDate.ts (확장)
- src/shared/lib/date/formatDate.test.ts (테스트 추가)
- 6개 컴포넌트 파일 (중복 교체)

검증:
- 모든 테스트 통과
- 시각적 변경 없음
- 앱 전체에서 일관된 날짜 포맷팅

예상 토큰: ~12,000
예상 시간: 2-3시간
```

---

### 예시 5: 함수 추출 리팩토링

**시나리오**: 긴 함수를 작은 함수로 분리

```bash
/minor
```

**작업 내용:** "handleSubmit에서 검증 로직을 별도 함수로 추출"

**생성되는 분석:**
```markdown
## 분석
현재 함수: 150줄
복잡도: 높음 (순환 복잡도: 15)
문제점:
- 여러 책임 (검증, 변환, 제출)
- 개별 부분 테스트 어려움
- 검증 로직 재사용 어려움

## 솔루션
작은 함수로 추출:
1. validateFormData(data): ValidationResult
2. transformToApiFormat(data): ApiRequest
3. handleSubmitError(error): void

## 재사용성
✓ features/register/에 유사한 검증 패턴 존재
✓ 에러 처리는 shared/lib/errors/handleApiError.ts 따름
✓ shared/types/의 기존 FormData 타입 사용

## 수정할 파일
- src/features/checkout/model/useCheckout.ts
  - 검증 함수 추출
  - 변환 로직 추출
  - 메인 핸들러 단순화

- src/features/checkout/model/useCheckout.test.ts
  - 추출된 각 함수 개별 테스트
  - 통합 테스트 복잡도 감소

## 이점
- 테스트 가능성: 각 함수 독립적으로 테스트
- 재사용성: 검증을 다른 곳에서 재사용 가능
- 유지보수성: 관심사 분리 명확
- 성능: 동일 (오버헤드 없음)
```

---

## 소규모 기능 추가

### 예시 6: Remember Me 체크박스 추가

**시나리오**: 로그인 폼에 "로그인 상태 유지" 기능 추가

```bash
/minor
```

**작업 내용:** "로그인 폼에 'Remember Me' 체크박스 추가"

**실행 결과:**
```
🔧 Minor 워크플로우 - 기능 추가
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 범위 분석
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

기능: Remember Me 체크박스
복잡도: 4/15 (Minor 적합)
영향: 낮음 (UI + 저장소만)

📦 재사용성
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

발견된 재사용 가능 컴포넌트:
✓ src/shared/ui/Checkbox.tsx
  → 일관된 스타일링에 사용

✓ src/shared/lib/storage/localStorage.ts
  → 설정 저장에 사용

✓ src/features/auth/model/useAuth.ts
  → remember me 로직을 위해 이 훅 확장

💡 구현
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Phase 1: UI 컴포넌트
- shared/ui에서 Checkbox 추가
- 폼 상태에 연결
- 레이블 및 스타일링 추가

Phase 2: 로직
- useAuth 훅 확장
- localStorage에 설정 저장
- 토큰 만료 조정 (7일 vs 24시간)

Phase 3: 테스트
- 체크박스 상호작용 테스트
- 설정 지속성 테스트
- 토큰 만료 로직 테스트

수정할 파일:
- src/features/auth/ui/LoginForm.tsx
- src/features/auth/model/useAuth.ts
- src/features/auth/ui/LoginForm.test.tsx
- src/features/auth/model/useAuth.test.ts

Quality gates:
✓ 관련 테스트 통과
✓ 기존 인증에 breaking changes 없음
✓ FSD 레이어 분리 유지

예상 토큰: ~18,000
예상 시간: 3-4시간
```

---

### 예시 7: 정렬 기능 추가

**시나리오**: 테이블에 간단한 정렬 기능 추가

```bash
/minor
```

**작업 내용:** "게시글 테이블에 날짜 및 이름 기준 정렬 추가"

**생성되는 분석:**
```markdown
## 범위
기존 게시글 테이블에 클라이언트 사이드 정렬 추가
컬럼: 날짜 (created_at), 이름 (title)
상호작용: 컬럼 헤더 클릭으로 정렬

## 재사용성
✓ src/shared/lib/array/sortBy.ts - 범용 정렬 유틸리티
✓ src/shared/ui/Table/TableHeader.tsx - 정렬 가능 헤더 컴포넌트
✓ src/features/comments/ui/CommentsList.tsx - 유사한 정렬 구현

## 구현
1. usePostsList 훅에 정렬 상태 추가
2. 공유 sortBy 유틸리티 사용
3. 정렬 아이콘이 있는 TableHeader 추가
4. 테스트 업데이트

## 수정할 파일
- src/features/posts/model/usePostsList.ts
  - sortBy 및 sortOrder 상태 추가
  - posts 배열에 정렬 적용

- src/features/posts/ui/PostsTable.tsx
  - 일반 헤더를 TableHeader로 교체
  - 정렬 핸들러 전달

- src/features/posts/ui/PostsTable.test.tsx
  - 날짜별 정렬 테스트
  - 이름별 정렬 테스트
  - 오름차순/내림차순 토글 테스트

## 품질
✓ Breaking changes 없음 (테이블 API 동일)
✓ 기존 공유 컴포넌트 사용
✓ CommentsList의 패턴 따름
✓ 클라이언트 사이드만 (API 변경 없음)
```

---

## 사용 시나리오

### 버그 수정에 적합한 경우

```bash
/minor

# ✅ 적합한 버그:
- Null pointer 에러
- Type 에러
- 로직 오류 (단순)
- UI 버그 (레이아웃, 스타일)
- 성능 이슈 (국소적)
- 에러 메시지 개선
- 입력 검증 누락

# ❌ 부적합한 버그:
- 아키텍처 문제 → /major 사용
- 여러 파일에 걸친 복잡한 버그 → /major
- 신규 기능이 필요한 경우 → /major
- 데이터 모델 변경 필요 → /major
```

**예시:**
```bash
# ✅ Minor 적합
/minor "로그인 버튼이 폼이 유효할 때 비활성화됨"
/minor "Safari에서 프로필 이미지 로드 안됨"
/minor "페이지 전체에서 날짜 포맷 불일치"

# ❌ Minor 부적합 (Major 사용)
/major "2FA로 인증 플로우 재설계"
/major "REST에서 GraphQL로 마이그레이션"
/major "실시간 채팅 기능 추가"
```

---

### 리팩토링에 적합한 경우

```bash
/minor

# ✅ 적합한 리팩토링:
- 중복 코드 제거
- 함수 추출 (Extract Function)
- 변수명 개선
- 타입 개선 (더 구체적으로)
- 파일 구조 정리 (소규모)
- 주석 추가/개선
- 상수 추출

# ❌ 부적합한 리팩토링:
- 전체 아키텍처 변경 → /major
- 여러 레이어에 걸친 리팩토링 → /major
- Public API 변경 → /major
- 디렉토리 구조 대규모 변경 → /major
```

**예시:**
```bash
# ✅ Minor 적합
/minor "날짜 포맷팅을 유틸리티 함수로 추출"
/minor "체크아웃의 잘못된 변수명 수정"
/minor "API 응답에 TypeScript 타입 추가"

# ❌ Minor 부적합 (Major 사용)
/major "Clean Architecture로 리팩토링"
/major "Redux에서 Zustand로 마이그레이션"
/major "모놀리식 컴포넌트를 FSD 레이어로 분리"
```

---

### 소규모 기능 추가에 적합한 경우

```bash
/minor

# ✅ 적합한 기능:
- 체크박스/라디오 버튼 추가
- 버튼 추가 (기존 기능 범위)
- 간단한 필터 (클라이언트 사이드)
- 정렬 기능 (클라이언트 사이드)
- UI 개선 (툴팁, 아이콘, 색상)
- 기존 폼에 필드 1-2개 추가
- 로딩 인디케이터 추가

# ❌ 부적합한 기능:
- 새로운 페이지 → /major
- 새로운 Entity/도메인 → /major
- API 엔드포인트 추가 → /major
- 데이터베이스 스키마 변경 → /major
- 인증/권한 로직 추가 → /major
```

**예시:**
```bash
# ✅ Minor 적합
/minor "로그인에 'Remember Me' 체크박스 추가"
/minor "게시글 목록에 날짜별 정렬 추가"
/minor "제출 버튼에 로딩 스피너 추가"

# ❌ Minor 부적합 (Major 사용)
/major "사용자 설정 페이지 추가"
/major "게시글에 댓글 시스템 추가"
/major "결제 통합 추가"
```

---

## 다른 워크플로우와 연계

### 패턴 1: Triage → Minor

**복잡도 분석 후 Minor 선택**

```bash
# 1. 작업 분석
/triage "로그인 null pointer 에러 수정"

# 출력:
# 복잡도: 5/15
# 추천: Minor 워크플로우
# 이유: 단순 버그 수정, 1-2 파일만 수정

# 2. Minor 실행
/minor

# 3. 구현
# ... 코딩 ...

# 4. 커밋
/commit
```

---

### 패턴 2: Minor → Review → Commit

**수정 후 검증 및 커밋**

```bash
# 1. Minor 실행
/minor
# → fix-analysis.md 생성

# 2. fix-analysis.md 확인
cat .specify/fixes/login-null-pointer/fix-analysis.md

# 3. 구현
# ... 코드 수정 ...

# 4. 관련 테스트 실행
npm test LoginForm

# 5. 변경사항 스테이징
git add src/features/auth/ui/LoginForm.tsx
git add src/features/auth/ui/LoginForm.test.tsx

# 6. 리뷰
/review --staged

# 출력:
# ✓ Constitution 준수
# ✓ Breaking changes 없음
# ✓ 관련 테스트 통과
# ✓ 커밋 준비 완료

# 7. 커밋
/commit

# 출력:
# fix(auth): add null check for email validation
#
# - shared/lib에서 emailValidator 추가
# - 빈 이메일 케이스 테스트 추가
# - null pointer 에러 수정
```

---

### 패턴 3: Review → Minor

**리뷰 결과 기반 리팩토링**

```bash
# 1. 코드 리뷰
/review --staged

# 출력:
# ⚠️  코드 중복 발견:
#     src/features/auth/ui/LoginForm.tsx
#     src/features/register/ui/RegisterForm.tsx
#     → 동일한 이메일 검증 로직 (42-45줄)
# 💡 제안: 공유 유틸리티로 추출

# 2. 리팩토링 실행
/minor "중복된 이메일 검증을 공유 유틸리티로 추출"

# 3. fix-analysis.md 확인
# → shared/lib/validation/emailValidator.ts 생성 권장
# → 두 컴포넌트에서 재사용

# 4. 구현 및 커밋
# ... 코딩 ...
/commit
```

---

### 패턴 4: Minor → Minor (연속 수정)

**관련 버그 연속 수정**

```bash
# 1. 첫 번째 버그 수정
/minor "로그인 폼 null pointer"
# ... 구현 ...
git add .
git commit -m "fix(auth): 이메일 null 체크 추가"

# 2. 관련 버그 발견
# (구현 중 유사한 문제 발견)

# 3. 두 번째 버그 수정
/minor "회원가입 폼에 동일한 null pointer 이슈"
# ... 구현 ...
git add .
git commit -m "fix(auth): 회원가입 이메일 null 체크 추가"

# 4. 리팩토링으로 통합
/minor "이메일 검증을 공유 유틸리티로 추출"
# ... 구현 ...
git add .
git commit -m "refactor(auth): 이메일 검증 유틸리티 추출"

# 5. 한 번에 PR
git push origin feature/auth-validation-fixes
/pr
```

---

### 패턴 5: Epic → Major → Minor

**Epic 내부에서 Major 구현 후 Minor로 버그 수정**

```bash
# 1. Epic 생성 (대규모 프로젝트)
/epic "전자상거래 플랫폼"
# → 브랜치: 009-ecommerce-platform

# 2. Epic 내부에서 Feature 구현 (Major)
/major "사용자 인증 시스템"
# → .specify/epics/009-ecommerce-platform/features/001-auth/
# ... 구현 ...

# 3. 구현 중 버그 발견
/minor "로그인 검증 에러 수정"
# → .specify/fixes/login-validation/
# ... 수정 ...
git add .
git commit -m "fix(auth): 로그인 검증 수정"

# 4. Feature 계속 진행
# ... 구현 ...

# 5. 모두 완료 후 PR
git push origin 009-ecommerce-platform
/pr
```

---

## 빠른 참조

### 자주 사용하는 패턴

```bash
# 기본 실행
/minor

# 복잡도 확인 후 실행
/triage "무언가 수정"
/minor

# 문서 확인
cat .specify/fixes/<issue-name>/fix-analysis.md

# 관련 테스트만 실행
npm test <ComponentName>

# 리뷰 및 커밋
/review --staged
/commit
```

### 토큰 절감 효과

| 시나리오 | 기존 | 최적화 | 절감 |
|---------|------|--------|------|
| 버그 수정 | 60,000 | 15,000 | 75% |
| 리팩토링 | 50,000 | 12,000 | 76% |
| 소규모 기능 | 70,000 | 18,000 | 74% |

---

**참고**:
- [minor.md](../minor.md) - Minor 워크플로우 메인 문서
- [minor-document-templates.md](minor-document-templates.md) - fix-analysis.md 템플릿
- [minor-troubleshooting.md](minor-troubleshooting.md) - 문제 해결 가이드
