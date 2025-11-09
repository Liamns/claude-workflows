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

---

## 🔧 Implementation

이제 위의 프로세스를 실제로 실행하세요.

### Step 1: 작업 타입 자동 감지

사용자가 제공한 작업 설명을 분석하세요:

```typescript
function detectWorkType(description: string): {
  type: string;
  confidence: number;
  targetFiles: string[];
} {
  // 타이포/오타 감지
  if (/오타|typo|텍스트\s*수정|오류|철자/i.test(description)) {
    return { type: "타이포/오타", confidence: 0.9, targetFiles: [] };
  }

  // 주석 감지
  if (/주석|comment|설명\s*추가|문서화/i.test(description)) {
    return { type: "주석", confidence: 0.9, targetFiles: [] };
  }

  // 로그 제거 감지
  if (/console\.log|로그\s*제거|디버그\s*제거|console/i.test(description)) {
    return { type: "로그 제거", confidence: 0.95, targetFiles: [] };
  }

  // 설정 파일 감지
  if (/\.env|config|설정|환경\s*변수/i.test(description)) {
    return { type: "설정 파일", confidence: 0.9, targetFiles: [".env", "config"] };
  }

  // 코드 포맷팅 감지
  if (/포맷|정렬|indent|prettier|format/i.test(description)) {
    return { type: "코드 포맷팅", confidence: 0.85, targetFiles: [] };
  }

  // 기타
  return { type: "기타", confidence: 0.5, targetFiles: [] };
}
```

1. **작업 타입 분류**:
   - 위의 로직을 사용하여 작업 타입을 감지하세요
   - 결과를 `{workType}`, `{confidence}` 변수에 저장하세요

2. **사용자에게 보고**:
```markdown
📋 작업 타입: {workType}
📁 예상 영향: 1-2개 파일
⏱️ 예상 소요: 5분 이하
🔧 워크플로: Micro ✅
```

### Step 2: 파일 식별

사용자 입력에서 파일 경로가 명시되었는지 확인하세요:

**Case A: 파일 경로가 명시된 경우**
- 예: "/micro src/components/Button.tsx 오타 수정"
- 해당 파일을 직접 사용하세요
- `{targetFile}` 변수에 저장

**Case B: 파일 경로가 없는 경우**
- Grep 도구를 사용하여 관련 파일을 검색하세요

**파일 검색 로직**:
```
1. 작업 설명에서 키워드 추출 (예: "로그인 버튼" → ["로그인", "버튼"])
2. Grep 도구로 키워드 검색:
   Grep:
   - pattern: "{keyword}"
   - output_mode: "files_with_matches"
   - head_limit: 5
3. 결과를 분석하여 가장 가능성 높은 파일 3개 선택
4. 사용자에게 선택 제시
```

**AskUserQuestion 도구 사용**:
```
질문: "수정할 파일을 선택하세요"
헤더: "파일 선택"
multiSelect: false
옵션:
  1. label: "{filepath1}"
     description: "가능성: 높음"
  2. label: "{filepath2}"
     description: "가능성: 중간"
  3. label: "{filepath3}"
     description: "가능성: 낮음"
```

사용자의 선택을 `{targetFile}` 변수에 저장하세요.

### Step 3: 파일 수정

1. **Read 도구로 파일 읽기**:
```
Read: {targetFile}
```

2. **수정할 부분 식별**:
   - 작업 타입에 따라 수정 전략 결정
   - 타이포: 오타를 찾아서 올바른 텍스트로 변경
   - 주석: 주석을 추가할 위치 찾기
   - 로그 제거: console.log가 있는 줄 찾기
   - 설정 파일: 변경할 설정값 찾기

3. **Edit 도구로 파일 수정**:

**타이포 수정 예시**:
```
Edit:
- file_path: {targetFile}
- old_string: "로긴"
- new_string: "로그인"
```

