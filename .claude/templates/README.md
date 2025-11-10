# Claude Workflow Templates

프로젝트에서 사용하는 모든 템플릿과 자동화 규칙을 관리하는 디렉토리입니다.

## 📁 디렉토리 구조

```
.claude/templates/
├── git/
│   ├── pr-template.md          # GitHub PR 템플릿
│   ├── pr-auto-fill.yaml       # PR 자동 채우기 규칙
│   └── pr-sections-map.json    # 섹션-데이터 매핑
└── README.md                   # 이 문서
```

## 🎯 개요

이 템플릿 시스템은 다음을 자동화합니다:

1. **커밋 메시지 일관성**: Conventional Commits 형식 준수 (`/commit`)
2. **PR 설명 자동 생성**: Git 커밋과 워크플로우 파일에서 PR body 자동 작성 (`/pr`)
3. **코드 리뷰 효율화**: 체크리스트와 참고 자료 자동 추가
4. **문서화 자동화**: spec.md, tasks.md와 자동 연동

## 🚀 빠른 시작

### PR 생성

```bash
# 1. 변경사항 커밋
/commit

# 2. PR 자동 생성
/pr

# 3. (선택) PR 생성과 동시에 코드 리뷰
/pr --review
```

### 워크플로우 통합

```bash
# Major 워크플로우 완료 후
/major
# ... 작업 완료 ...
/pr --review  # PR 생성 및 자동 리뷰
```

## 📋 PR 템플릿 시스템

### 템플릿 구조 (pr-template.md)

```markdown
## 📋 변경사항
- [ ] 새로운 기능 추가
- [ ] 버그 수정
- [ ] 리팩터링
- [ ] 문서 업데이트
- [ ] 테스트 추가/수정

## 🎯 작업 내용
<!-- 자동 생성: spec.md + 커밋 메시지 -->

## 🧪 테스트
- [ ] 단위 테스트 추가/수정
- [ ] 통합 테스트 확인
- [ ] 수동 테스트 완료

## 📸 스크린샷 (UI 변경시)
<!-- UI 변경 감지 시 자동 활성화 -->

## 📚 참고 자료
<!-- 이슈 링크, spec/plan/tasks 자동 연결 -->

## ✅ 체크리스트
- [ ] 코딩 컨벤션 준수
- [ ] 테스트 통과
- [ ] 문서 업데이트
- [ ] 성능 영향도 검토
```

### 자동 채우기 규칙 (pr-auto-fill.yaml)

각 섹션을 자동으로 채우는 규칙을 정의합니다:

#### 1. 📋 변경사항 섹션

**자동 체크 로직**:
- `feat:` 커밋 → "새로운 기능 추가" 체크
- `fix:` 커밋 → "버그 수정" 체크
- `refactor:` 커밋 → "리팩터링" 체크
- `docs:` 커밋 → "문서 업데이트" 체크
- `test:` 커밋 → "테스트 추가/수정" 체크

**예시**:
```markdown
- [x] 새로운 기능 추가    # feat 커밋 3개
- [x] 버그 수정           # fix 커밋 1개
- [ ] 리팩터링
- [x] 문서 업데이트       # docs 커밋 1개
- [x] 테스트 추가/수정    # test 커밋 2개
```

#### 2. 🎯 작업 내용 섹션

**데이터 소스** (우선순위 순):
1. `.specify/spec.md`의 Overview 섹션
2. Git 커밋 메시지 (타입별 그룹화)
3. `.specify/plan.md`의 Implementation 섹션
4. Breaking changes 자동 감지

**예시**:
```markdown
사용자 인증 시스템을 개선하여 보안과 사용자 경험을 향상시킵니다.

**주요 변경사항**:
- feat(auth): JWT 토큰 갱신 로직 추가
- feat(auth): 다중 디바이스 로그인 지원
- fix(login): 세션 만료 처리 개선
- test(auth): 토큰 갱신 및 로그인 테스트 추가

**⚠️ Breaking Changes**:
- API 응답 형식 변경 (v1.0 → v2.0)
- 기존 토큰은 2025-12-01부터 무효화됨
```

