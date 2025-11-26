---
name: commit
hooks:
  pre: .claude/hooks/commit-pre.sh
---

# 🚀 Smart Commit Command

> **참고**: 이 명령어는 `.claude/CLAUDE.md`의 규칙을 준수합니다.

**Claude를 위한 필수 지시사항:**

이 명령어가 실행될 때 반드시 다음 단계를 **순서대로** 따라야 합니다:

1. git status와 git diff를 사용하여 초기 분석 수행
2. 커밋 히스토리를 분석하여 커밋 메시지 패턴 파악
3. Conventional Commits 형식으로 커밋 메시지 생성
4. **⚠️ 커밋 메시지 전문(全文) 출력** - 반드시 생성된 커밋 메시지 전체를 사용자에게 보여주세요:
   ```
   === 생성된 커밋 메시지 ===
   <type>(<scope>): <subject>

   <body>

   🤖 Generated with [Claude Code](https://claude.com/claude-code)

   Co-Authored-By: Claude <noreply@anthropic.com>
   ===========================
   ```
5. AskUserQuestion을 사용하여 커밋 전 사용자 확인 받기:
   - question: "위 메시지로 커밋하시겠습니까?"
   - header: "커밋 확인"
   - options: ["예, 커밋 실행", "메시지 수정", "취소"]
6. 사용자 선택 처리:
   - "예, 커밋 실행" → 커밋 진행
   - "메시지 수정" → 수정 요청을 받고 다시 4번으로
   - "취소" → 커밋 중단

**절대로 커밋 메시지를 보여주지 않고 확인을 요청하지 마세요.**

---

## 📋 다음 단계 추천 시 필수 규칙

### 커밋 완료 후 PR 생성 제안 시 AskUserQuestion 사용

커밋 완료 후, **현재 브랜치가 feature 브랜치인 경우** (main/master/develop가 아닌 경우) PR 생성 여부를 물어볼 때 반드시 AskUserQuestion 도구를 사용하세요.

**❌ 잘못된 예시:**
```
"커밋이 완료되었습니다. PR을 생성하시겠습니까?"
```

**✅ 올바른 예시:**
```
"커밋이 완료되었습니다."

[AskUserQuestion 호출]
- question: "Pull Request를 생성하시겠습니까?"
- header: "다음 단계"
- options: ["예, /pr 실행", "나중에 수동으로"]
```

### 사용자 선택 후 자동 실행

**사용자가 "예" 또는 "실행"을 선택하면 즉시 /pr을 실행하세요:**

```javascript
{"0": "예, /pr 실행"}  → SlashCommand("/pr")
{"0": "PR 생성"}       → SlashCommand("/pr")
{"0": "나중에"}        → 실행 안 함, 안내만
```

**조건**: 현재 브랜치가 main, master, develop가 **아닐 때만** PR 생성 제안

---

## Overview

스테이징된 변경사항을 분석하여 Conventional Commits 형식을 따르는 의미 있는 커밋(commit) 메시지를 자동으로 생성합니다.

## Output Language

**IMPORTANT**: 사용자나 동료가 확인하는 모든 출력은 반드시 **한글로 작성**해야 합니다.

**한글 작성 대상:**
- 커밋 메시지 제목의 설명 부분 (콜론 `:` 이후)
- 커밋 메시지 본문 (body) - 변경 사항 상세 설명
- 진행 상황 메시지 및 안내
- 에러 메시지 및 경고

**영어 유지:**
- 커밋 타입 (feat, fix, chore, docs 등)
- 스코프 (auth, api, ui 등)
- 코드, 변수명, 함수명, 파일 경로

**예시:**
```
feat(auth): JWT 인증 시스템 추가

토큰 생성 및 검증 기능 구현
- 리프레시 토큰 메커니즘 추가
- 역할 기반 접근 제어 포함

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

이 커맨드는 다음을 수행합니다:
1. **변경사항 분석**: 모든 스테이징된 파일과 수정 내용을 검토합니다
2. **메시지 생성**: 간결하고 설명적인 커밋 메시지를 작성합니다
3. **표준 준수**: Conventional Commits 형식을 사용합니다 (feat, fix, chore 등)
4. **컨텍스트 포함**: 상세한 본문(body)과 co-authored-by 정보를 추가합니다

**주요 기능:**
- 자동 커밋 타입 감지 (feat, fix, chore, docs 등)
- 변경된 파일로부터 스코프 추론
- 호환성 파괴 변경(breaking change) 감지
- 복잡한 변경사항을 위한 여러 줄 본문
- Notion 연동을 통한 변경 로그(changelog) 추적

## Usage

```bash
/commit
```

이 커맨드는 다음을 수행합니다:
- Git 상태 확인
- 스테이징된 변경사항 분석
- 커밋 메시지 생성
- 올바른 형식으로 커밋 생성

### 사전 요구사항

- Git 저장소 초기화됨
- 변경사항 스테이징됨 (`git add` 이미 실행)
- 깨끗한 작업 디렉토리 (모든 변경사항이 스테이징되었거나 무시됨)

## Examples

### Example 1: Feature Addition

```bash
# After staging new authentication files
git add src/auth/
/commit
```

**Generated commit:**
```
feat(auth): add JWT authentication system

- Implement token generation and validation
- Add refresh token mechanism
- Include role-based access control

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Example 2: Bug Fix

```bash
# After fixing a login error
git add src/auth/login.ts
/commit
```

**Generated commit:**
```
fix(auth): resolve null pointer in login handler

- Add null check for user credentials
- Handle edge case for empty password field

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Example 3: Documentation Update

```bash
git add README.md
/commit
```

**Generated commit:**
```
docs: update installation instructions

