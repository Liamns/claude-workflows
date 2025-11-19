# /pr - Pull Request 자동 생성

**Claude를 위한 필수 지시사항:**

이 명령어가 실행될 때 반드시 다음 단계를 **순서대로** 따라야 합니다:

1. git log와 git diff [base]...HEAD를 사용하여 초기 분석 수행
2. 브랜치 변경사항 전체를 분석하여 영향 범위 파악
3. PR 제목과 설명 생성 (Summary, Changes, Test Plan)
4. AskUserQuestion을 사용하여 PR 생성 전 사용자 확인 받기
5. 확인 후 gh pr create 실행

**절대로 브랜치 분석 단계를 건너뛰지 마세요.**

---

## 📋 다음 단계 추천 시 필수 규칙

### PR 생성 완료 후 리뷰 제안 시 AskUserQuestion 사용 (선택 사항)

PR 생성 완료 후, **즉시 리뷰를 시작할지** 물어볼 때 반드시 AskUserQuestion 도구를 사용하세요.
(이 단계는 선택 사항이며, 사용자 워크플로우에 따라 생략 가능)

**❌ 잘못된 예시:**
```
"PR이 생성되었습니다. 리뷰를 시작하시겠습니까?"
```

**✅ 올바른 예시:**
```
"PR이 생성되었습니다: [PR URL]"

[AskUserQuestion 호출 - 선택 사항]
- question: "PR 리뷰를 시작하시겠습니까?"
- header: "다음 단계"
- options: ["예, /pr-review 실행", "나중에"]
```

### 사용자 선택 후 자동 실행

**사용자가 "예" 또는 "실행"을 선택하면 즉시 /pr-review를 실행하세요:**

```javascript
{"0": "예, /pr-review 실행"}  → SlashCommand("/pr-review")
{"0": "리뷰 시작"}             → SlashCommand("/pr-review")
{"0": "나중에"}                → 실행 안 함
```

**참고**: 많은 경우 PR 생성 후 바로 리뷰하지 않고 다른 팀원의 리뷰를 기다리므로, 이 단계는 필수가 아닌 선택 사항입니다.

---

## Overview

커밋(commit) 히스토리와 코드 변경사항을 기반으로 지능형 설명과 함께 Pull Request를 자동으로 생성합니다.

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

이 커맨드는 다음을 수행합니다:
1. **브랜치(branch) 분석**: 베이스에서 분기한 이후 모든 커밋 검토
2. **요약 생성**: 포괄적인 PR 설명 작성
3. **PR 생성**: GitHub CLI를 사용하여 Pull Request 제출
4. **URL 반환**: 생성된 PR에 대한 직접 링크 제공

**주요 기능:**
- 베이스 브랜치 자동 감지 (main/master)
- 커밋 메시지로부터 스마트한 PR 제목 생성
- 변경 요약이 포함된 상세한 본문
- 테스트 계획(test plan) 생성
- 자동 라벨링 지원

## Usage

```bash
/pr [options]
```

### 옵션

| 옵션 | 설명 | 기본값 |
|-----------|-------------|---------|
| `--base <branch>` | 대상 브랜치 | `main` 또는 `master` (자동 감지) |
| `--draft` | 드래프트 PR 생성 | `false` |
| `--no-push` | PR 생성 전 푸시하지 않음 | `false` |

### 기본 명령어

```bash
/pr                      # main 브랜치로 PR 생성
/pr --base develop       # develop으로 PR 생성
/pr --draft              # 드래프트 PR 생성
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

### 아키텍처(Architecture)

**documenter-unified** 에이전트(agent)를 다음을 위해 사용합니다:
- 커밋 메시지 분석
- PR 설명 생성
- 변경사항 분류

### 의존성(Dependencies)

**필수:**
- 리모트가 있는 Git 저장소
- GitHub CLI (`gh`) 설치 및 인증
- 리모트에 푸시된 브랜치 (또는 `--no-push` 없이 사용)

**선택:**
- PR 템플릿: `.github/pull_request_template.md`
- 자동화된 검사를 위한 GitHub Actions

### 워크플로우 단계

1. **사전 점검**
   - Git 저장소 확인
   - GitHub CLI 인증 확인
   - 브랜치 존재 및 커밋 확인

2. **분석**
   - 커밋 히스토리 가져오기: `git log base...HEAD`
   - 변경사항 Diff: `git diff base...HEAD`
   - 변경 패턴 식별

3. **생성**
   - 커밋으로부터 PR 제목 생성
   - 요약 항목 생성
   - 테스트 계획 섹션 추가
   - 템플릿이 있으면 체크리스트 포함

4. **생성**
   - 필요시 브랜치 푸시
   - 실행: `gh pr create --title "..." --body "..."`
   - PR URL 반환

### 관련 리소스

- **에이전트**: documenter-unified.md
- **CLI**: GitHub CLI (`gh`)
- **템플릿**: `.github/pull_request_template.md`

## PR 설명 형식

### 자동 생성 구조

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

### 커스텀 템플릿 지원

`.github/pull_request_template.md`가 존재하는 경우:
- 템플릿의 섹션 보존
- 자동 생성된 컨텐츠가 플레이스홀더 채움
- 체크리스트 항목 자동 추가

## 팁 및 모범 사례

### PR 생성 전

```bash
# 1. 로컬에서 변경사항 리뷰
/review --adv

# 2. 테스트 통과 확인
npm test

# 3. 커밋 생성
/commit

# 4. PR 생성
/pr
```

### PR 제목 규칙

커밋으로부터 자동 감지:
- `feat:` → 기능(feature) 추가
- `fix:` → 버그 수정
- `docs:` → 문서
- `refactor:` → 코드 리팩토링
- `perf:` → 성능 개선

### 드래프트 사용 시점

- 진행 중인 작업(work in progress)
- 조기 피드백 필요
- 의존성(dependency)에 의해 차단됨
- 실험적 변경사항

## 에러 처리

### "gh not found"
- **원인**: GitHub CLI가 설치되지 않음
- **해결**: `brew install gh` (macOS) 설치 또는 https://cli.github.com/ 참조

### "Not authenticated"
- **원인**: GitHub CLI에 로그인하지 않음
- **해결**: `gh auth login` 실행

### "No commits to create PR"
- **원인**: 브랜치가 베이스와 동일
- **해결**: 먼저 커밋 생성 또는 베이스 브랜치 확인

### "Remote branch not found"
- **원인**: 브랜치가 푸시되지 않음
- **해결**: 커맨드가 자동 푸시하도록 하거나 `git push -u origin <branch>` 실행

## 워크플로우와의 통합

### Major 워크플로우

```bash
/major "new feature"
# ... 개발 ...
/commit
/pr  # 마지막에 자동으로 PR 생성
```

### Minor/Micro 워크플로우

```bash
/minor "fix login bug"
# ... 수정 적용 ...
/commit
/pr
```

### 수동 워크플로우

```bash
# 변경사항 만들기
git add .
/commit
/pr --draft  # 조기 피드백
# ... 코멘트 반영 ...
gh pr ready  # 리뷰 준비 완료로 표시
```

## 관련 커맨드

- `/commit` - PR 전 커밋 생성
- `/review` - PR 생성 전 코드 리뷰
- `/pr-review <number>` - 기존 PR 리뷰
- `/major`, `/minor`, `/micro` - PR 생성 포함

---

**Version**: 3.3.2
**Last Updated**: 2025-11-18
