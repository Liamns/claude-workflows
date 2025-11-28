---
name: plan-major
hooks:
  post: .claude/hooks/plan-major-post.sh
---

# Plan:Major - Major 워크플로우 계획 단계

> **참고**: 이 명령어는 `.claude/CLAUDE.md`의 규칙을 준수합니다.

Major 복잡도 작업(8-15점)의 계획 문서를 생성합니다.

## 실행 순서

1. **요구사항 수집**
   - 사용자 요구사항 명확화
   - 기능 범위 정의
   - 제약사항 파악

2. **재사용성 검증**
   - `reusability-enforcer` Skill 자동 실행
   - 기존 코드/패턴 재사용 가능 여부 확인

3. **브랜치 확인** (선택)
   - 올바른 브랜치에서 작업 중인지 확인
   - 필요 시 `/branch` 명령어로 브랜치 생성/전환
   - 예: `/branch "user-auth 기능"`

4. **문서 생성**
   - `spec.md`: 기능 명세서 (문제 상황, 해결 방안, 요구사항)
   - `plan.md`: 구현 계획 (Phase별 작업, 일정, 위험 관리)
   - `tasks.md`: 작업 체크리스트 (구현 가능한 단위로 분해)

5. **PostHook 검증**
   - 문서 존재 확인
   - Placeholder 검사
   - 필수 섹션 검증

## PostHook 이후 안내

PostHook 검증 통과 시, 다음 단계를 안내합니다:

```
✅ 문서 생성이 완료되었습니다:
- spec.md: 기능 명세서
- plan.md: 구현 계획
- tasks.md: 작업 체크리스트

**다음 단계**:
1. `/review` - 문서 검토 및 개선사항 확인 (권장)
2. `/implement` - 바로 구현 시작
```

**중요**: 사용자가 명시적으로 다음 명령어를 실행해야 합니다.

## 예시

```bash
# Major 작업 계획
/plan-major "워크플로우 명령어 구조 재설계"

# 브랜치가 필요한 경우 (선택)
/branch "workflow-restructure"
```

## Output Language

모든 출력은 **한글**로 작성합니다.

## 참고

- 복잡도 분석은 `/triage`에서 수행됩니다
- 이 명령어는 계획만 수행하며, 구현은 `/implement`에서 진행합니다
- PostHook 검증 실패 시 명령어가 차단됩니다 (exit code 2)
