---
name: commit-guard
description: 커밋 전 선택적 검증을 수행합니다. 타입 체크, 테스트 실행, 민감 정보 검사 등을 자동으로 처리하여 커밋 품질을 보장합니다.
allowed-tools: Bash(yarn type-check), Bash(yarn test*), Bash(yarn lint), Read, Grep
---

# Commit Guard Skill

커밋 전 코드 품질과 보안을 검증하는 선택적 가드 시스템입니다.

## 활성화 시점

다음 상황에서 자동으로 활성화되거나 사용자 선택에 따라 실행됩니다:

- `/commit` 명령어 실행 시 선택적 활성화
- Breaking Changes 감지 시 자동 활성화
- 민감한 파일 변경 시 자동 알림
- 대규모 변경 시 권장 알림

## 검증 레벨

### Level 1: Quick Check (빠른 검증)
```bash
yarn type-check
```
- 실행 시간: 5-10초
- TypeScript 타입 오류만 검사
- 가장 기본적인 안전성 보장

### Level 2: Standard Check (표준 검증)
```bash
yarn type-check
yarn lint
```
- 실행 시간: 10-20초
- 타입 체크 + 코드 스타일 검증
- 일관된 코드 품질 유지

### Level 3: Full Check (전체 검증)
```bash
yarn type-check
yarn lint
yarn test:critical  # 또는 관련 테스트만
```
- 실행 시간: 30초-2분
- 완전한 품질 보장
- 프로덕션 배포 전 권장

## 검증 항목별 상세

### 1. 타입 체크 (Type Check)

**목적**: TypeScript 타입 안전성 보장

**검사 항목**:
- 타입 불일치
- Null/Undefined 참조
- 잘못된 함수 호출
- Interface 구현 누락

**실패 시 대응**:
```typescript
// ❌ Error: Type 'string | undefined' is not assignable to type 'string'
const name: string = user.name;

// ✅ 자동 수정 제안
const name: string = user.name ?? '';
```

### 2. 린트 검사 (Lint)

**목적**: 코드 스타일 일관성 유지

**검사 항목**:
- ESLint 규칙 위반
- Prettier 포맷팅
- Import 정렬
- 사용하지 않는 변수

**자동 수정**:
```bash
# 자동 수정 가능한 문제는 즉시 해결
yarn lint --fix
```

### 3. 테스트 실행 (Test)

**목적**: 기능 회귀 방지

**스마트 테스트 선택**:
```typescript
function getRelatedTests(changedFiles: string[]): string[] {
  const tests = [];

  for (const file of changedFiles) {
    // 직접 테스트 파일
    tests.push(file.replace('.tsx', '.test.tsx'));
    tests.push(file.replace('.ts', '.test.ts'));

    // 상위 디렉토리 통합 테스트
    const dir = path.dirname(file);
    tests.push(`${dir}/**/*.test.{ts,tsx}`);
  }

  return tests;
}
```

**실행 전략**:
- 작은 변경: 직접 관련 테스트만
- 중간 변경: Critical 테스트 포함
- 큰 변경: 전체 테스트 스위트

### 4. 민감 정보 검사 (Security Check)

**목적**: 실수로 민감한 정보 커밋 방지

**검사 패턴**:
```typescript
const sensitivePatterns = [
  // API 키
  /api[_-]?key[\s:=]+['"][a-zA-Z0-9]{20,}/gi,

  // AWS 자격증명
  /AKIA[0-9A-Z]{16}/g,

  // 비밀번호
  /password[\s:=]+['"][^'"]{8,}/gi,

  // Private Key
  /-----BEGIN (RSA|DSA|EC|OPENSSH) PRIVATE KEY-----/,

  // 환경 변수
  /VITE_[A-Z_]+_SECRET/g,
];
```

**감지 시 대응**:
```markdown
⚠️ 민감한 정보가 감지되었습니다!

파일: src/config/api.ts
라인 23: API_KEY = "sk-proj-abcd1234..."

이 정보를 커밋하시겠습니까? (권장하지 않음)
[N] 취소 (권장)
[E] .env로 이동
[Y] 무시하고 계속
```

### 5. 파일 크기 검사 (Size Check)

