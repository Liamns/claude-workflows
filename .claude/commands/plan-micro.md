---
name: plan-micro
---

# Plan:Micro - Micro 워크플로우 계획 단계

> **참고**: 이 명령어는 `.claude/CLAUDE.md`의 규칙을 준수합니다.

Micro 복잡도 작업(0-3점)의 간단한 계획을 수립합니다.

## 실행 순서

1. **작업 파악**
   - 간단한 수정/개선 사항 확인
   - 파일 위치 파악

2. **간단한 Context 저장** (선택적)
   - `.claude/cache/micro-context.json` 생성
   - 작업 내용, 파일 경로 저장

3. **바로 구현 시작**
   - 문서 생성 생략
   - 즉시 구현 진행 가능

## Micro 작업의 특징

Micro 작업은 **빠른 실행**을 위해 간소화되었습니다:

- ✅ 문서 생성 생략 또는 최소화
- ✅ Hooks 없음 (검증 생략)
- ✅ 즉시 구현 가능

## 언제 Micro를 사용하나요?

- 오타 수정
- 간단한 스타일링 변경
- 로그 메시지 수정
- 주석 추가
- 설정 파일 미세 조정

## micro-context.json 형식 (선택적)

```json
{
  "type": "micro",
  "description": "작업 설명",
  "files": ["경로1", "경로2"],
  "estimated_time": "5분"
}
```

## 사용 방법

```bash
# 단독 실행
/plan-micro "버튼 색상 수정"
# → 간단한 context만 저장하고 즉시 구현 가능

# /implement와 함께
/implement --micro
# → micro-context.json 기반 구현
```

## 예시

```bash
# 예시 1: 오타 수정
/plan-micro "README.md 오타 수정"
# → 즉시 수정 가능

# 예시 2: 스타일 미세 조정
/plan-micro "버튼 padding 5px → 8px"
# → 즉시 수정 가능
```

## 참고

- Micro 작업은 복잡도 0-3점에 해당
- 문서 생성을 생략하여 빠른 실행에 초점
- 복잡도가 높아질 것 같으면 `/triage`로 재분석 권장
