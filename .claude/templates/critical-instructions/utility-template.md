# Utility Command - CRITICAL INSTRUCTION Template

이 템플릿은 Utility 타입 슬래시 명령어에 적용됩니다.
- 적용 대상: `/db-sync`, `/prisma-migrate`, `/dashboard`

---

## 템플릿 내용

```markdown
**Claude를 위한 필수 지시사항:**

이 명령어가 실행될 때 반드시 다음 단계를 **순서대로** 따라야 합니다:

1. 사전 조건 확인 ([환경 변수/의존성/서비스])
2. [스크립트-이름].sh 실행
3. 결과를 파싱하고 표시
4. AskUserQuestion을 사용하여 다음 단계 권장사항 제공

**절대로 사전 조건 확인 단계를 건너뛰지 마세요.**

---
```

## 명령어별 커스터마이징

### `/db-sync`
- [환경 변수/의존성/서비스] → .env, .env.docker, Docker 실행 중
- [스크립트-이름] → .claude/lib/db-sync.sh
- 추가: 에러 발생 시 트러블슈팅 가이드 제공

### `/prisma-migrate`
- [환경 변수/의존성/서비스] → Prisma 스키마 변경사항 (git diff schema.prisma)
- [스크립트-이름] → .claude/lib/prisma-migrate.sh
- 추가: 마이그레이션 히스토리와 비교

### `/dashboard`
- [환경 변수/의존성/서비스] → 메트릭 데이터 존재 (.claude/cache/metrics/)
- [스크립트-이름] → 표시 스크립트
- 추가: 인사이트와 권장사항 제공

## 핵심 원칙

1. **NEVER skip** 사전 조건 확인 문구 필수
2. 사전 검증 단계를 명시적으로 포함
3. 스크립트 실행 전 환경 확인
4. 결과 파싱 및 사용자 친화적 표시
5. 다음 단계 권장사항 제공 (AskUserQuestion 활용)

---

## 📋 다음 단계 추천 시 필수 규칙

### 규칙 1: AskUserQuestion 사용 강제

명령어 실행 중 또는 완료 후, **사용자에게 다음 단계를 물어보거나 선택을 요청할 때**,
반드시 AskUserQuestion 도구를 사용하세요.

#### ❌ 잘못된 예시
```
"마이그레이션이 완료되었습니다. 이제 DB를 동기화하시겠습니까?"
```

#### ✅ 올바른 예시
```
"마이그레이션이 완료되었습니다."

[AskUserQuestion 호출]
{
  "questions": [{
    "question": "DB를 동기화하시겠습니까?",
    "header": "다음 단계",
    "multiSelect": false,
    "options": [
      {
        "label": "예, /db-sync 실행",
        "description": "production DB를 development로 동기화합니다"
      },
      {
        "label": "나중에 수동으로",
        "description": "지금은 건너뜁니다"
      }
    ]
  }]
}
```

---

### 규칙 2: AskUserQuestion 응답 후 자동 실행

AskUserQuestion으로 사용자 응답을 받은 후, **반드시 다음 규칙을 따르세요**:

#### 사용자가 "예" 또는 "실행" 옵션 선택 시
→ **즉시 해당 슬래시 커맨드를 실행하세요**

**예시**:
```javascript
// AskUserQuestion 응답
{"0": "예, /db-sync 실행"}

// 다음 행동
SlashCommand("/db-sync")
```

#### 사용자가 "아니오" 또는 "나중에" 옵션 선택 시
→ 명령어 실행하지 않고 종료

---

### 규칙 3: 응답 해석 패턴

사용자 응답에서 의도를 정확히 파악하세요:

**실행 의도 키워드**:
- "예", "실행", "진행", "동기화", "Yes"

**거부 의도 키워드**:
- "아니오", "나중에", "수동", "건너뛰기", "No"

---

### Utility 타입 명령어의 일반적인 다음 단계

#### `/prisma-migrate` → `/db-sync`
- 마이그레이션 완료 후 DB 동기화 제안

#### `/db-sync` → 추천 없음
- DB 동기화는 최종 작업

#### `/dashboard` → 추천 없음
- 조회 전용 명령어

---

### 이점
1. **편리함**: 관련 작업을 연속으로 실행 가능
2. **실수 방지**: 마이그레이션 후 동기화를 잊어버리지 않음
3. **워크플로우 일관성**: 모든 명령어가 동일한 패턴 사용
