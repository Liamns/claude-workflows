# Minor 워크플로우 - 사용 예시

> **참고**: Minor 워크플로우는 `/plan-minor` (분석/계획) → `/implement` (구현) 2단계로 분리되어 있습니다.

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

#### Step 1: 분석 및 계획
```bash
/plan-minor "이메일이 비어있을 때 로그인에서 null pointer 에러 발생"
```

**실행 결과:**
```
🔧 Minor Workflow - 분석 단계
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

📦 재사용성 검색
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

발견된 기존 솔루션:
✓ src/shared/lib/validation/emailValidator.ts
  → 이미 null-safe 이메일 검증 있음

✅ 분석 완료!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

생성된 문서: .specify/fixes/login-null-pointer/fix-analysis.md
다음 단계: /implement 로 구현 시작
```

#### Step 2: 구현
```bash
/implement
```

**출력:**
```
🔧 Implementation - 구현 단계
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📁 작업 디렉토리: .specify/fixes/login-null-pointer/

수정할 파일:
- src/features/auth/ui/LoginForm.tsx (수정)
- src/features/auth/ui/LoginForm.test.tsx (테스트 추가)

✅ 현재 작업을 시작합니다.
```

---

### 예시 2: 타입 에러 수정

**시나리오**: API 응답 타입 불일치로 인한 에러

```bash
/plan-minor "사용자 프로필 API가 선택적 필드에 undefined를 반환하여 타입 에러 발생"
```

**생성되는 fix-analysis.md:**
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
```

```bash
# 분석 검토 후 구현
/implement
```

---

### 예시 3: UI 버그 수정

**시나리오**: 버튼이 모바일에서 화면 밖으로 나감

```bash
/plan-minor "제출 버튼이 모바일 화면(< 768px)에서 넘침"
```

**생성되는 fix-analysis.md:**
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

## 검증
- [ ] 모바일에서 테스트 (< 768px)
- [ ] 태블릿에서 테스트 (768px - 1024px)
- [ ] 데스크톱에서 테스트 (> 1024px)
```

```bash
# 분석 검토 후 구현
/implement
```

---

## 리팩토링 예시

### 예시 4: 중복 코드 제거

**시나리오**: 여러 컴포넌트에 중복된 날짜 포맷팅 로직

```bash
/plan-minor "중복된 날짜 포맷팅 로직을 공유 유틸리티로 추출"
```

**실행 결과:**
```
🔧 Minor Workflow - 분석 단계
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 분석
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

중복 코드 발견:
- src/features/posts/ui/PostCard.tsx (3곳)
- src/features/comments/ui/Comment.tsx (2곳)
- src/features/notifications/ui/NotificationItem.tsx (1곳)

📦 재사용성 확인
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

기존 유틸리티:
✓ src/shared/lib/date/formatDate.ts (이미 있음!)
  → 새 유틸리티 만들지 말고 이것 사용

💡 솔루션
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. shared/lib/date/formatDate.ts 확장
2. 중복 교체 (6곳)
3. 테스트 업데이트

✅ 분석 완료!
생성된 문서: .specify/fixes/date-formatting-refactor/fix-analysis.md
```

```bash
# 분석 검토 후 구현
/implement
```

---

### 예시 5: 함수 추출 리팩토링

**시나리오**: 긴 함수를 작은 함수로 분리

```bash
/plan-minor "handleSubmit에서 검증 로직을 별도 함수로 추출"
```

**생성되는 fix-analysis.md:**
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

## 이점
- 테스트 가능성: 각 함수 독립적으로 테스트
- 재사용성: 검증을 다른 곳에서 재사용 가능
- 유지보수성: 관심사 분리 명확
```

```bash
# 분석 검토 후 구현
/implement
```

---

## 소규모 기능 추가

### 예시 6: Remember Me 체크박스 추가

**시나리오**: 로그인 폼에 "로그인 상태 유지" 기능 추가

```bash
/plan-minor "로그인 폼에 'Remember Me' 체크박스 추가"
```

**실행 결과:**
```
🔧 Minor Workflow - 분석 단계
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
✓ src/shared/lib/storage/localStorage.ts
✓ src/features/auth/model/useAuth.ts

