# Document Gate - 오류 해결 가이드

> Feature 005: Epic 006 - Token Optimization Hybrid

## 📋 개요

이 가이드는 Document Gate 검증 실패 시 각 오류 유형별 해결 방법을 제공합니다. Exit code에 따라 적절한 섹션을 참고하세요.

**Exit Code 참조**:
- Exit 1: [파일 누락 오류](#exit-code-1-missing-files)
- Exit 2: [플레이스홀더 발견](#exit-code-2-placeholders)
- Exit 3: [필수 섹션 누락](#exit-code-3-missing-sections)

---

## Exit Code 1: Missing Files

### 오류 메시지

```bash
==========================================
Document Gate - Validation Report
==========================================
Feature Directory: .specify/features/010-auth-system/

[1/3] Validating file existence...
✗ Missing files:
  - plan.md
  - tasks.md

==========================================
Validation Summary
==========================================
Feature Directory: .specify/features/010-auth-system/

❌ Validation failed:
  ✗ Missing required files

Action: Create missing files using Feature 003 templates

❌ Document Gate Failed

Please complete the planning documents before proceeding.
See errors above for details.
```

### 원인

필수 문서 파일 중 하나 이상이 feature 디렉토리에 존재하지 않습니다.

**필수 파일**:
- `spec.md` - 요구사항 명세서
- `plan.md` - 구현 계획
- `tasks.md` - 작업 목록

### 해결 방법

#### 방법 1: Feature 003 템플릿 생성기 사용 (권장)

**Major Feature인 경우**:
```bash
bash .claude/lib/doc-generator/generate-spec.sh \
  --type major \
  --feature-id "010-auth-system" \
  --feature-name "Authentication System"
```

**생성되는 파일**:
- `.specify/features/010-auth-system/spec.md`
- `.specify/features/010-auth-system/plan.md`
- `.specify/features/010-auth-system/tasks.md`

**Minor Feature (버그 수정)인 경우**:
```bash
bash .claude/lib/doc-generator/generate-spec.sh \
  --type minor \
  --feature-id "010-auth-bug" \
  --feature-name "Fix auth token expiry"
```

#### 방법 2: 수동 생성

템플릿을 복사하여 수동으로 생성할 수도 있습니다:

```bash
# Feature 디렉토리로 이동
cd .specify/features/010-auth-system/

# 템플릿 복사
cp .claude/lib/doc-generator/templates/spec-template.md spec.md
cp .claude/lib/doc-generator/templates/plan-template.md plan.md
cp .claude/lib/doc-generator/templates/tasks-template.md tasks.md

# 에디터로 열어서 내용 작성
vim spec.md
```

### 검증

파일 생성 후 다시 Document Gate를 실행하여 검증:

```bash
bash .claude/lib/document-gate/document-gate.sh \
  .specify/features/010-auth-system/
```

**예상 결과**:
- Exit Code 0 (모든 검증 통과) 또는
- Exit Code 2 (플레이스홀더 발견 - 다음 단계로 진행)

---

## Exit Code 2: Placeholders

### 오류 메시지

```bash
==========================================
Document Gate - Validation Report
==========================================
Feature Directory: .specify/features/010-auth-system/

[1/3] Validating file existence...
✓ All required files present
[2/3] Detecting template placeholders...
✗ Template placeholders found:
  spec.md:
    Line 45: Replace {feature_name} with actual name...
    Line 67: TODO: Add user scenarios...
  tasks.md:
    Line 12: FIXME: Break down tasks...

==========================================
Validation Summary
==========================================
Feature Directory: .specify/features/010-auth-system/

❌ Validation failed:
  ✗ Template placeholders found

Action: Replace all {placeholders} with actual content
        Remove all TODO: and FIXME: markers

❌ Document Gate Failed

Please complete the planning documents before proceeding.
See errors above for details.
```

### 원인

문서에 템플릿 플레이스홀더가 남아있습니다.

**감지되는 패턴**:
- `{placeholder}` - 단일 중괄호 플레이스홀더
- `{{placeholder}}` - 이중 중괄호 플레이스홀더
- `TODO:` - TODO 마커
- `FIXME:` - FIXME 마커

### 해결 방법

#### Step 1: 오류 메시지에서 위치 확인

오류 메시지는 정확한 파일명과 라인 번호를 제공합니다:

```
spec.md:
  Line 45: Replace {feature_name} with actual name...
```

#### Step 2: 파일을 열어 플레이스홀더 확인

```bash
# 해당 라인으로 바로 이동
vim +45 .specify/features/010-auth-system/spec.md
```

또는 grep으로 모든 플레이스홀더 검색:

```bash
cd .specify/features/010-auth-system/

# 중괄호 플레이스홀더 찾기
grep -n '{[^}]\+}' *.md

# TODO/FIXME 찾기
grep -n 'TODO:\|FIXME:' *.md
```

#### Step 3: 실제 내용으로 교체

**Before** (플레이스홀더):
```markdown
## 🎯 Overview

{feature_name}는 사용자 인증을 처리하는 시스템입니다.

TODO: Add more details about authentication flow
```

**After** (실제 내용):
```markdown
## 🎯 Overview

Authentication System은 JWT 기반 토큰 인증과 OAuth 2.0 소셜 로그인을 지원하는
사용자 인증 시스템입니다.

주요 기능:
- JWT 토큰 발급 및 검증
- 리프레시 토큰을 통한 자동 갱신
- Google, GitHub OAuth 연동
- 세션 관리 및 로그아웃
```

#### Step 4: TODO/FIXME 마커 제거

**Before**:
```markdown
## Implementation Phases

TODO: Break down into specific phases
```

**After**:
```markdown
## Implementation Phases

### Phase 1: JWT 기본 구현 (3h)
- JWT 토큰 생성 로직
- 토큰 검증 미들웨어
- 테스트 작성

### Phase 2: OAuth 연동 (5h)
- Google OAuth 클라이언트 설정
- GitHub OAuth 클라이언트 설정
- OAuth 콜백 핸들러
```

### 특수 케이스: 코드 블록 내 플레이스홀더

**코드 블록 내부는 검사하지 않습니다** - 이는 정상적인 코드 예시입니다:

```markdown
# ✅ 정상 - 코드 블록은 무시됨
```json
{
  "user": "{user_id}",
  "token": "{{access_token}}"
}
```
```

**하지만 인라인 코드는 검사됩니다**:

```markdown
# ❌ 오류 - 인라인 코드는 검사 대상
Use `{placeholder}` to represent variables.
```

**해결책**: 코드 블록으로 변경하거나 실제 예시로 교체:

```markdown
# ✅ 해결책 1: 코드 블록 사용
```
Use `{placeholder}` to represent variables.
```

# ✅ 해결책 2: 실제 예시
Use `userId` or `username` to represent variables.
```

### 검증

플레이스홀더 제거 후 다시 Document Gate를 실행:

```bash
bash .claude/lib/document-gate/document-gate.sh \
  .specify/features/010-auth-system/
```

**예상 결과**:
- Exit Code 0 (모든 검증 통과) 또는
- Exit Code 3 (필수 섹션 누락 - 다음 단계로 진행)

---

## Exit Code 3: Missing Sections

### 오류 메시지

```bash
==========================================
Document Gate - Validation Report
==========================================
Feature Directory: .specify/features/010-auth-system/

[1/3] Validating file existence...
✓ All required files present
[2/3] Detecting template placeholders...
✓ No template placeholders found
[3/3] Validating required sections...
✗ Missing required sections:
  spec.md:
    - ## 🎬 User Scenarios & Testing
    - ## ✅ Success Criteria
  plan.md:
    - ## Performance Targets

==========================================
Validation Summary
==========================================
Feature Directory: .specify/features/010-auth-system/

❌ Validation failed:
  ✗ Missing required sections

Action: Add missing sections to planning documents

❌ Document Gate Failed

Please complete the planning documents before proceeding.
See errors above for details.
```

### 원인

문서에 필수 섹션이 누락되었습니다.

### 필수 섹션 목록

#### spec.md 필수 섹션

```markdown
## 📋 Feature 정보
## 🎯 Overview
## 🎬 User Scenarios & Testing
## 🔍 Key Entities
## ✅ Success Criteria
```

#### plan.md 필수 섹션

```markdown
## Technical Foundation
## Constitution Check
## Phase 1: Design Artifacts
## Implementation Phases
## Performance Targets
```

#### tasks.md 필수 섹션

```markdown
## Phase 1:
### Tests (Write FIRST - TDD)
### Implementation (AFTER tests)
```

### 해결 방법

#### Step 1: 누락된 섹션 확인

오류 메시지에서 정확히 어떤 섹션이 누락되었는지 확인합니다:

```
spec.md:
  - ## 🎬 User Scenarios & Testing
  - ## ✅ Success Criteria
```

#### Step 2: 섹션 추가

**spec.md 예시** - User Scenarios & Testing 섹션:

```markdown
## 🎬 User Scenarios & Testing

### Primary User Scenarios

**시나리오 1: 신규 사용자 회원가입**
1. 사용자가 이메일/비밀번호로 회원가입
2. 시스템이 JWT access token과 refresh token 발급
3. 사용자가 인증된 상태로 대시보드 접근

**시나리오 2: OAuth 소셜 로그인**
1. 사용자가 "Google로 로그인" 버튼 클릭
2. Google 동의 화면으로 리다이렉트
3. 콜백에서 사용자 정보 받아 계정 생성/로그인
4. JWT 토큰 발급 및 세션 생성

**시나리오 3: 토큰 갱신**
1. Access token 만료 (15분)
2. 클라이언트가 refresh token으로 갱신 요청
3. 새로운 access token 발급
4. 사용자 경험 중단 없이 계속 사용

### Testing Strategy

**단위 테스트**:
- JWT 토큰 생성/검증 로직
- 비밀번호 해싱/검증
- OAuth 콜백 파싱

**통합 테스트**:
- 회원가입 → 로그인 → 인증 API 호출 플로우
- OAuth 전체 플로우 (mock OAuth provider)
- 토큰 갱신 플로우

**E2E 테스트**:
- 실제 브라우저에서 회원가입/로그인
- Google OAuth 연동 (테스트 계정)
```

**spec.md 예시** - Success Criteria 섹션:

```markdown
## ✅ Success Criteria

### 기능 완성도
- [ ] JWT 토큰 생성 및 검증 정상 작동
- [ ] Google OAuth 로그인 성공률 99% 이상
- [ ] GitHub OAuth 로그인 성공률 99% 이상
- [ ] 리프레시 토큰 갱신 정상 작동

### 성능 기준
- [ ] 토큰 발급: < 100ms (P95)
- [ ] 토큰 검증: < 10ms (P95)
- [ ] OAuth 콜백 처리: < 500ms (P95)

### 보안 기준
- [ ] 비밀번호 bcrypt 해싱 (cost factor 12)
- [ ] JWT secret 환경변수로 관리
- [ ] HTTPS only 쿠키 설정
- [ ] CSRF 토큰 검증

### 테스트 커버리지
- [ ] 단위 테스트: 90% 이상
- [ ] 통합 테스트: 주요 플로우 100%
- [ ] E2E 테스트: 핵심 시나리오 100%

### 문서화
- [ ] API 문서 작성 (Swagger)
- [ ] 인증 플로우 다이어그램
- [ ] 환경 변수 설정 가이드
```

**plan.md 예시** - Performance Targets 섹션:

```markdown
## Performance Targets

### Response Time Targets

| Operation | Target (P95) | Target (P99) |
|-----------|--------------|--------------|
| 토큰 발급 | < 100ms | < 200ms |
| 토큰 검증 | < 10ms | < 20ms |
| OAuth 콜백 | < 500ms | < 1000ms |
| 로그아웃 | < 50ms | < 100ms |

### Throughput Targets

- 동시 로그인 요청: 100 req/s
- 토큰 검증: 1000 req/s
- OAuth 플로우: 50 req/s

### Resource Limits

- 메모리 사용: < 100MB (평균)
- CPU 사용: < 30% (평균)
- 데이터베이스 연결: < 10개

### Scalability

- 수평 확장 가능 (stateless design)
- Redis 세션 저장소 지원
- JWT 토큰으로 서버 간 세션 공유
```

#### Step 3: 섹션 제목 정확히 일치시키기

**주의**: 섹션 제목은 **대소문자와 이모지를 포함하여 정확히 일치**해야 합니다.

**❌ 잘못된 예시**:
```markdown
## User Scenarios & Testing  (이모지 누락)
## 🎬 User scenarios & testing  (대소문자 불일치)
```

**✅ 올바른 예시**:
```markdown
## 🎬 User Scenarios & Testing  (정확히 일치)
```

### 검증

섹션 추가 후 다시 Document Gate를 실행:

```bash
bash .claude/lib/document-gate/document-gate.sh \
  .specify/features/010-auth-system/
```

**예상 결과**:
- Exit Code 0 (모든 검증 통과)

---

## 문제 해결 프로세스

### 단계별 해결 순서

Document Gate는 다음 우선순위로 오류를 보고합니다:

```
1. 파일 존재 확인 (Exit 1)
   ↓
2. 플레이스홀더 감지 (Exit 2)
   ↓
3. 필수 섹션 검증 (Exit 3)
   ↓
✅ 모든 검증 통과 (Exit 0)
```

**권장 해결 순서**:
1. **먼저 Exit 1 해결**: 모든 파일 생성
2. **다음 Exit 2 해결**: 플레이스홀더를 실제 내용으로 교체
3. **마지막 Exit 3 해결**: 누락된 필수 섹션 추가

### 빠른 체크리스트

**파일 존재 확인**:
```bash
ls -la .specify/features/010-auth-system/
# 확인: spec.md, plan.md, tasks.md 모두 있는가?
```

**플레이스홀더 검색**:
```bash
cd .specify/features/010-auth-system/
grep -n '{[^}]\+}\|TODO:\|FIXME:' *.md
# 출력 없으면 플레이스홀더 없음
```

**필수 섹션 확인**:
```bash
# spec.md 섹션 확인
grep "^## " spec.md

# plan.md 섹션 확인
grep "^## " plan.md

# tasks.md 섹션 확인
grep "^## \|^### " tasks.md
```

### 자동화 스크립트

전체 검증을 한 번에 실행:

```bash
#!/bin/bash
# quick-check.sh

FEATURE_DIR="${1:-.}"

echo "=== Quick Document Check ==="
echo ""

echo "1. Files:"
for file in spec.md plan.md tasks.md; do
  if [ -f "$FEATURE_DIR/$file" ]; then
    echo "  ✓ $file"
  else
    echo "  ✗ $file (missing)"
  fi
done

echo ""
echo "2. Placeholders:"
if grep -q '{[^}]\+}\|TODO:\|FIXME:' "$FEATURE_DIR"/*.md 2>/dev/null; then
  echo "  ✗ Found placeholders:"
  grep -n '{[^}]\+}\|TODO:\|FIXME:' "$FEATURE_DIR"/*.md
else
  echo "  ✓ No placeholders"
fi

echo ""
echo "3. Running Document Gate:"
bash .claude/lib/document-gate/document-gate.sh "$FEATURE_DIR"
```

사용법:
```bash
bash quick-check.sh .specify/features/010-auth-system/
```

---

## 고급 문제 해결

### 문제: grep 결과에 플레이스홀더가 없는데 Exit 2 발생

**원인**: 코드 블록 외부에 플레이스홀더가 있을 수 있습니다.

**해결**:
```bash
# 더 정확한 검색 (라인 번호 포함)
cd .specify/features/010-auth-system/
grep -n '{[^}]\+}' *.md | less

# 특정 라인 확인
sed -n '45p' spec.md  # 45번 라인만 출력
```

### 문제: 섹션이 있는데 Exit 3 발생

**원인**: 섹션 제목이 정확히 일치하지 않습니다.

**해결**:
```bash
# 현재 섹션 제목 확인 (정확한 문자열)
grep "^## " spec.md | cat -A

# 필수 섹션과 비교
# 예상: ## 🎬 User Scenarios & Testing$
# 실제: ## 🎬 User Scenarios & Testing  $ (공백 있음)
```

**수정**: 불필요한 공백 제거
```bash
# 자동으로 trailing 공백 제거
sed -i '' 's/[[:space:]]*$//' spec.md
```

### 문제: Document Gate가 너무 느림

**정상 속도**: < 0.1초

**느린 경우** (> 1초):
```bash
# 파일 크기 확인
wc -l .specify/features/010-auth-system/*.md

# 대용량 파일인 경우 (> 1000줄) 분할 고려
```

**최적화**:
- 문서를 여러 파일로 분할
- 불필요한 대용량 코드 블록 제거
- NFS/네트워크 드라이브 사용 시 로컬로 복사

---

## 관련 문서

- [README.md](README.md) - Document Gate 사용법
- [Feature 003 Templates](../doc-generator/) - 문서 템플릿 생성기
- [/major 워크플로우](../../commands/major.md) - Major feature 워크플로우
- [/minor 워크플로우](../../commands/minor.md) - Minor feature 워크플로우

---

## 추가 도움말

### 질문이 있으신가요?

1. **README.md의 FAQ 섹션** 확인
2. **이 가이드의 관련 섹션** 참고
3. **Document Gate 스크립트 직접 확인**: `.claude/lib/document-gate/document-gate.sh`

### 버그 리포트

Document Gate에서 잘못된 오류를 보고하는 경우:
1. 재현 가능한 최소 예시 준비
2. 실행 로그 저장: `bash document-gate.sh <dir> 2>&1 | tee log.txt`
3. 이슈 생성 (파일 경로와 로그 포함)

---

**Version**: 1.0.0
**Last Updated**: 2025-11-25
**Author**: Claude Code
**Feature**: 005-document-gate (Epic 006)
