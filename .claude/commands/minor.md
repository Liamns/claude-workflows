# /minor - Minor 워크플로 (Incremental Updates)

기존 기능 개선, 버그 픽스, UI 스타일 변경을 위한 경량 워크플로입니다.

## 사용법

```
/minor [feature-number-or-description]
```

예시:
```
/minor 001                          # 기존 feature 001 업데이트
/minor fix-login-error              # 새 브랜치로 버그 수정
```

## 실행 순서

### 1단계: 작업 대상 식별

**Q1: 작업 타입**
"어떤 작업을 수행하시겠습니까?"
- [ ] 기존 feature 업데이트 (spec 있음)
- [ ] 버그 수정 (spec 없음)
- [ ] UI/UX 개선
- [ ] 성능 최적화
- [ ] 리팩토링

**Case A: 기존 Feature 업데이트**
```
"Feature 번호를 입력하세요 (예: 001):"
→ .specify/specs/001-feature-name/ 디렉토리 확인
→ spec.md, plan.md, tasks.md 로드
```

**Case B: 새 작업**
```
"작업 설명을 간단히 입력하세요:"
예시: "로그인 폼 유효성 검사 개선"
→ 새 브랜치 생성 (자동 번호 부여)
→ 간소화된 spec.md 생성
```

### 2단계: 문제 식별 (Issue Identification)

**Q2: 문제 설명**
"어떤 문제를 해결하려고 하나요? (재현 가능하게 설명)"
```
예시:
- Given: 사용자가 로그인 폼에 잘못된 이메일 형식 입력
- When: Submit 버튼 클릭
- Then: 에러 메시지가 표시되지 않음 (현재)
- Expected: "유효한 이메일 주소를 입력하세요" 표시
```

**Q3: 영향 범위**
"영향받는 파일을 알고 있나요?"
- Yes → 파일 경로 입력
- No → 자동 분석 (quick-fixer agent 활용)

**자동 분석 실행**:
```
1. Grep으로 관련 코드 검색
2. 파일 읽기 및 의존성 트리 분석
3. 영향받는 파일 목록 생성
```

### 3단계: 최소 변경 원칙 (Minimal Change)

**quick-fixer agent 실행**:

**분석 항목**:
1. **변경 범위 최소화**
   - 꼭 필요한 파일만 수정
   - 기존 로직 최대한 유지

2. **Side Effect 검증**
   - 변경이 다른 기능에 영향 없는지 확인
   - 관련 테스트 식별

3. **FSD 규칙 준수**
   - fsd-architect agent 자동 호출
   - 레이어 규칙 위반 없는지 확인

### 4단계: 변경 계획 수립

**간소화된 plan 생성**:
```markdown
# Minor Update: {Description}

## Issue
{문제 설명}

## Root Cause
{근본 원인 분석}

## Solution
{해결 방법}

## Files to Change
- [ ] {file1}: {변경 내용}
- [ ] {file2}: {변경 내용}

## Related Tests
- [ ] {test1}: {테스트 내용}
- [ ] {test2}: {테스트 내용}

## Verification Steps
1. {검증 단계 1}
2. {검증 단계 2}
```

### 5단계: 구현

**Q4: 즉시 구현 여부**
"즉시 구현을 시작하시겠습니까? (y/N)"

**Yes → 자동 구현**:
```
1. 파일별로 순차 수정
2. 각 파일 수정 후:
   - yarn type-check 실행
   - 관련 테스트 실행
3. 모든 변경 완료 후:
   - 전체 테스트 실행 (선택)
```

**No → 변경 계획만 저장**:
```
변경 계획이 저장되었습니다:
.specify/specs/{NNN-description}/plan.md

수동으로 수정 후:
- yarn type-check
- yarn test [affected]
```

### 6단계: 타입 체크 (Type Check)

**자동 실행**:
```bash
yarn type-check
```

**실패 시**:
- 타입 에러 분석
- 자동 수정 제안
- 사용자 확인 후 적용

### 7단계: 관련 테스트 실행 (Related Tests)

**자동 실행**:
```bash
# 영향받는 파일의 테스트만 실행
yarn test {affected-files}
```

**실패 시**:
- 테스트 실패 원인 분석
- 수정 제안
- 재실행

### 8단계: 회귀 테스트 (선택, Regression Check)

**Q5: Critical Path 테스트 실행**
"Critical path 테스트를 실행하시겠습니까? (y/N)"

**Yes → 실행**:
```bash
yarn test:critical
```

### 9단계: 자동 분석 (Analyze)

**자동 실행 - spec-kit analyze 기능**:

**분석 항목**:
1. **Cross-Artifact Consistency**
   - spec.md ↔ plan.md 일관성
   - plan.md ↔ tasks.md 일관성
   - 실제 구현 ↔ tasks.md 일관성

2. **Quality Metrics**
   - 테스트 커버리지 변화
   - 타입 안전성 유지
   - 코드 복잡도 변화

3. **Constitution Compliance**
   - 변경사항이 Constitution 위반하지 않는지 확인

**보고서 생성**:
```markdown
# Analysis Report: {Description}

## Consistency Check
- ✅ spec.md ↔ plan.md: Aligned
- ✅ plan.md ↔ implementation: Aligned
- ⚠️ Missing test for edge case X

## Quality Metrics
- Test Coverage: 82% → 85% (+3%)
- Type Safety: 100% (No errors)
- Complexity: Reduced by 12%

## Constitution Compliance
- ✅ All articles compliant
- No violations detected

## Recommendations
- Add test for edge case X
- Consider extracting utility function Y
```

### 10단계: 완료 보고

```
✅ Minor 워크플로 완료!

📝 변경 사항:
- 수정된 파일: {N}개
- 테스트 통과: {M}개
- 타입 에러: 0개

📊 품질 지표:
- 테스트 커버리지: {before}% → {after}%
- 빌드 시간: {변화 없음/개선}

📋 다음 단계:
1. Git commit:
   git add .
   git commit -m "fix: {description}"

2. (선택) PR 생성:
   gh pr create --title "fix: {description}"

3. (선택) Changelog 업데이트:
   /changelog
```

## Quality Gates (workflow-gates.json 기준)

### Pre-Implementation
- ✅ 문제 식별 (재현 가능한 설명)
- ✅ 영향 범위 파악

### During-Implementation
- ✅ 최소 변경 원칙 (quick-fixer)
- ✅ FSD 규칙 준수 (fsd-architect)
- ✅ 타입 체크 (yarn type-check)

### Post-Implementation
- ✅ 관련 테스트 통과 (yarn test [affected])
- ⚠️ 회귀 테스트 (선택, yarn test:critical)
- ✅ 자동 분석 (analyze)

## 예상 토큰 절감

**75%** (전체 컨텍스트 로드 대비)

**절감 방법**:
1. 전체 spec 대신 변경 부분만 로드
2. quick-fixer agent로 컨텍스트 격리
3. 영향받는 파일만 분석
4. 간소화된 문서화

## 에러 처리

- Feature 번호 없음 → 새 브랜치 생성 제안
- 타입 체크 실패 → 자동 수정 제안
- 테스트 실패 → 원인 분석 및 수정 가이드
- FSD 위반 → fsd-architect의 수정 제안