💡 구현 계획
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Phase 1: UI 컴포넌트
Phase 2: 로직
Phase 3: 테스트

✅ 분석 완료!
생성된 문서: .specify/fixes/remember-me/fix-analysis.md
```

```bash
# 분석 검토 후 구현
/implement
```

---

### 예시 7: 정렬 기능 추가

**시나리오**: 테이블에 간단한 정렬 기능 추가

```bash
/plan-minor "게시글 테이블에 날짜 및 이름 기준 정렬 추가"
```

**생성되는 fix-analysis.md:**
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
```

```bash
# 분석 검토 후 구현
/implement
```

---

## 사용 시나리오

### 버그 수정에 적합한 경우

```bash
# ✅ 적합한 버그:
- Null pointer 에러
- Type 에러
- 로직 오류 (단순)
- UI 버그 (레이아웃, 스타일)
- 성능 이슈 (국소적)
- 에러 메시지 개선
- 입력 검증 누락

# ❌ 부적합한 버그:
- 아키텍처 문제 → /plan-major 사용
- 여러 파일에 걸친 복잡한 버그 → /plan-major
- 신규 기능이 필요한 경우 → /plan-major
- 데이터 모델 변경 필요 → /plan-major
```

**예시:**
```bash
# ✅ Minor 적합
/plan-minor "로그인 버튼이 폼이 유효할 때 비활성화됨"
/plan-minor "Safari에서 프로필 이미지 로드 안됨"
/plan-minor "페이지 전체에서 날짜 포맷 불일치"

# ❌ Minor 부적합 (Major 사용)
/plan-major "2FA로 인증 플로우 재설계"
/plan-major "REST에서 GraphQL로 마이그레이션"
/plan-major "실시간 채팅 기능 추가"
```

---

### 리팩토링에 적합한 경우

```bash
# ✅ 적합한 리팩토링:
- 중복 코드 제거
- 함수 추출 (Extract Function)
- 변수명 개선
- 타입 개선 (더 구체적으로)
- 파일 구조 정리 (소규모)
- 주석 추가/개선
- 상수 추출

# ❌ 부적합한 리팩토링:
- 전체 아키텍처 변경 → /plan-major
- 여러 레이어에 걸친 리팩토링 → /plan-major
- Public API 변경 → /plan-major
- 디렉토리 구조 대규모 변경 → /plan-major
```

**예시:**
```bash
# ✅ Minor 적합
/plan-minor "날짜 포맷팅을 유틸리티 함수로 추출"
/plan-minor "체크아웃의 잘못된 변수명 수정"
/plan-minor "API 응답에 TypeScript 타입 추가"

# ❌ Minor 부적합 (Major 사용)
/plan-major "Clean Architecture로 리팩토링"
/plan-major "Redux에서 Zustand로 마이그레이션"
/plan-major "모놀리식 컴포넌트를 FSD 레이어로 분리"
```

---

### 소규모 기능 추가에 적합한 경우

```bash
# ✅ 적합한 기능:
- 체크박스/라디오 버튼 추가
- 버튼 추가 (기존 기능 범위)
- 간단한 필터 (클라이언트 사이드)
- 정렬 기능 (클라이언트 사이드)
- UI 개선 (툴팁, 아이콘, 색상)
- 기존 폼에 필드 1-2개 추가
- 로딩 인디케이터 추가

# ❌ 부적합한 기능:
- 새로운 페이지 → /plan-major
- 새로운 Entity/도메인 → /plan-major
- API 엔드포인트 추가 → /plan-major
- 데이터베이스 스키마 변경 → /plan-major
- 인증/권한 로직 추가 → /plan-major
```

**예시:**
```bash
# ✅ Minor 적합
/plan-minor "로그인에 'Remember Me' 체크박스 추가"
/plan-minor "게시글 목록에 날짜별 정렬 추가"
/plan-minor "제출 버튼에 로딩 스피너 추가"

# ❌ Minor 부적합 (Major 사용)
/plan-major "사용자 설정 페이지 추가"
/plan-major "게시글에 댓글 시스템 추가"
/plan-major "결제 통합 추가"
```

