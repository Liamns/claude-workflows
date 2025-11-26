# Claude Code 프로젝트 지침

이 문서는 모든 슬래시 명령어 실행 시 적용되는 **Claude Code 행동 규칙**입니다.
프로젝트 레벨 Memory로서 User 레벨(~/.claude/CLAUDE.md)보다 우선 적용됩니다.

---

## 1. 사용자 상호작용 규칙

### AskUserQuestion 필수 사용

옵션을 제시하거나 다음 작업을 제안할 때 **반드시 AskUserQuestion 도구를 사용**합니다.

#### 사용 필수 상황
- 복잡도 선택 (Major/Minor/Micro)
- 다음 단계 제안 (/plan-* 완료 후 → /implement 또는 /review)
- 작업 방향 결정 (여러 옵션 중 선택)
- 커밋/PR 제안
- 워크플로우 선택

#### 올바른 사용 예시
```
AskUserQuestion 도구 호출:
- question: "문서 생성이 완료되었습니다. 다음으로 무엇을 하시겠습니까?"
- header: "다음 단계"
- options:
  - "/implement 바로 시작"
  - "/review 문서 검토"
  - "나중에 진행"
```

#### 금지 사항
- 단순 텍스트로 "~하시겠습니까?" 질문 후 기다리기
- 선택지 없이 단일 옵션만 제안
- AskUserQuestion 없이 다음 단계로 자동 진행

---

## 2. 단계 분리 원칙

계획과 구현은 **반드시 분리**됩니다.

### /plan-* 명령어 (계획 단계)
- **허용**: 문서 생성 (spec.md, plan.md, tasks.md, fix-analysis.md)
- **금지**: 구현 코드 작성, 파일 수정
- **완료 후**: AskUserQuestion으로 다음 단계 제안

### /implement 명령어 (구현 단계)
- **허용**: 코드 구현, 파일 수정, 테스트 작성
- **금지**: 새로운 계획 수립, spec/plan 문서 수정
- **기반**: 기존 문서(spec.md, plan.md, tasks.md) 참조

### 교차 작업 금지
- /plan-major 실행 중 구현 코드 작성 ❌
- /implement 실행 중 새로운 기능 계획 ❌
- 문서 생성 후 사용자 확인 없이 구현 진행 ❌

---

## 3. 명령어 실행 규칙

슬래시 명령어 md 파일의 다음 섹션은 **반드시 먼저 확인**합니다.

### 필수 확인 섹션
| 섹션명 | 처리 방법 |
|--------|-----------|
| **Critical Rules** | 절대 건너뛰지 않음, 모든 규칙 준수 |
| **필수 확인 사항** | 실행 전 반드시 확인 |
| **PostHook** | 완료 조건 인지, 문서 완성 후 종료 |
| **Output Language** | 지정된 언어로 출력 |

### 섹션 확인 순서
1. 명령어 md 파일 읽기
2. Critical Rules 섹션 확인 (있으면 필수 준수)
3. 필수 확인 사항 섹션 확인
4. 실행 단계 진행
5. PostHook 조건 충족 확인

---

## 4. Compact 후 작업 연속성 규칙

Compact(자동/수동) 발생 후에는 **반드시 compact된 history를 확인**합니다.

### 확인 절차
1. Compact 감지 시 즉시 history 요약 확인
2. 진행 중이던 작업/단계 파악
3. TodoWrite로 남은 작업 재구성
4. 중단된 지점부터 이어서 진행

### 금지 사항
- History 확인 없이 새 작업 시작
- 이전 컨텍스트 무시하고 처음부터 재시작
- Compact 전 진행 중이던 작업 방치

---

## 5. PostHook 준수 규칙

PostHook이 있는 명령어는 다음을 준수합니다.

### 문서 완성 조건
- 모든 필수 문서 생성 완료
- 각 문서 최소 크기 충족
  - spec.md: 1KB 이상
  - plan.md: 1KB 이상
  - tasks.md: 500B 이상

### 미완성 표시자 금지
다음 패턴을 문서에 남기지 않음:
- `{중괄호 템플릿}` 형태의 미완성 내용
- 실제 할일 태그 (구현할 내용을 표시하는 용도)
- 작성 중 표시

### PostHook 실패 시
- Hook이 exit code 2 반환 → 명령어 차단
- 문서 완성 후 재실행 필요

---

## 6. 금지 사항 요약

| 상황 | 금지 행동 |
|------|-----------|
| 옵션 제시 | AskUserQuestion 없이 텍스트 질문 |
| /plan-* 실행 | 구현 코드 작성 |
| /implement 실행 | 새로운 계획 수립 |
| 문서 생성 후 | 사용자 확인 없이 다음 단계 |
| Critical Rules 섹션 | 건너뛰기 |
| PostHook 있는 명령어 | 미완성 문서로 종료 |
| Compact 발생 후 | History 확인 없이 새 작업 시작 |

---

## 참고

### 관련 파일
- **constitution.md**: 개발 원칙 (`.specify/memory/constitution.md`)
- **이 문서**: Claude Code 행동 규칙 (`.claude/CLAUDE.md`)
- **User CLAUDE.md**: 사용자 기본 선호사항 (`~/.claude/CLAUDE.md`)

### 우선순위 (높음 → 낮음)
1. Enterprise 정책
2. 프로젝트 CLAUDE.md (이 파일)
3. User CLAUDE.md

### 명령어 import
각 명령어 md 파일에서 이 문서를 참조할 수 있습니다:
```markdown
@.claude/CLAUDE.md 의 규칙을 준수합니다.
```