**목적**: 큰 파일 실수 커밋 방지

**임계값**:
- 경고: 1MB 이상
- 차단: 10MB 이상

**대응**:
```markdown
⚠️ 큰 파일 감지:

• public/images/hero.png (3.2MB)

권장 조치:
1. 이미지 압축 (tinypng.com)
2. Git LFS 사용
3. CDN 업로드
```

## 검증 우회 옵션

### 정당한 우회 사유
```bash
# 긴급 핫픽스
/commit --no-verify --reason="Production critical fix"

# WIP 커밋
/commit --no-verify --reason="WIP: 작업 중간 저장"

# 문서만 수정
/commit --no-verify --reason="docs only"
```

### 우회 기록
```yaml
# .claude/commit-guard-history.yaml
bypassed:
  - date: 2025-01-06
    reason: "긴급 핫픽스"
    files: ["PaymentModule.tsx"]
    user: dev
```

## 커스텀 규칙

### 프로젝트별 설정
`.claude/commit-guard-rules.yaml`:
```yaml
rules:
  # FSD 아키텍처 검증
  fsd_check:
    enabled: true
    strict: true

  # 커밋 메시지 검증
  message:
    max_length: 72
    require_type: true
    require_scope: false

  # 파일별 규칙
  files:
    "*.env*":
      action: block
      message: ".env 파일은 커밋할 수 없습니다"

    "src/entities/**":
      require_test: true
      min_coverage: 80

  # 민감 정보 패턴 추가
  sensitive_patterns:
    - "kakaopay.*key"
    - "toss.*secret"
```

## 성능 최적화

### 병렬 실행
```typescript
// 독립적인 검사는 동시 실행
const [typeCheck, lint, tests] = await Promise.all([
  runTypeCheck(),
  runLint(),
  runTests()
]);
```

### 캐싱 활용
```typescript
// 변경되지 않은 파일은 캐시된 결과 사용
const cacheKey = `${fileHash}-${checkType}`;
if (cache.has(cacheKey)) {
  return cache.get(cacheKey);
}
```

### 점진적 검사
```typescript
// 변경된 파일만 검사
const changedFiles = await getChangedFiles();
const filesToCheck = changedFiles.filter(f =>
  f.endsWith('.ts') || f.endsWith('.tsx')
);
```

## 검증 결과 리포트

### 성공 시
```markdown
✅ 커밋 검증 완료

검증 항목       | 결과 | 시간
---------------|------|------
타입 체크       | ✅   | 8s
린트           | ✅   | 5s
테스트 (3/3)   | ✅   | 12s
보안 검사      | ✅   | 1s

총 소요 시간: 26초
커밋 준비 완료!
```

### 실패 시
```markdown
❌ 커밋 검증 실패

검증 항목       | 결과 | 상세
---------------|------|------
타입 체크       | ❌   | 2개 에러
린트           | ⚠️   | 5개 경고 (자동 수정 가능)
테스트         | ✅   | 모두 통과
보안 검사      | ❌   | API 키 노출

상세 내용:
1. src/api/client.ts:15 - Type error
2. src/config.ts:23 - Sensitive data

수정 후 다시 시도해주세요.
[A] 자동 수정 시도
[M] 수동 수정
[S] 검증 건너뛰기
```

## 통합 워크플로우

### /commit과 연동
```bash
/commit
→ 변경사항 분석
→ "검증을 실행하시겠습니까?"
→ [Y] commit-guard 활성화
→ 검증 실행
→ 성공 시 커밋
```

### CI/CD 연동
```yaml
# .github/workflows/pre-commit.yml
- name: Run commit guard
  run: |
    yarn type-check
    yarn lint
    yarn test:critical
```

## 문제 해결

### "검증이 너무 오래 걸립니다"
→ Quick Check 레벨 사용 또는 관련 파일만 검사

### "테스트가 실패합니다"
→ 실패한 테스트만 먼저 수정 후 재실행

### "민감 정보 경고가 잘못되었습니다"
→ `.claude/commit-guard-rules.yaml`에서 패턴 수정

---

커밋 품질과 보안을 자동으로 지켜주는 든든한 가드입니다!