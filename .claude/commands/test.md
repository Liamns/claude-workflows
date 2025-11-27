---
name: test
hooks:
  pre: .claude/hooks/test-pre.sh
---

# Test - 테스트 작성 명령어

> **참고**: 이 명령어는 `.claude/CLAUDE.md`의 규칙을 준수합니다.

대상 파일에 대한 테스트를 작성하거나 기존 테스트를 수정합니다.

## 사용법

```bash
# 1. 변경된 파일 기준 테스트 생성
/test
# → git diff로 변경된 파일 감지, 테스트 생성

# 2. 특정 파일 테스트 생성
/test <file-path>
# → 지정된 파일에 대한 테스트 생성/수정

# 3. 커버리지 분석
/test --coverage
# → 테스트 커버리지 분석 후 미커버 영역 보완

# 4. 타입 불일치 수정
/test --fix
# → 테스트 파일의 타입 에러 자동 수정
```

## PreHook: test-pre.sh

PreHook이 실행되어 다음 정보를 수집합니다:

### 수집 정보
1. **대상 파일**: 인자 또는 git diff 기반
2. **관련 DTO/Type**: reusability-checker 연동
3. **기존 테스트 패턴**: test-pattern-analyzer 호출
4. **Mock/Stub 파일**: `__mocks__/`, `*.mock.ts` 검색

### PreHook 출력 형식

```
TARGET_FILES:<파일1>,<파일2>,...
RELATED_DTOS:<dto1>,<dto2>,...
RELATED_TYPES:<type1>,<type2>,...
TEST_FRAMEWORK:<jest|vitest|mocha>
MOCK_PATTERN:<jest.mock|vi.mock>
EXISTING_MOCKS:<mock1>,<mock2>,...
```

## 실행 순서

### 1. 대상 파일 감지

```bash
# 인자 없음: git diff로 변경된 파일 감지
git diff --name-only | grep -E '\.(ts|tsx)$' | grep -v '\.test\.\|\.spec\.'

# 인자 있음: 해당 파일 사용
# 예: /test src/features/order/ui/OrderForm.tsx
```

### 2. 관련 DTO/Type 검색

```bash
# reusability-checker 활용
.claude/lib/reusability/reusability-checker.sh -t dto "<keyword>"
.claude/lib/reusability/reusability-checker.sh -t type "<keyword>"
```

검색 결과를 테스트 파일 import에 활용

### 3. 기존 테스트 패턴 분석

```bash
# test-pattern-analyzer 활용
.claude/lib/test-pattern-analyzer.sh
```

분석 결과:
- 테스트 프레임워크 (Jest, Vitest 등)
- Mock 패턴 (`jest.mock()`, `vi.mock()`)
- AAA 구조 템플릿
- 기존 import 패턴

### 4. 테스트 코드 생성

기존 패턴을 100% 준수하여 테스트 생성:

```typescript
// AAA (Arrange-Act-Assert) 패턴 적용
describe('TargetName', () => {
  // Setup
  beforeEach(() => {
    // Arrange: 공통 설정
  });

  it('should do expected behavior', () => {
    // Arrange: 테스트별 설정
    const input = createMockInput();

    // Act: 실행
    const result = targetFunction(input);

    // Assert: 검증
    expect(result).toEqual(expectedOutput);
  });
});
```

### 5. 타입 체크 및 수정

```bash
yarn type-check
# 에러 발생 시 import 수정
```

## Critical Rules

1. **기존 패턴 100% 준수**: 프로젝트 내 다른 테스트와 동일한 스타일
2. **DTO/Type 재사용**: 새 타입 정의 금지, 기존 것 import
3. **Mock 재사용**: `__mocks__/` 내 기존 Mock 우선 사용
4. **AAA 패턴**: Arrange-Act-Assert 구조 필수
5. **타입 안전성**: 타입 에러 0개 상태로 완료

## 옵션별 동작

### --coverage

```bash
/test --coverage
```

1. 현재 테스트 커버리지 분석
2. 미커버 영역 식별
3. 해당 영역 테스트 케이스 추가

### --fix

```bash
/test --fix
```

1. 테스트 파일 타입 체크
2. 타입 에러 자동 수정
   - 잘못된 import 경로 수정
   - 누락된 타입 import 추가
   - Mock 타입 불일치 수정

## Output Language

모든 출력은 **한글**로 작성합니다.

## 예시 출력

### 기본 실행

```
🧪 테스트 생성 시작
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📁 대상 파일:
   - src/features/order/ui/OrderForm.tsx

🔍 관련 리소스 검색 중...
   ✓ DTO 발견: CreateOrderDTO, OrderResponseDTO
   ✓ Type 발견: OrderFormProps, OrderStatus
   ✓ Mock 발견: __mocks__/orderApi.ts

📊 테스트 패턴 분석:
   - 프레임워크: vitest
   - Mock 패턴: vi.mock()
   - 구조: AAA 패턴

📝 테스트 파일 생성:
   → src/features/order/ui/__tests__/OrderForm.test.tsx

✅ 테스트 생성 완료
   - 테스트 케이스: 5개
   - 타입 체크: 통과
```

### 커버리지 분석

```
📊 커버리지 분석 결과
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

파일: OrderForm.tsx
현재 커버리지: 67%

미커버 영역:
1. handleSubmit (line 45-52)
2. validateForm (line 78-95)
3. error handling branch (line 102)

테스트 케이스 추가 중...
✅ 커버리지: 67% → 89%
```

## 참고

- PreHook은 항상 exit code 0
- `/implement`에서 TDD 분기로 연계됨
- 기존 테스트 수정 시에도 패턴 준수