- Add troubleshooting section
- Update dependency versions

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Implementation

### 아키텍처(Architecture)

이 커맨드는 **documenter-unified** 에이전트(agent)를 활용하며, 다음을 결합합니다:
- 일관된 스타일을 위한 변경 로그 분석
- 정확한 변경 감지를 위한 Git diff 파싱
- Conventional Commits 형식 강제

### 의존성(Dependencies)

**필수:**
- Git: 버전 관리 시스템
- documenter-unified 에이전트: 커밋 메시지 생성

**선택:**
- Notion MCP: 자동 변경 로그 업데이트

### 워크플로우 단계

1. **사전 점검**
   - Git 저장소 존재 여부 확인
   - 변경사항 스테이징 확인
   - 충돌 또는 이슈 확인

2. **분석**
   - 스테이징된 변경사항의 Git diff 읽기
   - 스타일 일관성을 위한 최근 커밋 검토
   - 변경 패턴 및 스코프 식별

3. **생성**
   - 커밋 타입 결정 (feat/fix/chore 등)
   - 파일 경로에서 스코프 추출
   - 간결한 제목 줄 작성 (최대 72자)
   - 필요 시 상세한 본문 작성

4. **커밋**
   - 생성된 메시지로 git commit 실행
   - Co-authored-by 정보 추가
   - 설정된 경우 post-commit 훅 실행

### 관련 리소스

- **에이전트**: documenter-unified
- **형식**: [Conventional Commits](https://www.conventionalcommits.org/)
- **연동**: 변경 로그 추적을 위한 Notion MCP

### 설정(Configuration)

Conventional Commits 형식 사용:
- `feat`: 새 기능(feature)
- `fix`: 버그 수정
- `docs`: 문서 변경
- `style`: 코드 스타일 변경 (포매팅 등)
- `refactor`: 코드 리팩토링
- `perf`: 성능 개선
- `test`: 테스트 추가 또는 수정
- `chore`: 빌드 프로세스 또는 보조 도구 변경

## 프로세스

1. **단계 1: Git 상태 확인**
   - `git status`로 staged 파일 확인
   - `git diff --staged`로 변경사항 분석

2. **단계 2: 커밋 타입 결정**
   - 파일 경로와 내용 기반 분류
   - Breaking change 여부 감지

3. **단계 3: 메시지 생성**
   - Subject: `<type>(<scope>): <description>`
   - Body: 변경 이유와 영향도
   - Footer: Breaking changes, references

4. **단계 4: 커밋 실행**
   - Git commit 실행
   - Pre-commit hook 검증 통과
   - 결과 확인

## 실제 사용 예시

### 시나리오 1: API 엔드포인트 추가

```bash
# 파일 변경
src/api/users.ts (새 파일)
src/routes/index.ts (수정)

# 커밋
/commit

# 결과
# feat(api): add user management endpoints
#
# - Implement GET /api/users
# - Implement POST /api/users
# - Add user validation middleware
```

### 시나리오 2: 긴급 버그 수정

```bash
# 파일 변경
src/utils/validation.ts (버그 수정)

# 커밋
/commit

# 결과
# fix(validation): prevent XSS in user input
#
# - Sanitize HTML tags from input fields
# - Add escape function for special characters
```

## 고급 기능

### Notion 연동

문서화 에이전트가 활성화된 경우:
- 커밋 메시지가 자동으로 Notion changelog에 기록
- 일자별 변경사항 추적
- 태그 기반 필터링 지원

### Breaking Change 감지

API 변경, 인터페이스 수정 등을 자동 감지하여:
- `BREAKING CHANGE:` footer 추가
- 버전 업그레이드 제안 (minor → major)

## 설정 옵션

커스터마이징 가능한 설정:
- **메시지 스타일**: Conventional Commits vs Angular vs Custom
- **Scope 규칙**: 파일 경로 기반 vs 수동 지정
- **Body 길이**: 제한 설정 가능

## 통계 및 분석

커밋 후 표시되는 정보:
- 변경된 파일 수
- 추가/삭제된 라인 수
- 커밋 해시
- 브랜치 정보

## 문제 해결

### "Nothing to commit" 에러
- **원인**: staged 파일 없음
- **해결**: `git add <files>` 실행 후 재시도

### "Pre-commit hook failed" 에러
- **원인**: 검증 실패 (lint, test 등)
- **해결**: 에러 메시지 확인 후 코드 수정

### 커밋 메시지가 부적절한 경우
- **원인**: 변경사항이 복잡하거나 일관성 없음
- **해결**: `git commit --amend`로 수동 수정

## 연동 워크플로우

### Major/Minor/Micro 워크플로우와 함께
```bash
/minor "fix: login error"
# ... 구현 완료 후
/commit  # 자동으로 적절한 메시지 생성
/pr      # PR 자동 생성
```

### Review와 함께
```bash
/review --staged  # 커밋 전 리뷰
/commit           # 리뷰 통과 후 커밋
```

## ✅ Pre-commit Validation Hook

Pre-commit hook이 설치된 경우 자동 검증:
- **Lint 검사**: 코드 스타일 확인
- **Type 검사**: TypeScript 타입 에러
- **Test 실행**: 관련 테스트 통과 확인
- **Format 검사**: Prettier/ESLint 규칙

설치 방법:
```bash
bash .claude/hooks/install-hooks.sh
```

---

**Version**: 4.0.0
**Last Updated**: 2025-11-18
