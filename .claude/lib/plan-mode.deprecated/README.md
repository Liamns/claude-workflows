# Plan Mode (Deprecated)

## Status
**Deprecated as of v3.1.0 (2025-11-13)**

## Reason
Plan Mode가 Major 워크플로우의 AskUserQuestion 기능으로 대체되었습니다.
사용자의 수동 개입을 줄이고 워크플로우를 간소화하기 위해 제거되었습니다.

## What Was Plan Mode?
Plan Mode는 복잡한 작업에 대해 사용자가 Shift+Tab으로 별도 모드에 진입하여 상세 계획을 작성한 후, 해당 계획을 Major 워크플로우에 전달하는 방식이었습니다.

**문제점:**
- 사용자가 긴 텍스트를 직접 입력해야 하는 수동성
- Plan Mode → Major 워크플로우로의 전환이 끊김
- ExitPlanMode 도구가 데이터 반환이 아닌 모드 전환 신호로만 동작
- 실제 사용률이 낮음

## Migration Guide

### 이전 워크플로우:
```bash
1. /triage "복잡한 기능"
2. Plan Mode 가이드 확인
3. Shift+Tab → Plan Mode 진입
4. 상세 계획 작성 (수동 입력)
5. ExitPlanMode
6. /major 실행 → 계획 내용 복사-붙여넣기
```

### 현재 워크플로우:
```bash
1. /triage "복잡한 기능"
2. Major 워크플로우 선택
3. AskUserQuestion으로 필요한 정보 자동 수집
   - 기능 목표
   - 사용자 시나리오
   - 성공 기준
   - 영향 범위
   - 기존 패턴
   - API 통합 정보
4. spec.md, plan.md, tasks.md 자동 생성
```

**개선 효과:**
- 워크플로우 실행 시간 30초-1분 단축
- 수동 복사-붙여넣기 단계 제거
- 더 직관적이고 끊김없는 경험

## Rollback Instructions

Plan Mode를 다시 활성화하려면:

```bash
# 1. 백업 파일 복원
cp .claude/commands/major.md.backup .claude/commands/major.md
cp .claude/commands/triage.md.backup .claude/commands/triage.md

# 2. plan-mode 디렉토리 복원
mv .claude/lib/plan-mode.deprecated .claude/lib/plan-mode

# 3. 변경사항 확인
git diff .claude/commands/major.md
git diff .claude/commands/triage.md
```

## Files in This Directory

- **guide-template.md**: Plan Mode 가이드 메시지 템플릿
- **integration-strategy.md**: Plan Mode 통합 전략 문서 (Context-based Integration)
- **extract-context.sh**: 대화 컨텍스트에서 계획 추출 스크립트

## References

- **Removal Spec**: `.specify/specs/001-epic-workflow-system-v31-improvements/features/001-plan-mode-improvement/spec.md`
- **Implementation Plan**: `.specify/specs/001-epic-workflow-system-v31-improvements/features/001-plan-mode-improvement/plan.md`
- **Tasks**: `.specify/specs/001-epic-workflow-system-v31-improvements/features/001-plan-mode-improvement/tasks.md`
- **Epic**: `.specify/specs/001-epic-workflow-system-v31-improvements/epic.md`
- **CHANGELOG**: `CHANGELOG.md` (v3.1.0 section)

## Feedback

If you have feedback about this change or need Plan Mode back, please:
1. Open an issue at https://github.com/anthropics/claude-workflows/issues
2. Include your use case and why AskUserQuestion doesn't meet your needs

---

**Last Updated**: 2025-11-13
**Removed By**: Plan Mode Improvement Feature (001-plan-mode-improvement)