**console.log 제거 예시**:
```
Edit:
- file_path: {targetFile}
- old_string: "  console.log('debug:', userData);\n  return userData;"
- new_string: "  return userData;"
```

**주석 추가 예시**:
```
Edit:
- file_path: {targetFile}
- old_string: "const isValid = validateToken(token);"
- new_string: "// 사용자 인증 토큰 검증\nconst isValid = validateToken(token);"
```

**설정 변경 예시**:
```
Edit:
- file_path: {targetFile}
- old_string: "VITE_API_BASE_URL=https://dev-api.example.com"
- new_string: "VITE_API_BASE_URL=https://prod-api.example.com"
```

4. **수정 완료 보고**:
```markdown
✅ 파일 수정 완료: {targetFile}
```

### Step 4: Lint 실행

1. **Bash 도구로 lint 실행**:
```
Bash:
- command: "yarn lint"
- description: "Run lint check"
```

2. **Lint 에러 처리**:

**에러 발견 시**:
```
Bash:
- command: "yarn lint --fix"
- description: "Auto-fix lint errors"
```

**자동 수정 불가 시**:
- 에러 메시지를 분석하여 수동 수정
- Edit 도구로 다시 수정

**Lint 통과 시**:
```markdown
✅ Lint 통과
```

### Step 5: 빌드 검증 (선택)

**AskUserQuestion 도구 사용**:
```
질문: "빌드 검증을 실행하시겠습니까?"
헤더: "빌드 검증"
multiSelect: false
옵션:
  1. label: "예, 빌드 검증 실행"
     description: "yarn build:dev를 실행하여 빌드 성공 여부를 확인합니다"
  2. label: "아니오, 건너뛰기"
     description: "빌드 검증을 생략하고 완료합니다"
```

**Option 1 선택 시**:
```
Bash:
- command: "yarn build:dev"
- description: "Run development build"
- timeout: 120000
```

**빌드 성공**:
```markdown
✅ 빌드 성공
```

**빌드 실패**:
```markdown
❌ 빌드 실패

이 작업은 /minor 워크플로가 더 적합할 수 있습니다.
```

**AskUserQuestion 도구 사용** (빌드 실패 시):
```
질문: "/minor 워크플로로 전환하시겠습니까?"
헤더: "워크플로 전환"
multiSelect: false
옵션:
  1. label: "예, /minor로 전환"
     description: "더 상세한 검증 프로세스로 진행합니다"
  2. label: "아니오, 계속 진행"
     description: "현재 상태로 완료합니다"
```

**Option 1 선택 시**:
```
SlashCommand: /minor "{사용자 요청}"
```

**Option 2 선택 시**:
```markdown
⚠️ 빌드 검증 건너뜀
```

### Step 6: 완료 보고

다음 형식으로 완료 보고를 출력하세요:

```markdown
✅ Micro 워크플로 완료!

📝 변경 사항:
- 파일: {targetFile}
- 변경 타입: {workType}
- 라인 수: {변경된 줄 수}줄

🔍 검증 결과:
- Lint: ✅ 통과
- Build: {실행됨/건너뜀}

📋 다음 단계:
1. 변경사항 확인:
   git diff {targetFile}

2. Git commit:
   git add {targetFile}
   git commit -m "style: {작업 설명}"

💡 Tip:
- 여러 파일을 동시에 수정하려면 /minor 사용을 권장합니다
- 로직 변경이 필요하면 /minor로 전환하세요
```

---

**중요 사항:**
- Step 1-6을 순차적으로 실행하세요
- 각 단계의 결과를 변수에 저장하여 다음 단계에서 사용하세요
- 파일 경로가 명시되지 않은 경우 반드시 Grep으로 검색하세요
- 모든 수정은 Edit 도구를 사용하세요
- Lint와 빌드는 Bash 도구를 사용하세요
- 사용자 확인이 필요한 경우 AskUserQuestion 도구를 사용하세요