#### 3. 🧪 테스트 섹션

**데이터 소스**:
1. `.specify/tasks.md`의 Verification 체크리스트
2. Git diff에서 테스트 파일 변경 감지

**예시**:
```markdown
- [x] 단위 테스트 추가/수정
  - AuthService.test.ts
  - LoginForm.test.tsx
  - TokenManager.test.ts
- [x] 통합 테스트 확인
  - E2E 로그인 플로우 테스트
- [x] 수동 테스트 완료
  - ✅ Chrome/Safari에서 로그인 확인
  - ✅ 토큰 만료 시나리오 테스트
  - ✅ 다중 디바이스 동시 로그인 테스트
```

#### 4. 📸 스크린샷 섹션

**UI 변경 감지**:
- `.tsx`, `.jsx`, `.vue`, `.html`, `.css`, `.scss` 파일 변경 시 활성화
- UI 변경이 없으면 이 섹션 자동 제거

**예시** (UI 변경 있을 때):
```markdown
## 📸 스크린샷 (UI 변경시)
<!-- ⚠️ UI 변경이 감지되었습니다. 변경 전후 스크린샷을 추가해주세요 -->

### 변경 전
[여기에 스크린샷 추가]

### 변경 후
[여기에 스크린샷 추가]
```

#### 5. 📚 참고 자료 섹션

**데이터 소스**:
1. 커밋 메시지에서 이슈 번호 추출
2. `.specify/spec.md`의 Research 링크
3. 커밋 메시지에서 Notion 링크 추출
4. spec/plan/tasks 파일 자동 링크

**예시**:
```markdown
- Closes #456
- Related: #123, #234
- Spec: [.specify/spec.md](.specify/spec.md)
- Plan: [.specify/plan.md](.specify/plan.md)
- Tasks: [.specify/tasks.md](.specify/tasks.md)
- Notion: [인증 시스템 설계](https://notion.so/auth-system-design)
```

#### 6. ✅ 체크리스트 섹션

**자동 검증** (`--validate` 플래그 사용 시):
- `yarn type-check` 통과 → "코딩 컨벤션 준수" 체크
- `yarn test` 통과 → "테스트 통과" 체크
- `.md` 파일 변경 → "문서 업데이트" 체크
- "성능 영향도 검토"는 항상 수동

**예시**:
```markdown
- [x] 코딩 컨벤션 준수     # type-check 통과
- [x] 테스트 통과          # yarn test 통과
- [x] 문서 업데이트        # README.md 수정됨
- [ ] 성능 영향도 검토     # 수동 확인 필요
```

## 🔧 사용법

### 기본 사용

```bash
# 현재 브랜치의 PR 생성
/pr
```

### 플래그 옵션

```bash
# 베이스 브랜치 지정
/pr --base develop

# 드래프트 PR로 생성
/pr --draft

# 리뷰어 자동 할당
/pr --reviewers @user1,@user2

# 체크리스트 검증 실행 (type-check, test)
/pr --validate

# PR 생성 후 자동 코드 리뷰
/pr --review

# 템플릿만 미리보기 (PR 생성 안함)
/pr --dry-run
```

### 실행 흐름

1. **Git 분석**
   ```bash
   git log main..HEAD        # 커밋 히스토리
   git diff main..HEAD       # 변경 파일
   ```

2. **워크플로우 파일 읽기**
   ```bash
   .specify/spec.md          # 기능 명세
   .specify/plan.md          # 구현 계획
   .specify/tasks.md         # 작업 목록
   ```

3. **템플릿 자동 완성**
   - 각 섹션에 데이터 자동 삽입
   - 조건부 섹션 처리 (UI 변경 등)
   - Breaking changes 강조

4. **PR 생성**
   ```bash
   gh pr create \
     --title "feat(auth): 사용자 인증 시스템 개선" \
     --body "{자동 완성된 템플릿}"
   ```

5. **결과 출력**
   ```
   🔗 PR URL: https://github.com/user/repo/pull/123
   ```

