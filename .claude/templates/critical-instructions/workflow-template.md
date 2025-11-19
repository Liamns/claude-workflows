# Workflow Command - CRITICAL INSTRUCTION Template

이 템플릿은 Workflow 타입 슬래시 명령어에 적용됩니다.
- 적용 대상: `/epic`, `/major`, `/minor`, `/micro`

---

## 템플릿 내용

```markdown
**Claude를 위한 필수 지시사항:**

이 명령어가 실행될 때 반드시 다음 단계를 **순서대로** 따라야 합니다:

1. **아직 코드를 작성하지 마세요**
2. 대화 맥락에서 [요구사항/이슈 설명]을 수집하세요
3. 영향받는 파일을 읽어 근본 원인을 분석하세요
4. reusability-enforcer skill을 사용하여 재사용 가능한 패턴을 검색하세요
5. **[문서-경로] 문서를 생성하세요**
6. 구현하기 전에 사용자 승인을 기다리세요

**절대로 [문서-이름] 생성 단계를 건너뛰지 마세요.**

---
```

## 명령어별 커스터마이징

### `/epic`
- [요구사항/이슈 설명] → epic 비전과 범위
- [문서-경로] → `.specify/epics/NNN-epic-name/epic-plan.md`
- [문서-이름] → epic-plan.md

### `/major`
- [요구사항/이슈 설명] → 기능 요구사항
- [문서-경로] → `.specify/features/NNN-name/spec.md, plan.md, tasks.md`
- [문서-이름] → 문서 (spec.md, plan.md, tasks.md)

### `/minor`
- [요구사항/이슈 설명] → 이슈 설명
- [문서-경로] → `.specify/specs/fixes/NNN-issue-name/fix-analysis.md`
- [문서-이름] → fix-analysis.md

### `/micro`
- 문서 생성 단계 불필요 (바로 구현)
- 대신 "변경사항이 정말 micro인지 확인" 단계 강조

## 핵심 원칙

1. **DO NOT write code yet** 문구 필수
2. **NEVER skip [문서명]** 문구 필수
3. 문서 생성 단계를 명시적으로 포함
4. 사용자 승인 대기 단계 포함
5. 재사용성 검색 단계 포함
