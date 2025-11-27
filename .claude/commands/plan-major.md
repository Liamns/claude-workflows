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

3. **브랜치 전략 적용**
   - **IMPORTANT**: 아래 로직을 실제로 실행하여 브랜치를 생성하거나 확인합니다
   - 현재 디렉토리 구조를 확인하여 자동으로 전략을 선택합니다:
     - **독립 Major** (`.specify/features/`): 신규 브랜치 생성 (`{feature-id}-{feature-name}`)
     - **Epic 하위 Major** (`.specify/epics/*/features/`): Epic 브랜치 유지 (신규 생성 안 함)
   - "브랜치 생성 로직" 섹션의 코드를 참고하여 실행하세요

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

## 브랜치 생성 로직

**이 로직은 실제로 실행되어야 합니다.** "브랜치 전략 적용" 단계에서 아래 코드를 사용하여 브랜치를 생성하거나 확인하세요.

```bash
# 현재 디렉토리 확인
current_dir=$(pwd)

# Epic 하위인지 감지
if echo "$current_dir" | grep -q "\.specify/epics/[^/]*/features/"; then
  # Epic 하위 feature
  echo "📍 Epic 하위 feature - 브랜치 생성 안 함"
  epic_branch=$(git branch --show-current)

  # Epic 브랜치 확인
  if [[ ! "$epic_branch" =~ ^[0-9]+-epic- ]]; then
    echo "⚠️ Epic 브랜치가 아닙니다. Epic 브랜치로 전환해주세요."
  fi
else
  # 독립 feature
  echo "📍 독립 feature - 신규 브랜치 생성"
  feature_id=$(basename "$(dirname "$(pwd)")" | cut -d'-' -f1)
  feature_name=$(basename "$(dirname "$(pwd)")" | cut -d'-' -f2-)
  git checkout -b "${feature_id}-${feature_name}"
fi
```

## 예시

```bash
# 독립 Major 작업
cd .specify/features/007-workflow-restructure
/plan-major "워크플로우 명령어 구조 재설계"
# → 007-workflow-restructure 브랜치 생성

# Epic 하위 Major 작업
cd .specify/epics/006-token-optimization/features/001-caching
/plan-major "스마트 캐싱 시스템"
# → 006-epic-token-optimization 브랜치 유지
```

## Output Language

모든 출력은 **한글**로 작성합니다.

## 참고

- 복잡도 분석은 `/triage`에서 수행됩니다
- 이 명령어는 계획만 수행하며, 구현은 `/implement`에서 진행합니다
- PostHook 검증 실패 시 명령어가 차단됩니다 (exit code 2)
