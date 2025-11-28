---
name: branch
description: 브랜치 관리 전용 명령어 (문맥 기반 처리)
---

# /branch - 브랜치 관리

> **참고**: 이 명령어는 `.claude/CLAUDE.md`의 규칙을 준수합니다.

브랜치 생성, 전환, 상태 확인을 문맥 기반으로 처리합니다.

## Critical Rules

### 1. 서브커맨드 금지
- `/branch create`, `/branch switch` 등 서브커맨드 사용 안 함
- 입력된 인자를 분석하여 동작 결정

### 2. 인자 분석 순서 (반드시 이 순서로 판단)

```
1. 인자 없음?
   → 상태 표시 (현재 브랜치, 변경사항, 미푸시 커밋)

2. --list 플래그?
   → 브랜치 목록 표시

3. 기존 브랜치명인지 확인 (git branch -a로 검증)
   → 존재하면: 브랜치 전환
   → 존재하지 않으면: 브랜치 생성

4. 브랜치 생성 시 이름 분석 (Git 표준 컨벤션: <type>/<description>)
   → fix, bug 키워드 포함? → fix/{description}
   → hotfix 키워드 포함? → hotfix/{description}
   → refactor 키워드 포함? → refactor/{description}
   → docs 키워드 포함? → docs/{description}
   → chore 키워드 포함? → chore/{description}
   → 그 외 (Feature) → feat/{description}
```

### 3. 브랜치 타입 (Git 표준 컨벤션)

| Type | 사용 시점 | 예시 |
|------|----------|------|
| `feat/` | 새로운 기능 추가 | `feat/user-auth` |
| `fix/` | 버그 수정 | `fix/login-bug` |
| `hotfix/` | 긴급 수정 | `hotfix/critical-error` |
| `refactor/` | 코드 리팩토링 | `refactor/auth-cleanup` |
| `docs/` | 문서 수정 | `docs/readme-update` |
| `chore/` | 빌드, 설정 등 | `chore/ci-config` |

### 4. 변경사항 처리
- 브랜치 전환/생성 전 uncommitted changes 확인
- 변경사항 있으면 **반드시** AskUserQuestion으로 처리 방법 선택

### 5. AskUserQuestion 필수 사용
- 변경사항 처리 옵션 제시
- 한글 입력 시 영문 브랜치명 확인
- 불확실한 상황에서 사용자 확인

---

## 사용법

```bash
/branch                        # 현재 상태 표시
/branch --list                 # 브랜치 목록
/branch main                   # main으로 전환
/branch "user-auth"            # feat/user-auth 브랜치 생성
/branch "로그인 버그 수정"      # fix/login-bug 브랜치 생성 (키워드 감지)
/branch "refactor auth"        # refactor/auth 브랜치 생성
```

---

## 실행 순서

### Step 1: 인자 파싱

```bash
# 인자 확인
args="$1"

if [[ -z "$args" ]]; then
  # 상태 표시 모드
  mode="status"
elif [[ "$args" == "--list" ]]; then
  # 목록 표시 모드
  mode="list"
else
  # 브랜치명으로 판단
  # 기존 브랜치인지 확인
  if git show-ref --verify --quiet "refs/heads/$args" 2>/dev/null || \
     git show-ref --verify --quiet "refs/remotes/origin/$args" 2>/dev/null; then
    mode="switch"
  else
    mode="create"
  fi
fi
```

### Step 2: 모드별 실행

#### 상태 표시 (mode=status)

```bash
current_branch=$(git branch --show-current)
changes=$(git status --porcelain | wc -l | tr -d ' ')
unpushed=$(git log origin/$current_branch..$current_branch --oneline 2>/dev/null | wc -l | tr -d ' ')

echo "📍 현재 브랜치: $current_branch"
echo "📝 변경사항: ${changes}개 파일"
echo "📤 미푸시 커밋: ${unpushed}개"
```

#### 목록 표시 (mode=list)

```bash
echo "📋 브랜치 목록"
echo ""
git branch -vv --sort=-committerdate | head -10
```

#### 브랜치 전환 (mode=switch)

