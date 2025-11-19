# Micro 워크플로우 - 사용 예시

## 예시 1: 오타 수정

**시나리오**: README 문서의 오타 발견

```bash
/micro
```

**대화 과정:**
```
어떤 사소한 변경을 하시나요?
> README에서 "installtion" → "installation" 오타 수정
```

**실행 결과:**
```
⚡ Micro Workflow - Quick Fix
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📝 Change Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Type: Documentation fix
Scope: Single file (README.md)
Complexity: 1/15 (Micro appropriate)
Estimated: < 5 minutes

✅ Micro Validation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Single file modification
✓ Cosmetic change only
✓ No code logic affected
✓ No tests needed

🔧 Executing Change
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

File: README.md
Change: "installtion" → "installation" (line 23)

✅ Complete!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Next steps:
1. Verify change looks correct
2. Run: /commit

Expected tokens: ~3,000 (vs 20,000 without Micro)
Token savings: 85%
Time saved: 10 minutes
```

---

## 예시 2: Console.log 제거

**시나리오**: 프로덕션 코드에서 디버그 로그 제거

```bash
/micro
```

**대화 과정:**
```
어떤 사소한 변경을 하시나요?
> 프로덕션 코드에서 console.log 문 제거
```

**실행 결과:**
```
⚡ Micro Workflow - Code Cleanup
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📝 Change Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Type: Debug code removal
Scope: 3 files
Complexity: 2/15 (Micro appropriate)
Estimated: 10-15 minutes

🔍 Found Console Logs
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

src/features/auth/ui/LoginForm.tsx (2 instances)
  - Line 42: console.log('User data:', user)
  - Line 87: console.log('Login success')

src/features/profile/ui/ProfilePage.tsx (1 instance)
  - Line 156: console.log('Profile loaded')

src/shared/lib/api/apiClient.ts (3 instances)
  - Line 23: console.log('Request:', config)
  - Line 45: console.log('Response:', data)
  - Line 67: console.error('API Error:', error)

🔧 Executing Removal
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Removed 6 console.log statements
✓ No logic changes
✓ Files remain valid

✅ Complete!

Next steps:
1. Quick smoke test
2. Run: /commit

Expected tokens: ~2,500
```

---

## 예시 3: 설정 값 변경

**시나리오**: API 타임아웃 값 증가

```bash
/micro
```

**대화 과정:**
```
어떤 사소한 변경을 하시나요?
> API 타임아웃을 5000ms에서 10000ms로 변경
```

**실행 결과:**
```
⚡ Micro Workflow - Configuration Update
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📝 Change Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Type: Configuration change
Scope: 1 file (config.ts)
Complexity: 1/15 (Micro appropriate)
Estimated: 2 minutes

🔧 Executing Change
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

File: src/config/api.ts
Line: 12
Change: timeout: 5000 → timeout: 10000

✅ Complete!

Verification:
- Test a slow API call to confirm timeout
- Monitor for timeout errors

Expected tokens: ~2,000
```

---

## 예시 4: 자동 워크플로 전환 (Minor)

**시나리오**: Micro 범위를 초과하는 작업 시도

```bash
/micro
```

**대화 과정:**
```
어떤 사소한 변경을 하시나요?
> 로그인 검증 로직 수정
```

**실행 결과:**
```
⚠️ Scope Too Large for Micro
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Analysis:
- Type: Logic change (not cosmetic)
- Scope: Multiple files
- Complexity: 6/15
- Tests required: Yes

Reason:
Validation logic changes affect behavior and require:
- Root cause analysis
- Test coverage
- Regression prevention

💡 Recommendation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Use /minor instead:
- Proper issue analysis
- Related tests validation
- Documentation

Auto-upgrading to /minor workflow...
```

---

## 예시 5: Import 정리

**시나리오**: 사용하지 않는 import 제거

```bash
/micro
```

**대화 과정:**
```
어떤 사소한 변경을 하시나요?
> 사용하지 않는 import 문 제거
```

**실행 결과:**
```
⚡ Micro Workflow - Code Cleanup
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📝 Change Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Type: Import cleanup
Scope: 2 files
Complexity: 2/15 (Micro appropriate)
Estimated: 5 minutes

🔍 Found Unused Imports
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

src/features/auth/ui/LoginForm.tsx
  - Line 3: import { useState } from 'react' (unused)
  - Line 7: import { validatePassword } from '../lib' (unused)

src/features/profile/ui/ProfilePage.tsx
  - Line 5: import { formatDate } from '@/shared/lib' (unused)

🔧 Executing Removal
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Removed 3 unused imports
✓ Code compiles successfully
✓ No side effects

✅ Complete!

Expected tokens: ~3,000
```

