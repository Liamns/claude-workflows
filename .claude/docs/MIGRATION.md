# 마이그레이션 가이드

이 문서는 deprecated 명령어에서 새로운 워크플로우로 전환하는 방법을 안내합니다.

## 개요

v3.3부터 도입된 **md + Hook + CLAUDE.md 3중 방어 구조**를 활용하기 위해 기존 명령어를 새로운 워크플로우로 전환해야 합니다.

### 3중 방어 구조

```
우선순위 높음
    ↓
.claude/CLAUDE.md          ← 프로젝트 레벨 Memory
    ↓                         "모든 명령어 공통 강제 규칙"
.claude/commands/*.md      ← 명령어별 상세 지시사항
    ↓                         "@.claude/CLAUDE.md 참조"
.claude/hooks/*.sh         ← 하드 검증 (exit code 2 = 차단)
    ↓
~/.claude/CLAUDE.md        ← User 레벨 기본 선호사항
```

---

## 주요 변경사항

### 1. 계획/구현 분리

**기존**: 하나의 명령어가 계획과 구현을 모두 수행
**신규**: `/plan-*`으로 계획, `/implement`로 구현 분리

### 2. Hook 기반 검증

**기존**: 소프트 가이드라인 (무시 가능)
**신규**: Hook으로 하드 검증 (exit code 2 시 차단)

### 3. CLAUDE.md 통합

**기존**: 각 명령어가 독립적으로 규칙 정의
**신규**: `.claude/CLAUDE.md`에서 공통 규칙 강제

---

## 마이그레이션 단계

### `/major` → `/triage` + `/plan-major` + `/implement`

#### Before (기존)
```bash
/major "사용자 인증 시스템"
# → 문서 생성 + 구현까지 한번에
```

#### After (신규)
```bash
# 1단계: 복잡도 분석
/triage "사용자 인증 시스템"
# → Major 워크플로우 추천

# 2단계: 계획 수립 (문서만 생성)
/plan-major
# → spec.md, plan.md, tasks.md 생성
# → PostHook이 문서 완성도 검증

# 3단계: 사용자 검토 후 구현
/implement
# → tasks.md 기반 구현
```

#### 장점
- 문서 생성 후 사용자 검토 시간 확보
- PostHook이 미완성 문서를 차단
- `/implement` 전에 요구사항 수정 가능

---

### `/minor` → `/triage` + `/plan-minor` + `/implement`

#### Before (기존)
```bash
/minor "로그인 널 포인터 에러"
# → 분석 + 수정까지 한번에
```

#### After (신규)
```bash
# 1단계: 복잡도 분석
/triage "로그인 널 포인터 에러"
# → Minor 워크플로우 추천

# 2단계: 계획 수립 (분석 문서만 생성)
/plan-minor
# → fix-analysis.md 생성
# → PostHook이 필수 섹션 검증

# 3단계: 사용자 검토 후 구현
/implement
# → fix-analysis.md 기반 수정
```

#### 장점
- 근본 원인 분석 결과 확인 후 수정 진행
- 필수 섹션(증상, 근본 원인, 영향 범위) 자동 검증
- 잘못된 분석 시 `/implement` 전에 수정 가능

---

### `/docu` → `/docu-*` 시리즈

#### Before (기존)
```bash
/docu start 로그인
/docu list
/docu switch 2
/docu update "개발중"
/docu close
```

#### After (신규)
```bash
/docu-start 로그인
/docu-list
/docu-switch 2
/docu-update "개발중"
/docu-close
```

#### 장점
- 단일 책임 원칙 (각 명령어가 하나의 작업만 수행)
- 더 명확한 명령어 이름
- Hook 추가 가능 (예: `/docu-close` 시 커밋 동기화 강제)

---

## 워크플로우 비교

### 기존 워크플로우
```
사용자 → /major → [문서 생성 + 구현] → 완료
                        ↑
                  (중간 검토 없음)
```

### 신규 워크플로우
```
사용자 → /triage → /plan-major → [사용자 검토] → /implement → 완료
                        ↓
                   PostHook 검증
                  (미완성 시 차단)
```

---

## FAQ

### Q: 왜 계획과 구현을 분리했나요?

**A**: 계획 문서 생성 후 사용자가 검토할 시간을 확보하기 위해서입니다. 기존 방식은 문서 생성 후 바로 구현으로 넘어가 검토 기회가 없었습니다.

### Q: PostHook이 문서를 차단하면 어떻게 되나요?

**A**: 문서를 완성한 후 다시 명령어를 실행하면 됩니다. PostHook은 exit code 2를 반환하여 명령어 진행을 차단합니다.

### Q: 기존 명령어는 언제 제거되나요?

**A**: v4.0에서 제거 예정입니다. 현재는 deprecated 경고만 표시됩니다.

### Q: Epic 하위 Feature는 어떻게 처리되나요?

**A**: Epic 하위 Feature는 새 브랜치를 생성하지 않습니다. Epic 브랜치 내에서 작업하며, `/plan-major` 실행 시 자동으로 감지됩니다.

### Q: CLAUDE.md 규칙을 무시할 수 있나요?

**A**: User 레벨 규칙(`~/.claude/CLAUDE.md`)은 프로젝트 레벨 규칙(`.claude/CLAUDE.md`)보다 우선순위가 낮습니다. 프로젝트 규칙은 필수 준수입니다.

---

## 관련 문서

- **명령어 관계도**: `.claude/docs/COMMAND-REFERENCE.md`
- **CLAUDE.md 규칙**: `.claude/CLAUDE.md`
- **Epic 007 문서**: `.specify/epics/007-command-pattern-extension/epic.md`

---

**문서 버전**: 1.0.0
**최종 수정**: 2025-11-26
