# /micro - Micro 워크플로 (Quick Fix)

타이포 수정, 주석 추가/제거, 로그 제거, 설정 파일 변경을 위한 초고속 워크플로입니다.

## 사용법

```
/micro [description]
```

예시:
```
/micro 로그인 버튼 텍스트 오타 수정
/micro console.log 제거
/micro 주석 추가
/micro .env 설정 변경
```

## 실행 순서

### 1단계: 작업 타입 자동 감지

**AI 자동 분석**:
사용자 입력을 분석하여 작업 타입 자동 분류

**분류 기준**:
- **타이포/오타**: "오타", "typo", "텍스트 수정"
- **주석**: "주석", "comment", "설명 추가"
- **로그 제거**: "console.log", "로그 제거", "디버그 제거"
- **설정 파일**: ".env", "config", "설정"
- **코드 포맷팅**: "포맷", "정렬", "indent"
- **기타**: 사용자 재확인

**자동 감지 결과 보고**:
```
📋 작업 타입: 타이포 수정
📁 예상 영향: 1-2개 파일
⏱️ 예상 소요: 5분 이하
🔧 워크플로: Micro ✅

계속하시겠습니까? (Y/n)
```

### 2단계: 빠른 파일 식별

**Q1: 파일 위치 (선택)**
"파일 위치를 알고 있나요? (알면 입력, 모르면 Enter)"

**입력 있음**:
```
→ 해당 파일 직접 열기
```

**입력 없음**:
```
→ 키워드 기반 자동 검색
→ Grep으로 관련 파일 찾기
→ 가능성 높은 파일 3개 제시
```

**예시**:
```
🔍 관련 파일 검색 결과:
1. src/features/auth/ui/LoginButton.tsx (가능성: 높음)
2. src/pages/auth/LoginPage.tsx (가능성: 중간)
3. src/widgets/header/ui/Header.tsx (가능성: 낮음)

수정할 파일 번호를 선택하세요 (1-3):
```

### 3단계: 즉시 수정

**자동 실행 - AI 직접 수정**:

**수정 원칙**:
1. **최소 변경**: 요청된 부분만 정확히 수정
2. **컨텍스트 보존**: 주변 코드 건드리지 않음
3. **포맷 유지**: 기존 코드 스타일 유지

**수정 예시**:

**Case 1: 타이포**
```diff
- <Button>로긴</Button>
+ <Button>로그인</Button>
```

**Case 2: console.log 제거**
```diff
- console.log('debug:', userData);
  return userData;
```

**Case 3: 주석 추가**
```diff
+ // 사용자 인증 토큰 검증
  const isValid = validateToken(token);
```

**Case 4: 설정 변경**
```diff
- VITE_API_BASE_URL=https://dev-api.example.com
+ VITE_API_BASE_URL=https://prod-api.example.com
```

### 4단계: 문법 체크 (Syntax Check)

**자동 실행**:
```bash
yarn lint
```

**lint 에러 발견 시**:
- 자동 수정 시도 (yarn lint --fix)
- 자동 수정 불가 시 → 수동 수정 제안

**lint 통과 시**:
```
✅ Lint 통과
```

### 5단계: 빌드 검증 (선택, Build Verify)

**기본값: 비활성화** (workflow-gates.json에서 enabled: false)

**Q2: 빌드 검증 실행 (선택)**
"빌드 검증을 실행하시겠습니까? (y/N)"

**Yes → 실행**:
```bash
yarn build:dev
```

**No → 건너뛰기**:
```
⚠️ 빌드 검증을 건너뛰었습니다.
   커밋 전에 직접 확인하세요: yarn build:dev
```

### 6단계: 완료 보고

```
✅ Micro 워크플로 완료!

📝 변경 사항:
- 파일: {filepath}
- 변경 줄 수: {N}줄
- 타입: {타이포/주석/로그/설정}

🔍 검증 결과:
- Lint: ✅ 통과
- Build: {실행/건너뜀}

📋 다음 단계:
1. 변경사항 확인:
   git diff

2. Git commit:
   git add {filepath}
   git commit -m "style: {description}"

💡 Tip:
- 여러 파일을 동시에 수정하려면 /minor 사용을 권장합니다
- 로직 변경이 필요하면 /minor로 전환하세요
```

## Quality Gates (workflow-gates.json 기준)

### Post-Implementation만 존재
- ✅ 문법 체크 (yarn lint)
- ⚠️ 빌드 검증 (선택, yarn build:dev)

## 예상 토큰 절감

**85%** (AI 최소 개입)

**절감 방법**:
1. 문서 생성 없음 (spec, plan, tasks 불필요)
2. 최소 파일만 로드
3. 즉시 수정 (분석 단계 생략)
4. 간소화된 검증

## 작업 타입별 처리

### 타이포/오타 수정
```
1. 파일 검색 (Grep)
2. 해당 줄 수정
3. Lint 실행
4. 완료
```

### 주석 추가/제거
```
1. 파일 열기
2. 주석 추가/제거
3. Lint 실행
4. 완료
```

### console.log 제거
```
1. Grep으로 모든 console.log 찾기
2. 제거할 라인 선택
3. 일괄 제거
4. Lint 실행
5. 완료
```

### 설정 파일 변경
```
1. .env 또는 config 파일 열기
2. 설정값 수정
3. (Lint 건너뛰기 - 설정 파일은 lint 대상 아님)
4. 완료
```

### 코드 포맷팅
```
1. Prettier 또는 ESLint auto-fix 실행
2. 완료
```

## 자동 워크플로 전환

**Micro → Minor 전환 조건**:
- 수정 중 로직 변경 필요 발견
- 타입 에러 발생
- 여러 파일 수정 필요

**자동 제안**:
```
⚠️ 이 작업은 /minor 워크플로가 더 적합합니다.

이유:
- 로직 변경이 필요합니다
- 타입 정의 수정이 필요합니다
- 3개 이상의 파일 수정이 필요합니다

/minor로 전환하시겠습니까? (Y/n)
```

## 에러 처리

- 파일 못 찾음 → 전체 프로젝트 검색
- Lint 실패 → 자동 수정 시도
- 빌드 실패 → /minor로 전환 제안
- 로직 변경 필요 → /minor로 전환 제안

## 사용 제한

**Micro 워크플로 사용 가능 조건**:
- ✅ 파일 1-2개 수정
- ✅ 로직 변경 없음
- ✅ 타입 정의 변경 없음
- ✅ 테스트 추가/수정 불필요

**Micro 워크플로 사용 불가 조건**:
- ❌ 3개 이상 파일 수정
- ❌ 로직 변경 필요
- ❌ 타입 정의 변경
- ❌ 새 함수/컴포넌트 추가
- ❌ API 호출 변경
- ❌ 상태 관리 변경

→ 이 경우 `/minor` 또는 `/major` 사용