---

## 예시 6: CSS 색상 변경

**시나리오**: 버튼 색상 업데이트

```bash
/micro
```

**대화 과정:**
```
어떤 사소한 변경을 하시나요?
> 로그인 버튼 색상을 파란색으로 변경
```

**실행 결과:**
```
⚡ Micro Workflow - Style Update
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📝 Change Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Type: Cosmetic styling
Scope: 1 file (LoginForm.module.css)
Complexity: 1/15 (Micro appropriate)
Estimated: 2 minutes

🔧 Executing Change
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

File: src/features/auth/ui/LoginForm.module.css
Line: 23
Change:
  background-color: #28a745 → background-color: #007bff

✅ Complete!

Verification:
- Visual check in browser
- Ensure contrast meets accessibility standards

Expected tokens: ~1,500
```

---

## 예시 7: 주석 제거

**시나리오**: 오래된 TODO 주석 정리

```bash
/micro
```

**대화 과정:**
```
어떤 사소한 변경을 하시나요?
> 완료된 TODO 주석 제거
```

**실행 결과:**
```
⚡ Micro Workflow - Comment Cleanup
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📝 Change Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Type: Comment removal
Scope: 1 file
Complexity: 1/15 (Micro appropriate)
Estimated: 3 minutes

🔍 Found TODO Comments
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

src/features/auth/ui/LoginForm.tsx
  - Line 15: // TODO: Add password validation (completed)
  - Line 42: // TODO: Handle errors (completed)

🔧 Executing Removal
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Removed 2 TODO comments
✓ Code unchanged

✅ Complete!

Expected tokens: ~2,000
```

---

## 실전 시나리오

### 시나리오 A: 긴급 프로덕션 수정

**상황**: 프로덕션 에러 메시지에서 오타 발견

```bash
# 1. 오타 수정
/micro
> "에러 메시지 오타 수정: 'occured' → 'occurred'"

# 출력:
# ✓ src/shared/lib/errors.ts 수정
# ✓ Line 23: message: 'An error occured' → 'An error occurred'

# 2. 즉시 커밋 & 배포
/commit

# 3. 프로덕션 배포
git push origin main

# 총 소요 시간: 3분
```

---

### 시나리오 B: PR 전 코드 클린업

**상황**: PR 제출 전 마지막 정리

```bash
# 1. Console.log 제거
/micro
> "console.log 문 제거"

# 출력:
# ✓ 5개 파일에서 12개 console.log 제거

# 2. 사용하지 않는 import 제거
/micro
> "사용하지 않는 import 제거"

# 출력:
# ✓ 3개 파일에서 7개 import 제거

# 3. 일괄 커밋
/commit

# 4. PR 생성
/pr

# 총 소요 시간: 8분
```

---

### 시나리오 C: 설정 조정

**상황**: API 응답 시간이 느려져서 타임아웃 증가 필요

```bash
# 1. 타임아웃 증가
/micro
> "API 타임아웃을 30초로 증가"

# 출력:
# ✓ src/config/api.ts
# ✓ timeout: 10000 → 30000

# 2. 개발 서버로 테스트
npm run dev

# 3. 느린 API 호출 테스트
# (브라우저에서 수동 확인)

# 4. 확인 후 커밋
/commit

# 총 소요 시간: 5분
```

---

### 시나리오 D: 연속 Micro 작업

**상황**: 여러 사소한 수정 일괄 처리

```bash
# 1. 오타 수정
/micro
> "README 오타 수정: 'authentification' → 'authentication'"

# 2. 링크 업데이트
/micro
> "문서 내 깨진 링크 수정"

# 3. 코드 주석 정리
/micro
> "오래된 주석 제거"

# 4. CSS 간격 조정
/micro
> "버튼 패딩 4px 증가"

# 5. 환경 변수 업데이트
/micro
> "개발 포트를 8080으로 변경"

# 6. 일괄 커밋
/commit

# 총 소요 시간: 15분
# (각 Micro: 2-3분)
```

---

### 시나리오 E: 리뷰 피드백 즉시 반영

**상황**: 코드 리뷰에서 간단한 수정 요청 받음