---

## 다른 워크플로우와 연계

### 패턴 1: Triage → Plan-Minor → Implement

**복잡도 분석 후 Minor 선택**

```bash
# 1. 작업 분석
/triage "로그인 null pointer 에러 수정"

# 출력:
# 복잡도: 5/15
# 추천: Minor 워크플로우
# 이유: 단순 버그 수정, 1-2 파일만 수정

# 2. Minor 계획
/plan-minor

# 3. 구현
/implement

# 4. 커밋
/commit
```

---

### 패턴 2: Plan-Minor → Implement → Review → Commit

**수정 후 검증 및 커밋**

```bash
# 1. Minor 분석
/plan-minor "로그인 폼 null pointer"
# → fix-analysis.md 생성

# 2. fix-analysis.md 확인
cat .specify/fixes/login-null-pointer/fix-analysis.md

# 3. 구현
/implement
# → 코드 수정

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
```

---

### 패턴 3: Review → Plan-Minor → Implement

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

# 2. 리팩토링 계획
/plan-minor "중복된 이메일 검증을 공유 유틸리티로 추출"

# 3. 구현
/implement

# 4. 커밋
/commit
```

---

### 패턴 4: Minor 연속 수정

**관련 버그 연속 수정**

```bash
# 1. 첫 번째 버그 분석 및 수정
/plan-minor "로그인 폼 null pointer"
/implement
git add .
git commit -m "fix(auth): 이메일 null 체크 추가"

# 2. 관련 버그 발견 (구현 중 유사한 문제 발견)

# 3. 두 번째 버그 분석 및 수정
/plan-minor "회원가입 폼에 동일한 null pointer 이슈"
/implement
git add .
git commit -m "fix(auth): 회원가입 이메일 null 체크 추가"

# 4. 리팩토링으로 통합
/plan-minor "이메일 검증을 공유 유틸리티로 추출"
/implement
git add .
git commit -m "refactor(auth): 이메일 검증 유틸리티 추출"

# 5. 한 번에 PR
git push origin feature/auth-validation-fixes
/pr
```

---

### 패턴 5: Epic → Plan-Major → Plan-Minor

**Epic 내부에서 Major 구현 후 Minor로 버그 수정**

```bash
# 1. Epic 생성 (대규모 프로젝트)
/epic "전자상거래 플랫폼"
# → 브랜치: 009-ecommerce-platform

# 2. Epic 내부에서 Feature 구현 (Major)
/plan-major "사용자 인증 시스템"
/implement
# → .specify/epics/009-ecommerce-platform/features/001-auth/

# 3. 구현 중 버그 발견
/plan-minor "로그인 검증 에러 수정"
/implement
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

### 기본 워크플로우
```bash
# 분석 및 계획
/plan-minor "문제 설명"

# 문서 확인
cat .specify/fixes/<issue-name>/fix-analysis.md

# 구현
/implement

# 관련 테스트만 실행
npm test <ComponentName>

# 리뷰 및 커밋
/review --staged
/commit
```

### 복잡도 확인 후 실행
```bash
/triage "무언가 수정"
# → Minor 권장 시
/plan-minor
/implement
```

### 토큰 절감 효과

| 시나리오 | 기존 | 최적화 | 절감 |
|---------|------|--------|------|
| 버그 수정 | 60,000 | 15,000 | 75% |
| 리팩토링 | 50,000 | 12,000 | 76% |
| 소규모 기능 | 70,000 | 18,000 | 74% |

---

**참고**:
- [plan-minor.md](../../commands/plan-minor.md) - 계획 명령어
- [implement.md](../../commands/implement.md) - 구현 명령어
- [minor-document-templates.md](minor-document-templates.md) - fix-analysis.md 템플릿
- [minor-troubleshooting.md](minor-troubleshooting.md) - 문제 해결 가이드