## 📚 설정 파일 상세

### pr-auto-fill.yaml

PR 자동 채우기 규칙을 정의하는 YAML 파일입니다.

**주요 섹션**:
- `changes_detection`: 변경사항 타입 매핑
- `description_generation`: 작업 내용 생성 규칙
- `test_generation`: 테스트 섹션 자동 완성
- `screenshots`: UI 변경 감지 설정
- `references_generation`: 참고 자료 자동 링크
- `checklist_validation`: 체크리스트 검증 규칙
- `pr_options`: PR 생성 기본 옵션

**커스터마이징 방법**:
```yaml
# 예: 커밋 타입 매핑 변경
changes_detection:
  commit_type_mapping:
    feat: "새로운 기능 추가"
    feature: "새로운 기능 추가"  # 별칭 추가
    hotfix: "긴급 버그 수정"    # 새 타입 추가
```

### pr-sections-map.json

템플릿 섹션과 데이터 소스를 매핑하는 JSON 파일입니다.

**주요 구조**:
```json
{
  "sections": [
    {
      "id": "changes",
      "emoji": "📋",
      "data_sources": [...],
      "automation": {...}
    }
  ]
}
```

**데이터 소스 타입**:
- `git_commits`: Git 커밋 메시지 분석
- `git_diff`: 파일 변경 감지
- `spec_file`: spec.md 파일 읽기
- `plan_file`: plan.md 파일 읽기
- `tasks_file`: tasks.md 파일 읽기
- `command_execution`: 명령어 실행 결과
- `manual`: 수동 입력 필요

## 🎨 템플릿 커스터마이징

### 1. 템플릿 수정

`.claude/templates/git/pr-template.md`를 직접 편집:

```markdown
## 🔥 새로운 섹션 추가
<!-- 프로젝트 특화 섹션 -->

## 📋 변경사항
<!-- 기존 섹션 수정 -->
```

### 2. 자동 채우기 규칙 추가

`pr-auto-fill.yaml`에 새 규칙 추가:

```yaml
custom_section:
  sources:
    - type: git_diff
      patterns: ["migrations/**"]
      format: "데이터베이스 마이그레이션 포함"
```

### 3. 새 데이터 소스 추가

`pr-sections-map.json`에 매핑 추가:

```json
{
  "id": "database",
  "title": "데이터베이스 변경",
  "data_sources": [
    {
      "source": "git_diff",
      "patterns": ["migrations/**", "schema.prisma"]
    }
  ]
}
```

## 🔗 워크플로우 통합

### /major 워크플로우와 통합

Major 워크플로우 완료 후 PR 자동 생성:

```markdown
# .claude/workflows/major.md 마지막 단계

6. PR 생성 및 리뷰
   - /pr --review
   - spec.md, tasks.md 자동 연동
   - 코드 리뷰 자동 실행
```

### /commit 커맨드와 연계

```bash
# 변경사항 커밋
/commit

# 여러 커밋 후 PR 생성
/pr

# 또는 한번에
/commit && /pr --draft
```

### /pr-review와 연계

```bash
# PR 생성과 동시에 리뷰
/pr --review

# 또는 따로
/pr
/pr-review 123
```

## 📊 예시 시나리오

### 시나리오 1: 새 기능 개발

```bash
# 1. Major 워크플로우 시작
/major

# 2. 작업 완료 후 커밋
/commit

# 3. PR 생성 및 리뷰
/pr --review
```

**생성되는 PR**:
```markdown
## 📋 변경사항
- [x] 새로운 기능 추가

## 🎯 작업 내용
{spec.md Overview 내용}

**주요 변경사항**:
- feat(feature): 새 기능 구현

## 🧪 테스트
- [x] 단위 테스트 추가/수정
  {tasks.md Verification 내용}

## 📚 참고 자료
- Spec: [.specify/spec.md](.specify/spec.md)
- Tasks: [.specify/tasks.md](.specify/tasks.md)

## ✅ 체크리스트
- [x] 코딩 컨벤션 준수
- [x] 테스트 통과
- [x] 문서 업데이트
- [ ] 성능 영향도 검토
```

