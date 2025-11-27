---
name: implement
hooks:
  pre: .claude/hooks/implement-smart-selector.sh
  post: .claude/hooks/implement-task-updater.sh
---

# Implement - 구현 단계

> **참고**: 이 명령어는 `.claude/CLAUDE.md`의 규칙을 준수합니다.

계획 문서 기반으로 실제 구현을 수행합니다.

## 사용법

```bash
# 1. 스마트 선택 (권장)
/implement
# → PreHook이 미완료 작업을 자동으로 찾아서 제시

# 2. 명시적 지정
/implement {feature-id}
# → 특정 feature/fix를 지정하여 구현

# 3. Micro 작업
/implement --micro
# → micro-context.json 기반 간단한 작업
```

## PreHook: 스마트 Context 선택

`/implement` 인자 없이 실행 시, PreHook이 자동으로 작업을 찾습니다:

### 탐색 범위
1. `.specify/features/*/` (독립 Major)
2. `.specify/epics/*/features/*/` (Epic 하위 Major)
3. `.specify/fixes/*/` (Minor)
4. 최근 수정된 4개 디렉토리 우선

### 선택 기준
- `tasks.md` 또는 `fix-analysis.md` 존재
- 미완료 task 확인 (`- [ ]` 패턴, `(optional)` 제외)
- 미완료가 있는 디렉토리만 필터링

### 선택 결과
- **1개 발견**: 자동 선택 (exit code 0)
- **여러 개 발견**: stderr로 목록 출력, 명령어가 AskUserQuestion 생성
- **0개 발견**: 차단 (exit code 2) - "완료되지 않은 작업이 없습니다"

## 구현 프로세스

1. **문서 로드**
   - `tasks.md` 또는 `fix-analysis.md` 읽기
   - 미완료 task 목록 확인

2. **순차 구현**
   - 체크리스트 순서대로 구현
   - 각 task마다:
     - 필요한 파일 탐색
     - 코드 작성/수정
     - 테스트 확인

3. **품질 검증**
   - 타입 체크 (`yarn type-check`)
   - 테스트 실행 (해당 시)
   - 코드 스타일 확인

## PostHook: 변경사항 확인

구현 완료 후 PostHook이 변경 사항을 확인합니다:

```bash
git diff --name-only
# → 변경된 파일 개수 출력
```

### PostHook 이후 안내

```
✅ 구현이 완료되었습니다
📝 변경된 파일: {N}개

**다음 단계**:
1. tasks.md에서 완료한 작업 확인 후 체크박스 업데이트 (`[ ]` → `[x]`)
2. `/review` - 코드 품질 검토 (권장)
3. 테스트 실행 및 검증
4. 커밋 준비
```

**중요**: task 체크박스는 사용자가 수동으로 업데이트합니다.

## Context 예시

### tasks.md 기반 (Major/Minor)

```markdown
## 작업 체크리스트

### Phase 1: 기반 구조
- [x] 디렉토리 구조 생성
- [x] 타입 정의
- [ ] API 클라이언트 구현 ← 다음 작업
- [ ] 에러 핸들링
- [ ] (optional) 로깅 추가

### Phase 2: 기능 구현
- [ ] 메인 로직
- [ ] 테스트 작성
```

→ 구현 시 "API 클라이언트 구현"부터 시작

### fix-analysis.md 기반 (Minor)

```markdown
## 작업 체크리스트

- [x] 버그 재현
- [x] 근본 원인 파악
- [ ] null check 추가 ← 다음 작업
- [ ] 에러 핸들링 개선
- [ ] 단위 테스트 추가
```

→ 구현 시 "null check 추가"부터 시작

## 스마트 선택 동작 예시

### 예시 1: 1개 발견 (자동 선택)

```bash
$ /implement

# PreHook 실행:
🔍 미완료 작업 탐색 중...
✅ 발견: .specify/features/007-workflow-restructure
   - 3개 미완료 task

📍 자동 선택되었습니다
→ 구현 시작...
```

### 예시 2: 여러 개 발견 (선택 필요)

```bash
$ /implement

# PreHook 실행:
🔍 미완료 작업 탐색 중...
✅ 발견 (3개):
1. .specify/features/007-workflow-restructure (3개 미완료)
2. .specify/fixes/042-null-pointer (2개 미완료)
3. .specify/epics/006-token-optimization/features/001-caching (5개 미완료)

# 명령어가 AskUserQuestion 생성:
[사용자 선택 대기]
```

### 예시 3: 없음 (차단)

```bash
$ /implement

# PreHook 실행:
🔍 미완료 작업 탐색 중...
❌ 미완료 작업이 없습니다

모든 작업이 완료되었거나 새로운 작업이 필요합니다.
다음 중 하나를 실행하세요:
- `/triage` - 새 작업 분석
- `/plan-major` - Major 작업 계획
- `/plan-minor` - Minor 작업 계획

# exit code 2 → 실행 차단
```

## 주의사항

1. **문서 먼저 생성**: `/plan-major` 또는 `/plan-minor` 실행 후 사용
2. **브랜치 확인**: 올바른 브랜치에서 작업 중인지 확인
3. **점진적 커밋**: 큰 작업은 task 단위로 커밋 권장
4. **테스트 우선**: TDD 가능한 경우 테스트 먼저 작성

## Output Language

모든 출력은 **한글**로 작성합니다.

## 참고

- PreHook 차단 시 (exit code 2) 명령어 실행 안 됨
- PostHook은 항상 성공 (exit code 0)
- 명령어가 안내 메시지 출력, task 업데이트는 수동
