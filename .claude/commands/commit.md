# 🚀 Smart Commit Command

## Overview

Automatically generates semantic commit messages following Conventional Commits format by analyzing staged changes.

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

This command:
1. **Analyzes Changes**: Reviews all staged files and their modifications
2. **Generates Message**: Creates a concise, descriptive commit message
3. **Follows Standards**: Uses Conventional Commits format (feat, fix, chore, etc.)
4. **Includes Context**: Adds detailed body and co-authored-by information

**Key Features:**
- Automatic commit type detection (feat, fix, chore, docs, etc.)
- Scope inference from changed files
- Breaking change detection
- Multi-line body for complex changes
- Notion integration for changelog tracking

## Usage

```bash
/commit
```

The command will:
- Check git status
- Analyze staged changes
- Generate commit message
- Create commit with proper format

### Prerequisites

- Git repository initialized
- Changes staged (`git add` already run)
- Clean working directory (all changes either staged or ignored)

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

### Architecture

The command leverages the **documenter-unified** agent which combines:
- Changelog analysis for consistent style
- Git diff parsing for accurate change detection
- Conventional Commits format enforcement

### Dependencies

**Required:**
- Git: Version control system
- documenter-unified agent: Commit message generation

**Optional:**
- Notion MCP: For automatic changelog updates

### Workflow Steps

1. **Pre-checks**
   - Verify git repository exists
   - Confirm changes are staged
   - Check for conflicts or issues

2. **Analysis**
   - Read git diff for staged changes
   - Review recent commits for style consistency
   - Identify change patterns and scope

3. **Generation**
   - Determine commit type (feat/fix/chore/etc.)
   - Extract scope from file paths
   - Write concise subject line (max 72 chars)
   - Create detailed body if needed

4. **Commit**
   - Execute git commit with generated message
   - Add co-authored-by information
   - Run post-commit hooks if configured

### Related Resources

- **Agents**: documenter-unified
- **Format**: [Conventional Commits](https://www.conventionalcommits.org/)
- **Integration**: Notion MCP for changelog tracking

### Configuration

Uses Conventional Commits format:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `test`: Test additions or modifications
- `chore`: Build process or auxiliary tool changes

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

**Version**: 3.3.1
**Last Updated**: 2025-11-18
