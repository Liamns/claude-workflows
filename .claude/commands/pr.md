# /pr - Pull Request Auto-Creation

## Overview

Automatically creates pull requests with intelligent descriptions based on commit history and code changes.

## Output Language

**IMPORTANT**: 사용자나 동료가 확인하는 모든 출력은 반드시 **한글로 작성**해야 합니다.

**한글 작성 대상:**
- PR 제목의 설명 부분 (콜론 `:` 이후)
- PR 본문 전체 (Summary, Changes, Test Plan 등)
- 진행 상황 메시지
- 에러 메시지 및 경고

**영어 유지:**
- PR 제목의 타입과 스코프 (feat, fix 등)
- 코드, 파일 경로
- 명령어

**예시:**
```markdown
제목: feat(auth): JWT 인증 시스템 추가

## 요약
- JWT 기반 인증 시스템 구현
- 리프레시 토큰 메커니즘 추가
- 역할 기반 접근 제어 구현

## 변경 사항
- `src/auth/`: 새로운 인증 모듈
- `src/middleware/auth.ts`: JWT 검증 미들웨어
- `tests/auth.test.ts`: 인증 테스트 suite

## 테스트 계획
- [ ] 수동: 유효한 자격 증명으로 로그인
- [ ] 수동: 토큰 만료 확인
- [ ] 자동: `npm test` 실행
- [ ] 자동: CI/CD 파이프라인 확인

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

This command:
1. **Analyzes Branch**: Reviews all commits since divergence from base
2. **Generates Summary**: Creates comprehensive PR description
3. **Creates PR**: Uses GitHub CLI to submit pull request
4. **Returns URL**: Provides direct link to created PR

**Key Features:**
- Auto-detect base branch (main/master)
- Smart PR title from commit messages
- Detailed body with change summary
- Test plan generation
- Automatic labeling support

## Usage

```bash
/pr [options]
```

### Options

| Option | Description | Default |
|-----------|-------------|---------|
| `--base <branch>` | Target branch | `main` or `master` (auto-detected) |
| `--draft` | Create as draft PR | `false` |
| `--no-push` | Don't push before creating PR | `false` |

### Basic Commands

```bash
/pr                      # Create PR to main branch
/pr --base develop       # Create PR to develop
/pr --draft              # Create draft PR
```

## Examples

### Example 1: Basic PR Creation

```bash
/pr
```

**Output:**
```
📊 Analyzing branch: feature/user-auth
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Base branch: main
Commits: 6
Files changed: 12
+ Additions: 450
- Deletions: 89

🔍 Generating PR description...

📝 Creating pull request...

✅ Pull Request Created!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Title: feat: Add JWT authentication system

URL: https://github.com/user/repo/pull/42

Next steps:
  - Review the PR description
  - Request reviewers
  - Wait for CI/CD checks
```

### Example 2: PR with Custom Base

```bash
/pr --base develop
```

**Creates PR targeting `develop` branch instead of `main`**

### Example 3: Draft PR

```bash
/pr --draft
```

**Creates draft PR for early feedback:**
```
📝 Creating draft pull request...

✅ Draft PR Created!

Title: [DRAFT] feat: Add payment integration

URL: https://github.com/user/repo/pull/43

ℹ️  Mark as "Ready for review" when complete
```

## Implementation

### Architecture

Uses **documenter-unified** agent for:
- Commit message analysis
- PR description generation
- Change categorization

### Dependencies

**Required:**
- Git repository with remote
- GitHub CLI (`gh`) installed and authenticated
- Branch pushed to remote (or use without `--no-push`)

**Optional:**
- PR template: `.github/pull_request_template.md`
- GitHub Actions for automated checks

### Workflow Steps

1. **Pre-checks**
   - Verify git repository
   - Check GitHub CLI authentication
   - Ensure branch exists and has commits

2. **Analysis**
   - Get commit history: `git log base...HEAD`
   - Diff changes: `git diff base...HEAD`
   - Identify change patterns

3. **Generation**
   - Create PR title from commits
   - Generate summary bullets
   - Add test plan section
   - Include checklist if template exists

4. **Creation**
   - Push branch if needed
   - Execute: `gh pr create --title "..." --body "..."`
   - Return PR URL

### Related Resources

- **Agent**: documenter-unified.md
- **CLI**: GitHub CLI (`gh`)
- **Template**: `.github/pull_request_template.md`

## PR Description Format

### Auto-Generated Structure

```markdown
## Summary
- Added JWT authentication with refresh tokens
- Implemented role-based access control
- Created login/logout endpoints

## Changes
- `src/auth/`: New authentication module
- `src/middleware/auth.ts`: JWT verification middleware
- `tests/auth.test.ts`: Authentication test suite

## Test Plan
- [ ] Manual: Login with valid credentials
- [ ] Manual: Verify token expiration
- [ ] Automated: Run `npm test`
- [ ] Automated: Check CI/CD pipeline

## Related Issues
Closes #123

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

### Custom Template Support

If `.github/pull_request_template.md` exists:
- Sections from template are preserved
- Auto-generated content fills in placeholders
- Checklist items added automatically

## Tips & Best Practices

### Before Creating PR

```bash
# 1. Review changes locally
/review --adv

# 2. Ensure tests pass
npm test

# 3. Create commit
/commit

# 4. Create PR
/pr
```

### PR Title Conventions

Auto-detected from commits:
- `feat:` → Feature addition
- `fix:` → Bug fix
- `docs:` → Documentation
- `refactor:` → Code refactoring
- `perf:` → Performance improvement

### When to Use Draft

- Work in progress
- Need early feedback
- Blocked by dependencies
- Experimental changes

## Error Handling

### "gh not found"
- **Cause**: GitHub CLI not installed
- **Fix**: Install with `brew install gh` (macOS) or see https://cli.github.com/

### "Not authenticated"
- **Cause**: GitHub CLI not logged in
- **Fix**: Run `gh auth login`

### "No commits to create PR"
- **Cause**: Branch same as base
- **Fix**: Make commits first or check base branch

### "Remote branch not found"
- **Cause**: Branch not pushed
- **Fix**: Let command auto-push or run `git push -u origin <branch>`

## Integration with Workflows

### Major Workflow

```bash
/major "new feature"
# ... development ...
/commit
/pr  # Auto-creates PR at the end
```

### Minor/Micro Workflows

```bash
/minor "fix login bug"
# ... fix applied ...
/commit
/pr
```

### Manual Workflow

```bash
# Make changes
git add .
/commit
/pr --draft  # Early feedback
# ... address comments ...
gh pr ready  # Mark as ready for review
```

## Related Commands

- `/commit` - Create commit before PR
- `/review` - Review code before creating PR
- `/pr-review <number>` - Review existing PR
- `/major`, `/minor`, `/micro` - Include PR creation

---

**Version**: 3.3.1
**Last Updated**: 2025-11-18
