# PR 자동 생성 커맨드

현재 브랜치의 변경사항을 분석하여 PR을 자동으로 생성합니다.

## 역할

1. **Git 분석**
   - 현재 브랜치의 모든 커밋 분석 (`git log main..HEAD` 또는 지정된 베이스 브랜치)
   - 커밋 타입별 그룹화 (feat, fix, refactor, docs, test 등)
   - Breaking changes 자동 감지
   - 이슈 번호 추출 (#123, closes #456 등)

2. **파일 분석**
   - Git diff로 변경된 파일 목록 확인
   - UI 변경 여부 감지 (.tsx, .css 등)
   - 테스트 파일 변경 감지 (*.test.ts 등)
   - 문서 변경 감지 (*.md)

3. **워크플로우 파일 읽기** (존재하는 경우)
   - `.specify/spec.md`: Overview, Summary 섹션 추출
   - `.specify/plan.md`: Implementation 섹션 추출
   - `.specify/tasks.md`: Verification 체크리스트 추출

4. **템플릿 자동 완성**
   - `.claude/templates/git/pr-template.md` 템플릿 로드
   - `.claude/templates/git/pr-auto-fill.yaml` 설정 참조
   - `.claude/templates/git/pr-sections-map.json` 매핑 규칙 적용
   - 각 섹션에 데이터 자동 삽입

5. **PR 생성**
   - `gh pr create` 명령어로 GitHub PR 생성
   - 자동 완성된 템플릿을 PR body로 사용
   - PR URL 반환

## 사용법

```bash
# 기본 사용 (main 브랜치 기준)
/pr

# 베이스 브랜치 지정
/pr --base develop

# 드래프트 PR 생성
/pr --draft

# 리뷰어 자동 할당
/pr --reviewers @user1,@user2

# 체크리스트 검증 실행 (type-check, test)
/pr --validate

# PR 생성 후 자동 리뷰
/pr --review

# 디버그 모드 (템플릿만 출력, PR 생성 안함)
/pr --dry-run
```

## 실행 흐름

### Step 1: 현재 브랜치 확인
- 현재 브랜치가 main/master가 아닌지 확인
- 베이스 브랜치 (기본값: main) 확인

### Step 2: Git 데이터 수집
다음 명령어들을 **병렬로 실행**하여 정보 수집:

```bash
# 커밋 히스토리
git log --oneline --no-merges main..HEAD

# 상세 커밋 메시지
git log --no-merges --format="%s%n%b" main..HEAD

# 변경된 파일 목록
git diff --name-only main..HEAD

# 변경된 파일 통계
git diff --stat main..HEAD
```

### Step 3: 워크플로우 파일 읽기
존재하는 파일만 읽기 (병렬 실행):

```bash
# 파일 존재 여부 확인 후 읽기
.specify/spec.md
.specify/plan.md
.specify/tasks.md
```

### Step 4: 템플릿 자동 완성

#### 📋 변경사항 섹션
```markdown
- [x] 새로운 기능 추가    # feat 커밋 있음
- [x] 버그 수정           # fix 커밋 있음
- [ ] 리팩터링
- [x] 문서 업데이트       # docs 커밋 있음
- [x] 테스트 추가/수정    # test 커밋 있음
```

#### 🎯 작업 내용 섹션
```markdown
{spec.md의 Overview 요약}

**주요 변경사항**:
- feat(auth): JWT 토큰 갱신 로직 추가
- fix(login): 세션 만료 처리 개선
- test(auth): 토큰 갱신 테스트 추가

{Breaking changes가 있다면}
**⚠️ Breaking Changes**:
- API 응답 형식 변경 (v2.0)
```

#### 🧪 테스트 섹션
```markdown
- [x] 단위 테스트 추가/수정 (AuthService.test.ts, LoginForm.test.tsx)
- [x] 통합 테스트 확인
- [x] 수동 테스트 완료
  {tasks.md의 Verification 체크리스트 내용 삽입}
```

#### 📸 스크린샷 섹션
- UI 변경 (.tsx, .css 등) 감지되면 유지
- UI 변경 없으면 이 섹션 제거

#### 📚 참고 자료 섹션
```markdown
- Closes #456
- Related: #123
- Spec: [.specify/spec.md](.specify/spec.md)
- Plan: [.specify/plan.md](.specify/plan.md)
- Tasks: [.specify/tasks.md](.specify/tasks.md)
{커밋 메시지에서 Notion 링크 추출}
```

#### ✅ 체크리스트 섹션
```markdown
- [x] 코딩 컨벤션 준수     # --validate 시 yarn type-check 실행
- [x] 테스트 통과          # --validate 시 yarn test 실행
- [x] 문서 업데이트        # .md 파일 변경 감지
- [ ] 성능 영향도 검토     # 수동 확인 필요
```

### Step 5: PR 제목 생성

**커밋이 1개인 경우**:
```
커밋 메시지를 그대로 사용
예: feat(auth): JWT 토큰 갱신 로직 추가
```

**커밋이 여러 개인 경우**:
```
가장 많은 커밋 타입을 사용하고 요약 생성
예: feat(auth): 사용자 인증 시스템 개선
```

### Step 6: PR 생성

```bash
# 템플릿 내용을 heredoc으로 전달
gh pr create \
  --title "{생성된 제목}" \
  --base {베이스 브랜치} \
  --body "$(cat <<'EOF'
{자동 완성된 템플릿 내용}
EOF
)"
```

### Step 7: 후속 작업 (옵션)

```bash
# --review 플래그가 있으면 PR 리뷰 자동 실행
/pr-review {생성된 PR 번호}

# 또는 사용자에게 질문
"PR이 생성되었습니다. 지금 바로 /pr-review를 실행하시겠습니까?"
```

## 설정 파일 참조

### pr-auto-fill.yaml
- 각 섹션별 자동 채우기 규칙
- 데이터 소스 우선순위
- 출력 포맷

### pr-sections-map.json
- 템플릿 섹션 구조 정의
- 데이터 소스 매핑
- 자동화 규칙

## 에러 처리

### 현재 브랜치가 main/master인 경우
```
❌ 에러: main/master 브랜치에서는 PR을 생성할 수 없습니다.
feature 브랜치를 생성하거나 다른 브랜치로 이동해주세요.
```

### 커밋이 없는 경우
```
❌ 에러: 베이스 브랜치와 비교하여 새로운 커밋이 없습니다.
변경사항을 커밋한 후 다시 시도해주세요.
```

### gh CLI가 설치되지 않은 경우
```
❌ 에러: GitHub CLI (gh)가 설치되어 있지 않습니다.
설치 방법: brew install gh
```

### gh 인증이 안된 경우
```
❌ 에러: GitHub CLI 인증이 필요합니다.
실행: gh auth login
```

## 출력 예시

```
🔍 현재 브랜치 분석 중...
  ✓ 브랜치: feature/auth-improvement
  ✓ 베이스: main
  ✓ 커밋 수: 5개

📊 변경사항 분석 중...
  ✓ feat: 2개
  ✓ fix: 1개
  ✓ test: 2개
  ✓ 변경된 파일: 8개

📄 워크플로우 파일 읽기...
  ✓ spec.md 발견
  ✓ tasks.md 발견
  ⚠ plan.md 없음 (건너뜀)

✍️ PR 템플릿 자동 완성 중...
  ✓ 변경사항 섹션 (3개 체크)
  ✓ 작업 내용 자동 생성
  ✓ 테스트 섹션 (tasks.md 연동)
  ✓ 참고 자료 (2개 이슈 링크)
  ✓ 체크리스트 자동 체크

🚀 PR 생성 중...
  ✓ 제목: feat(auth): 사용자 인증 시스템 개선
  ✓ PR 생성 완료!

🔗 PR URL: https://github.com/user/repo/pull/123

💡 다음 단계:
  - PR을 리뷰하고 필요한 부분 수정
  - /pr-review 123 으로 자동 코드 리뷰 실행
  - 스크린샷이 필요한 경우 추가
```

## 고급 사용법

### 템플릿 커스터마이징

템플릿을 프로젝트에 맞게 수정하려면:

1. `.claude/templates/git/pr-template.md` 수정
2. `.claude/templates/git/pr-auto-fill.yaml` 규칙 조정
3. 변경사항이 즉시 반영됨

### 다른 워크플로우와 통합

#### /major 워크플로우 완료 시
```markdown
# major 워크플로우 마지막 단계
...
6. PR 생성 (optional)
   - /pr --review 실행
   - 자동으로 코드 리뷰까지 완료
```

#### /commit 후 자동 PR
```bash
# 여러 커밋을 만든 후
/commit
/pr --draft  # 드래프트로 먼저 생성하여 확인
```

## 플래그 상세

| 플래그 | 설명 | 기본값 |
|-------|------|--------|
| `--base <branch>` | 베이스 브랜치 지정 | main |
| `--draft` | 드래프트 PR로 생성 | false |
| `--reviewers <users>` | 리뷰어 자동 할당 | 없음 |
| `--validate` | 체크리스트 검증 실행 | false |
| `--review` | PR 생성 후 자동 리뷰 | false |
| `--dry-run` | 템플릿만 출력 (PR 생성 안함) | false |
| `--no-footer` | Claude 생성 footer 제거 | false |

## 실행

**사용자가 `/pr` 또는 `/pr {플래그}`를 입력하면**:

1. 위의 Step 1-7을 순차적으로 실행
2. 진행 상황을 사용자에게 실시간으로 표시
3. PR이 성공적으로 생성되면 URL 반환
4. 에러가 발생하면 명확한 에러 메시지와 해결 방법 제시

**주의사항**:
- 모든 파일 읽기와 Git 명령어는 병렬로 실행하여 성능 최적화
- 선택적 파일(.specify/*.md)이 없어도 에러 없이 계속 진행
- 사용자가 수동으로 수정할 수 있도록 템플릿은 유연하게 생성