```bash
# 1. 코드 리뷰 실행
/review --staged

# 출력:
# ⚠️ Unused import on line 23: useState
# ⚠️ Typo in comment: 'recieve' should be 'receive'

# 2. 즉시 수정 1
/micro
> "23번 라인 사용하지 않는 import 제거"

# 3. 즉시 수정 2
/micro
> "주석 오타 수정: 'recieve' → 'receive'"

# 4. 재검토
/review --staged

# 출력:
# ✅ All checks passed!

# 5. 커밋
/commit

# 총 소요 시간: 7분
```

---

## 작업 타입별 사용 예시

### 문서 수정

```bash
# 오타 수정
/micro "Fix typo in API documentation"

# 링크 업데이트
/micro "Update broken link in README"

# 형식 정리
/micro "Fix markdown formatting in CONTRIBUTING.md"

# 예제 코드 업데이트
/micro "Update code example to use new API"
```

---

### 로그/주석 제거

```bash
# Console.log 제거
/micro "Remove console.log from production code"

# 디버깅 코드 제거
/micro "Remove debugger statements"

# TODO 주석 제거
/micro "Remove completed TODO comments"

# 주석 처리된 코드 제거
/micro "Clean up commented-out code"
```

---

### 설정 변경

```bash
# 타임아웃 조정
/micro "Change API timeout to 10 seconds"

# 포트 변경
/micro "Update development port from 3000 to 8080"

# 환경 변수
/micro "Update DATABASE_URL in .env.example"

# 기능 플래그
/micro "Enable experimental feature flag"
```

---

### 스타일링 (코스메틱)

```bash
# 색상 변경
/micro "Change button color to blue"

# 간격 조정
/micro "Increase padding by 4px"

# 폰트 크기
/micro "Update heading font size to 24px"

# 레이아웃 조정
/micro "Adjust margin between sections"
```

---

### Import 정리

```bash
# 사용하지 않는 import 제거
/micro "Remove unused imports"

# Import 순서 정리
/micro "Organize imports alphabetically"

# Alias 업데이트
/micro "Update import paths to use @/ alias"
```

---

## 자동 전환 예시

### Minor로 전환되는 경우

```bash
# 시도
/micro "로그인 검증 로직 개선"

# 결과
⚠️ Complexity too high (5/15)
→ Auto-upgrading to /minor

# 이유: 로직 변경은 테스트 필요
```

```bash
# 시도
/micro "null pointer 버그 수정"

# 결과
⚠️ Logic change detected
→ Requires testing
→ Auto-upgrading to /minor

# 이유: 버그 수정은 테스트 커버리지 필요
```

```bash
# 시도
/micro "여러 컴포넌트의 import 경로 변경"

# 결과
⚠️ Multiple files affected (8 files)
→ Needs analysis
→ Auto-upgrading to /minor

# 이유: 5개 이상 파일은 Minor 권장
```

---

### Major로 전환되는 경우

```bash
# 시도
/micro "새로운 결제 기능 추가"

# 결과
⚠️ New feature detected
→ Auto-upgrading to /major

# 이유: 새 기능은 Major 필수
```

```bash
# 시도
/micro "전체 인증 시스템 리팩토링"

# 결과
⚠️ Complexity too high (10/15)
→ Requires planning
→ Auto-upgrading to /major

# 이유: 대규모 리팩토링은 Major
```

---

## 빠른 참조

### Micro 사용 가능한 작업

```
✅ 오타 수정 (typo)
✅ console.log 제거
✅ 주석 정리/제거
✅ 설정 값 변경 (단순)
✅ CSS 스타일 조정
✅ Import 정리
✅ 문서 형식 수정
✅ 링크 업데이트
✅ 코드 포맷팅
✅ 환경 변수 업데이트
```

### Micro 사용 불가한 작업

```
❌ 로직 변경 → /minor
❌ 버그 수정 → /minor
❌ 리팩토링 → /minor
❌ 함수 추가 → /minor
❌ 새 기능 → /major
❌ API 변경 → /major
❌ 아키텍처 수정 → /major
```

### 토큰 사용량 예상

| 작업 타입 | 평균 토큰 | 시간 |
|----------|---------|------|
| 오타 수정 | ~2,000 | 2-3분 |
| 로그 제거 | ~2,500 | 5-10분 |
| 설정 변경 | ~1,500 | 2-5분 |
| Import 정리 | ~3,000 | 5-8분 |
| 주석 제거 | ~2,000 | 3-5분 |
| CSS 조정 | ~1,500 | 2-4분 |

---

**참고**:
- [micro.md](../micro.md) - 메인 문서
- [micro-troubleshooting.md](micro-troubleshooting.md) - 문제 해결
