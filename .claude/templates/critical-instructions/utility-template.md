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