### 시나리오 2: 버그 수정

```bash
# 1. 버그 수정 작업
# ... 코드 수정 ...

# 2. 커밋
/commit

# 3. 빠른 PR 생성
/pr --base main
```

**생성되는 PR**:
```markdown
## 📋 변경사항
- [x] 버그 수정

## 🎯 작업 내용
fix(component): null 참조 에러 수정

## 🧪 테스트
- [x] 단위 테스트 추가/수정
  - Component.test.tsx 수정

## 📚 참고 자료
- Closes #456

## ✅ 체크리스트
- [x] 코딩 컨벤션 준수
- [x] 테스트 통과
- [ ] 문서 업데이트
- [ ] 성능 영향도 검토
```

### 시나리오 3: UI 개선

```bash
# UI 변경 작업 후
/pr --draft  # 드래프트로 먼저 생성
```

**생성되는 PR** (스크린샷 섹션 포함):
```markdown
## 📋 변경사항
- [x] 새로운 기능 추가
- [x] 리팩터링

## 🎯 작업 내용
UI 컴포넌트 리디자인

## 🧪 테스트
...

## 📸 스크린샷 (UI 변경시)
<!-- ⚠️ UI 변경이 감지되었습니다. 변경 전후 스크린샷을 추가해주세요 -->

## 📚 참고 자료
...
```

## 🐛 트러블슈팅

### 문제: PR 템플릿이 자동 완성되지 않음

**원인**: 설정 파일을 찾을 수 없음

**해결**:
```bash
# 파일 존재 확인
ls -la .claude/templates/git/

# 없으면 다시 생성
mkdir -p .claude/templates/git
```

### 문제: 커밋 타입이 제대로 인식되지 않음

**원인**: Conventional Commits 형식이 아님

**해결**:
```bash
# /commit 커맨드 사용
/commit

# 또는 수동으로 형식 맞추기
git commit -m "feat(scope): description"
```

### 문제: spec.md 내용이 PR에 포함되지 않음

**원인**: spec.md 파일이 없거나 Overview 섹션이 없음

**해결**:
```bash
# spec.md 확인
cat .specify/spec.md

# /major 워크플로우로 spec.md 생성
/major
```

### 문제: gh pr create 실패

**원인**: GitHub CLI 인증 문제

**해결**:
```bash
# gh CLI 설치 확인
gh --version

# 인증
gh auth login

# 권한 확인
gh auth status
```

## 📖 추가 리소스

### 관련 커맨드
- `/commit`: Conventional Commits 형식으로 커밋 생성
- `/pr`: PR 자동 생성 (이 문서의 주제)
- `/pr-review`: PR 자동 코드 리뷰
- `/major`: 전체 개발 워크플로우

### 설정 파일
- `.claude/templates/git/pr-template.md`: PR 템플릿
- `.claude/templates/git/pr-auto-fill.yaml`: 자동 채우기 규칙
- `.claude/templates/git/pr-sections-map.json`: 섹션 매핑
- `.claude/commands/pr.md`: /pr 커맨드 구현

### 외부 링크
- [Conventional Commits](https://www.conventionalcommits.org/)
- [GitHub CLI 문서](https://cli.github.com/manual/)
- [GitHub PR 템플릿 가이드](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository)

## 🚀 다음 단계

1. **템플릿 테스트**
   ```bash
   # 테스트 브랜치 생성
   git checkout -b test/pr-template

   # 샘플 커밋
   echo "test" > test.txt
   git add test.txt
   /commit

   # PR 템플릿 미리보기
   /pr --dry-run
   ```

2. **프로젝트에 맞게 커스터마이징**
   - `pr-template.md` 섹션 추가/수정
   - `pr-auto-fill.yaml` 규칙 조정
   - 팀 컨벤션 반영

3. **팀원과 공유**
   - 템플릿 사용법 공유
   - 피드백 수집
   - 지속적 개선

---

**마지막 업데이트**: 2025-11-10
**버전**: 1.0.0
