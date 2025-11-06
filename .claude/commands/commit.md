---
name: commit
description: Git 변경사항을 분석하여 Conventional Commits 형식으로 커밋 메시지를 자동 생성하고 커밋합니다
---

# 🚀 Smart Commit Command

Git 변경사항을 자동으로 분석하여 Conventional Commits 형식의 커밋 메시지를 생성하고 커밋합니다.

## 사용법

```bash
/commit              # 변경사항 분석 후 커밋
/commit --no-verify  # 검증 없이 빠른 커밋
/commit "컨텍스트"   # 추가 컨텍스트와 함께 커밋
```

## 프로세스

### 1️⃣ 변경사항 분석
```bash
git status  # 변경된 파일 목록 확인
git diff    # 상세 변경 내용 분석
```

### 2️⃣ smart-committer Agent 활성화
복잡한 변경사항 분석을 위해 전문 Agent를 활성화합니다:
- 다중 파일 변경 시 카테고리별 분류
- 변경 유형 자동 판단 (feat/fix/refactor 등)
- Breaking Changes 감지

### 3️⃣ 커밋 메시지 생성

#### Conventional Commits 형식
```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

#### 타입 분류 기준
- **feat**: 새로운 기능 추가
- **fix**: 버그 수정
- **refactor**: 코드 리팩토링 (기능 변경 없음)
- **style**: 코드 포맷팅, 세미콜론 누락 등
- **docs**: 문서 수정
- **test**: 테스트 추가 또는 수정
- **chore**: 빌드 프로세스, 도구 설정 변경
- **perf**: 성능 개선
- **ci**: CI 설정 변경
- **build**: 빌드 시스템 또는 외부 종속성 변경
- **revert**: 이전 커밋 되돌리기

#### 스코프 자동 감지
```javascript
// 파일 경로에서 스코프 추출
src/features/order/... → feat(order): ...
src/shared/ui/...     → style(ui): ...
src/entities/user/... → refactor(user): ...
```

### 4️⃣ 선택적 검증 (commit-guard)

```markdown
📋 커밋 전 검증을 실행하시겠습니까?

[1] Full Check - 타입체크 + 테스트 + 린트
[2] Quick Check - 타입체크만
[3] Skip - 검증 건너뛰기

선택: _
```

검증 옵션:
- **타입 체크**: `yarn type-check`
- **관련 테스트**: 변경된 파일의 테스트만 실행
- **린트**: `yarn lint` (선택사항)
- **민감 정보 검사**: .env, API 키 등 확인

### 5️⃣ 커밋 메시지 확인 및 수정

```markdown
📝 생성된 커밋 메시지:

feat(order): 운송 신청 폼에 차량 선택 기능 추가

- 차량 타입별 이미지 표시
- 선택 시 운임 자동 계산
- 차량 정보 툴팁 추가

이 메시지로 커밋하시겠습니까?
[Y] 커밋 실행
[E] 메시지 수정
[R] 다시 분석
[C] 취소
```

### 6️⃣ 커밋 실행

```bash
git add .  # 또는 선택적 스테이징
git commit -m "커밋 메시지"
```

## 실제 사용 예시

### 예시 1: 새 기능 추가
```bash
/commit

🔍 변경사항 분석 중...
변경된 파일: 5개
주요 변경: VehicleSelector.tsx 추가

📝 생성된 메시지:
feat(vehicle): 차량 선택 컴포넌트 구현

- 차량 타입별 선택 UI 추가
- 운임 계산 로직 통합
- 반응형 디자인 적용

✅ 커밋이 완료되었습니다!
```

### 예시 2: 버그 수정
```bash
/commit

🔍 변경사항 분석 중...
변경된 파일: 2개
주요 변경: null 체크 추가

📝 생성된 메시지:
fix(order): 주소 정보 null 참조 에러 수정

- Optional chaining 추가
- 기본값 설정

✅ 커밋이 완료되었습니다!
```

### 예시 3: 리팩토링
```bash
/commit --no-verify

🔍 변경사항 분석 중...
변경된 파일: 8개
주요 변경: 공통 로직 추출

📝 생성된 메시지:
refactor: 중복 코드를 유틸 함수로 추출

- formatAddress 함수 생성
- 3개 컴포넌트에서 재사용
- 테스트 커버리지 향상

⚡ 검증 없이 빠른 커밋 실행
✅ 커밋이 완료되었습니다!
```

## 고급 기능

### Breaking Changes 감지
```markdown
⚠️ Breaking Change 감지됨!

- API 응답 형식 변경
- 필수 prop 추가

BREAKING CHANGE 푸터를 추가하시겠습니까? [Y/n]
```

### 다중 타입 변경
```markdown
🔍 여러 타입의 변경이 감지되었습니다:
- 새 기능 (feat): 3개 파일
- 버그 수정 (fix): 1개 파일
- 문서 (docs): 2개 파일

어떻게 처리하시겠습니까?
[1] 개별 커밋으로 분리 (권장)
[2] 주요 타입으로 통합
[3] 수동 선택
```

### 커밋 템플릿
자주 사용하는 패턴을 템플릿으로 저장:
```yaml
templates:
  hotfix: "fix(critical): 긴급 수정 - "
  feature: "feat({scope}): "
  wip: "chore: WIP - "
```

## 설정 옵션

`.claude/commit-config.yaml` (선택사항):
```yaml
# 기본 설정
default_type: feat
auto_scope: true
emoji: false  # 이모지 사용 여부

# 검증 기본값
verification:
  default: quick  # full, quick, skip
  auto_fix: true  # 린트 오류 자동 수정

# 커밋 규칙
rules:
  max_length: 72
  require_scope: false
  require_body: false
```

## 통계 및 분석

```markdown
📊 커밋 통계 (최근 30일)

타입별 분포:
• feat: 42 (35%)
• fix: 31 (26%)
• refactor: 18 (15%)
• docs: 12 (10%)
• test: 10 (8%)
• style: 7 (6%)

평균 커밋 메시지 생성 시간: 5초
검증 통과율: 94%
```

## 문제 해결

### "변경사항이 너무 많습니다"
→ 개별 커밋으로 분리하거나 논리적 단위로 스테이징

### "타입을 자동으로 판단할 수 없습니다"
→ 수동으로 타입 선택 또는 추가 컨텍스트 제공

### "검증이 실패했습니다"
→ 오류 내용 확인 후 수정 또는 --no-verify 옵션 사용

## 연동 워크플로우

```bash
# Minor 워크플로우 완료 후 자동 커밋
/minor
→ 작업 완료
→ /commit 자동 실행

# PR 생성 전 커밋
/commit
→ git push
→ /pr-review
```

---

💡 **팁**: 자주 커밋하고 작은 단위로 나누면 더 명확한 히스토리를 유지할 수 있습니다.