1. 변경사항 확인
2. 변경사항 있으면 → AskUserQuestion
3. 선택에 따라 처리 후 전환

#### 브랜치 생성 (mode=create)

1. 변경사항 확인
2. 이름 분석 (fix 키워드 확인)
3. 다음 번호 할당
4. 브랜치 생성

---

## 상태 표시 (인자 없음)

`/branch` 실행 시 다음 정보를 표시합니다:

```
📍 현재 브랜치: feat/user-auth
📝 변경사항: 3개 파일
📤 미푸시 커밋: 2개
🔗 연결된 Epic: 없음
```

### 구현

```bash
# 현재 브랜치
current=$(git branch --show-current)

# 변경사항 수
changes=$(git status --porcelain | wc -l | tr -d ' ')

# 미푸시 커밋 수
if git rev-parse --verify origin/$current &>/dev/null; then
  unpushed=$(git log origin/$current..$current --oneline | wc -l | tr -d ' ')
else
  unpushed="(원격 브랜치 없음)"
fi

# Epic 연결 확인
if [[ -d ".specify/epics" ]]; then
  epic_count=$(ls -d .specify/epics/*/ 2>/dev/null | wc -l | tr -d ' ')
  if [[ $epic_count -gt 0 ]]; then
    epic_info="${epic_count}개 Epic 존재"
  else
    epic_info="없음"
  fi
else
  epic_info="없음"
fi
```

---

## 브랜치 목록 (--list)

`/branch --list` 실행 시:

```
📋 브랜치 목록

* feat/user-auth (현재)
  feat/payment-integration
  fix/login-bug
  main

최근 작업: feat/user-auth (2시간 전)
```

### 구현

```bash
echo "📋 브랜치 목록"
echo ""

# 최근 수정 순으로 정렬
git branch -vv --sort=-committerdate | while read line; do
  if [[ "$line" == \** ]]; then
    echo "* ${line:2} (현재)"
  else
    echo "  $line"
  fi
done | head -15

echo ""
echo "최근 작업: $(git branch --sort=-committerdate | head -1 | tr -d '* ')"
```

---

## 브랜치 전환

### 변경사항 없을 때

```bash
git switch "$target_branch"
echo "✅ $target_branch 브랜치로 전환되었습니다"
```

### 변경사항 있을 때

**반드시 AskUserQuestion 호출:**

```
question: "변경사항이 있습니다. 어떻게 처리하시겠습니까?"
header: "변경사항 처리"
options:
  - label: "커밋 후 전환"
    description: "현재 변경사항을 커밋하고 전환"
  - label: "변경사항과 함께 이동"
    description: "변경사항을 유지한 채 전환 (충돌 가능)"
  - label: "Stash 후 전환"
    description: "변경사항을 임시 저장하고 전환"
  - label: "변경사항 삭제"
    description: "⚠️ 복구 불가 - 모든 변경사항 삭제"
  - label: "취소"
    description: "전환 취소"
```

### 선택별 처리

| 선택 | 처리 |
|------|------|
| 커밋 후 전환 | `git add -A && git commit` → `git switch` |
| 변경사항과 함께 이동 | `git switch` (충돌 시 안내) |
| Stash 후 전환 | `git stash push -m "auto-stash"` → `git switch` |
| 변경사항 삭제 | `git checkout -- .` → `git switch` |
| 취소 | 종료 |

---

## 브랜치 생성

### 이름 분석 로직

