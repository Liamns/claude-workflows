# Hybrid Command - CRITICAL INSTRUCTION Template

이 템플릿은 Hybrid 타입 슬래시 명령어에 적용됩니다.
- 적용 대상: `/triage`, `/commit`, `/pr`, `/pr-review`, `/review`, `/start`

---

## 템플릿 내용

```markdown
**Claude를 위한 필수 지시사항:**

이 명령어가 실행될 때 반드시 다음 단계를 **순서대로** 따라야 합니다:

1. [도구/방법]을 사용하여 초기 분석 수행
2. 필요 시 AskUserQuestion을 사용하여 추가 정보 수집
3. 스크립트를 통해 자동화된 작업 실행
4. 결과를 기반으로 권장사항 생성
5. 진행하기 전에 사용자 확인을 기다리세요

**절대로 분석 단계를 건너뛰지 마세요.**

---
```

## 명령어별 커스터마이징

### `/triage`
- [도구/방법] → 복잡도 분석 (키워드 점수, 파일 개수, 소요 시간)
- 분석 단계 → 복잡도 분석
- 권장사항 → 워크플로우 추천 (Epic/Major/Minor/Micro) + Plan Mode 가이드

### `/commit`
- [도구/방법] → git status와 git diff
- 분석 단계 → 변경사항 확인 + 커밋 히스토리 분석
- 권장사항 → 커밋 메시지 생성
- 추가: 커밋하기 전 AskUserQuestion으로 확인

### `/pr`
- [도구/방법] → git log, git diff [base]...HEAD
- 분석 단계 → 브랜치 변경사항 전체 분석
- 권장사항 → PR 제목과 설명 생성
- 추가: gh pr create 전 확인

### `/pr-review`
- [도구/방법] → gh pr view, gh pr diff
- 분석 단계 → PR 변경사항 분석
- 권장사항 → 코드 리뷰 코멘트 생성

### `/review`
- [도구/방법] → 파일 읽기, 아키텍처 분석
- 분석 단계 → 코드 품질, 보안, 성능 검토
- 권장사항 → 개선 제안 생성

### `/start`
- [도구/방법] → 프로젝트 구조 분석
- 분석 단계 → 기존 패턴과 설정 확인
- 권장사항 → 개발 환경 설정 가이드

## 핵심 원칙

1. **NEVER skip** 분석 단계 문구 필수
2. 분석 → 질문 → 실행 순서 준수
3. AskUserQuestion 통합 (사용자 확인 단계)
4. 스크립트와 대화형 요소 결합
5. 결과 기반 권장사항 제공

---

## 📋 다음 단계 추천 시 필수 규칙

### 규칙 1: AskUserQuestion 사용 강제

명령어 실행 중 또는 완료 후, **사용자에게 다음 단계를 물어보거나 선택을 요청할 때**,
반드시 AskUserQuestion 도구를 사용하세요.

#### ❌ 잘못된 예시
```
"복잡도 분석 결과 Major 워크플로우를 추천합니다. 실행하시겠습니까?"
"커밋이 완료되었습니다. PR을 생성하시겠습니까?"
```

#### ✅ 올바른 예시
```
"복잡도 분석 결과 Major 워크플로우를 추천합니다."

[AskUserQuestion 호출]
{
  "questions": [{
    "question": "어떤 워크플로우를 실행하시겠습니까?",
    "header": "워크플로우 선택",
    "multiSelect": false,
    "options": [
      {
        "label": "Major 워크플로우",
        "description": "중규모 기능 개발 (복잡도: 8/15)"
      },
      {
        "label": "Minor 워크플로우",
        "description": "소규모 수정"
      },
      {
        "label": "직접 선택",
        "description": "나중에 수동으로 결정"
      }
    ]
  }]
}
```

---

### 규칙 2: AskUserQuestion 응답 후 자동 실행

AskUserQuestion으로 사용자 응답을 받은 후, **반드시 다음 규칙을 따르세요**:

#### 사용자가 워크플로우/명령어 선택 시
→ **즉시 해당 슬래시 커맨드를 실행하세요**

**예시**:
```javascript
// /triage 후 응답
{"0": "Major 워크플로우"}  → SlashCommand("/major")
{"0": "Minor 워크플로우"}  → SlashCommand("/minor")

// /commit 후 응답
{"0": "예, /pr 실행"}      → SlashCommand("/pr")

// /pr 후 응답
{"0": "예, /pr-review 실행"} → SlashCommand("/pr-review")
```

#### 사용자가 "직접 선택" 또는 "나중에" 선택 시
→ 명령어 실행하지 않고 종료

---

### 규칙 3: 응답 해석 패턴

사용자 응답에서 의도를 정확히 파악하세요:

**워크플로우 선택 패턴**:
```javascript
"Major 워크플로우"   → SlashCommand("/major")
"Minor"              → SlashCommand("/minor")
"Epic"               → SlashCommand("/epic")
"Micro"              → SlashCommand("/micro")
```

**실행 의도 키워드**:
- "예", "실행", "진행", "생성", "Yes"

**거부 의도 키워드**:
- "직접 선택", "나중에", "수동", "건너뛰기", "No"

---

### Hybrid 타입 명령어의 일반적인 다음 단계

#### `/triage` → `/epic` | `/major` | `/minor` | `/micro`
- 복잡도 분석 결과에 따라 적절한 워크플로우 제안
- 반드시 AskUserQuestion으로 선택 받기

#### `/commit` → `/pr`
- 커밋 완료 후 feature 브랜치인 경우 PR 생성 제안
- 조건: 현재 브랜치 ≠ main/master/develop

#### `/pr` → `/pr-review`
- PR 생성 완료 후 즉시 리뷰 제안 (선택 사항)

#### `/pr-review` → `/commit`
- 리뷰에서 수정 필요 사항 발견 시 수정 후 커밋 제안

#### `/review` → `/commit`
- 코드 리뷰 후 개선사항 적용하면 커밋 제안

#### `/start` → `/triage`
- 프로젝트 초기화 완료 후 첫 작업 트리아지 제안

---

### 전체 워크플로우 예시 (/triage → /major → /commit → /pr)

```
1. /triage "새로운 로그인 기능 추가"
2. 복잡도 분석: 키워드 점수 10/15 → Major 추천
3. AskUserQuestion: "어떤 워크플로우를 실행하시겠습니까?"
   옵션: ["Major 워크플로우", "Minor 워크플로우", "직접 선택"]
4. 사용자: "Major 워크플로우" 클릭
5. SlashCommand("/major") 자동 실행
6. /major 구현 완료
7. AskUserQuestion: "변경사항을 커밋하시겠습니까?"
   옵션: ["예, /commit 실행", "나중에"]
8. 사용자: "예, /commit 실행" 클릭
9. SlashCommand("/commit") 자동 실행
10. /commit 완료
11. AskUserQuestion: "PR을 생성하시겠습니까?"
    옵션: ["예, /pr 실행", "나중에"]
12. 사용자: "예, /pr 실행" 클릭
13. SlashCommand("/pr") 자동 실행
14. PR 생성 완료
```

**사용자 행동**: 클릭 4번 (triage 입력 + 3번의 선택)
**결과**: 전체 워크플로우 완료

---

### 이점
1. **최소 개입**: 전체 워크플로우를 클릭 몇 번으로 완료
2. **유연성**: 각 단계에서 선택 가능
3. **일관성**: 모든 Hybrid 명령어가 동일한 패턴 사용
4. **자동화**: 수동 타이핑 불필요