```bash
input="$1"

# 1. 타입 키워드 감지 (우선순위 순)
if echo "$input" | grep -qiE '(hotfix|긴급)'; then
  branch_type="hotfix"
elif echo "$input" | grep -qiE '(fix|bug|버그|수정|오류)'; then
  branch_type="fix"
elif echo "$input" | grep -qiE '(refactor|리팩토링|정리)'; then
  branch_type="refactor"
elif echo "$input" | grep -qiE '(docs|문서)'; then
  branch_type="docs"
elif echo "$input" | grep -qiE '(chore|설정|빌드)'; then
  branch_type="chore"
else
  branch_type="feat"
fi

# 2. description 추출 (타입 키워드 제거 후 kebab-case 변환)
# 한글 입력 시 AskUserQuestion으로 영문명 확인
if echo "$input" | grep -qP '[가-힣]'; then
  # 한글 포함 → 사용자에게 영문명 확인
  need_confirm=true
else
  # 영문만 → 자동 변환 (타입 키워드 제거)
  description=$(echo "$input" | sed -E 's/(fix|bug|hotfix|refactor|docs|chore)[:. ]*//gi' | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g' | sed 's/^-//' | sed 's/-$//')
fi

# 3. 최종 브랜치명 생성: <type>/<description>
final_branch="${branch_type}/${description}"
```

### 한글 입력 처리

한글이 포함된 경우 **반드시 AskUserQuestion 호출:**

```
question: "브랜치명을 영문으로 입력해주세요. 예: 'login-bug'"
header: "브랜치명 확인"
options:
  - label: "직접 입력"
    description: "영문 브랜치명을 직접 입력"
```

또는 Claude가 자동 번역하여 확인:

```
question: "'로그인 버그 수정' → 'fix/login-bug'로 생성할까요?"
header: "브랜치명 확인"
options:
  - label: "확인"
    description: "fix/login-bug 브랜치 생성"
  - label: "다른 이름"
    description: "다른 이름으로 변경"
  - label: "취소"
    description: "브랜치 생성 취소"
```

---

## 스크립트 연동

기존 스크립트를 재사용합니다:

### branch-state-handler.sh

```bash
source .claude/lib/branch-state-handler.sh

# 변경사항 처리
handle_dirty_state "$target_branch"

# 브랜치 생성
handle_branch_creation "$branch_name" "$base_branch"
```

### git-operations.sh

```bash
source .claude/lib/git-operations.sh

# 브랜치 생성
create_branch_from_base "$branch_name" "main"

# 변경사항과 함께 이동
move_changes_to_new_branch "$branch_name"

# Stash
auto_stash "branch-switch"

# 커밋
auto_commit "WIP: before branch switch"
```

---

## 예시

### Feature 브랜치 생성

```bash
/branch "user-auth"
# → feat/user-auth 브랜치 생성

/branch "payment integration"
# → feat/payment-integration 브랜치 생성
```

### Fix 브랜치 생성 (키워드 자동 감지)

```bash
/branch "login bug"
# → fix/login-bug 브랜치 생성

/branch "hotfix: payment error"
# → hotfix/payment-error 브랜치 생성

/branch "로그인 버그 수정"
# → AskUserQuestion으로 영문명 확인
# → fix/login-bug 브랜치 생성
```

### 기타 타입 브랜치 생성

```bash
/branch "refactor auth module"
# → refactor/auth-module 브랜치 생성

/branch "docs: update readme"
# → docs/update-readme 브랜치 생성

/branch "chore: ci config"
# → chore/ci-config 브랜치 생성
```

### 브랜치 전환

```bash
/branch main
# 변경사항 없음 → main으로 바로 전환
# 변경사항 있음 → AskUserQuestion 표시
```

### 상태 확인

```bash
/branch
# 출력:
# 📍 현재 브랜치: feat/user-auth
# 📝 변경사항: 3개 파일
# 📤 미푸시 커밋: 2개
# 🔗 연결된 Epic: 없음
```

---

## 에러 처리

### 브랜치명 충돌

```
❌ 오류: 'feat/user-auth' 브랜치가 이미 존재합니다
→ 기존 브랜치로 전환하려면: /branch feat/user-auth
→ 새 브랜치를 만들려면 다른 이름을 사용하세요
```

### Git 저장소 아님

```
❌ 오류: Git 저장소가 아닙니다
→ 'git init'으로 저장소를 초기화하거나
→ Git 저장소 디렉토리에서 실행하세요
```

### 전환 실패

```
❌ 오류: 브랜치 전환 실패
원인: 병합 충돌 또는 추적되지 않은 파일
→ 변경사항을 먼저 정리하세요
```

---

## Output Language

모든 출력은 **한글**로 작성합니다.
