# /pr-review - Automated PR Review

**Claude를 위한 필수 지시사항:**

이 명령어가 실행될 때 반드시 다음 단계를 **순서대로** 따라야 합니다:

1. gh pr view와 gh pr diff를 사용하여 초기 분석 수행
2. PR 변경사항을 분석하여 코드 품질, 보안, 성능 검토
3. 장점, 이슈, 개선사항을 포함한 리뷰 리포트 생성
4. 코드 리뷰 코멘트 및 권장사항 제공
5. 진행하기 전에 사용자에게 리뷰 결과 확인 요청

**절대로 PR 분석 단계를 건너뛰지 마세요.**

---

## 📋 다음 단계 추천 시 필수 규칙

### 리뷰에서 수정사항 발견 시 커밋 제안 (선택 사항)

PR 리뷰 완료 후, **수정이 필요한 사항이 있을 때** 커밋 여부를 물어볼 때 AskUserQuestion 도구를 사용할 수 있습니다.

**✅ 올바른 예시:**
```
"리뷰 완료. 3개의 개선사항이 발견되었습니다."

[AskUserQuestion 호출 - 선택 사항]
- question: "개선사항을 적용하고 커밋하시겠습니까?"
- header: "다음 단계"
- options: ["예, 수정 후 /commit", "나중에"]
```

### 사용자 선택 후 행동

```javascript
{"0": "예, 수정 후 /commit"}  → 수정 후 SlashCommand("/commit")
{"0": "나중에"}                → 실행 안 함
```

---

## Overview

코드베이스 컨텍스트와 특정 PR 변경 사항의 지능형 분석을 통한 자동화된 Pull Request 리뷰입니다.

## Output Language

**IMPORTANT**: 사용자나 동료가 확인하는 모든 PR 리뷰 결과는 반드시 **한글로 작성**해야 합니다.

**한글 작성 대상:**
- PR 리뷰 리포트 전체
- 장점 및 이슈 설명
- 보안 취약점 분석
- 개선 제안사항
- 전체 평가 및 권장사항

**영어 유지:**
- PR 제목 (원본 유지)
- 코드, 파일 경로
- 기술 용어
- GitHub 사용자명

**예시 리포트:**
```
╔═══════════════════════════════════════╗
║   PR #42 리뷰                         ║
╚═══════════════════════════════════════╝

📋 PR 정보
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

제목: feat: Add user authentication
작성자: @username
변경 파일: 12개
+1,245 -89 라인

✅ 장점
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. 잘 구조화된 인증 플로우
2. 높은 테스트 커버리지 (92%)
3. 기존 auth/ 패턴 준수

⚠️  발견된 이슈
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[MEDIUM] Rate limiting 누락
  파일: src/api/login.ts:45
  → 무차별 대입 공격 방지를 위한 rate limiting 추가 필요

💡 제안사항
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

- 기존 src/utils/validator.ts 활용 권장
- 토큰 갱신 플로우에 대한 통합 테스트 추가

📊 종합 평가
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

점수: 85/100
권장사항: ✅ 경미한 수정 후 승인
```

이 커맨드는 다음을 수행합니다:
1. **PR 가져오기**: GitHub CLI를 사용하여 PR 세부 정보 다운로드
2. **변경 분석**: diff 및 커밋 히스토리 검토
3. **컨텍스트 기반 리뷰**: 기존 코드베이스에 미치는 영향 이해
4. **피드백 제공**: 보안, 품질, 아키텍처(architecture), 성능 분석

**주요 기능:**
- OWASP Top 10 보안 스캔
- Breaking change 감지
- 성능 영향 분석
- 아키텍처(architecture) 준수 확인
- 재사용성(reusability) 제안

## Usage

```bash
/pr-review <pr-number> [options]
```

### Options

| 옵션 | 설명 | 기본값 |
|--------|-------------|---------|
| `<pr-number>` | 리뷰할 PR 번호 | 필수 |
| `--full` | 전체 상세 리뷰 | `false` |
| `--security` | 보안 중심 리뷰 | `false` |

### Basic Commands

```bash
/pr-review 42              # PR #42 리뷰
/pr-review 42 --full       # 상세 리뷰
/pr-review 42 --security   # 보안 중심 리뷰
```

## Examples

### Example 1: Basic PR Review

```bash
/pr-review 42
```

**Output:**
```
╔═══════════════════════════════════════╗
║   PR #42 Review                       ║
╚═══════════════════════════════════════╝

📋 PR Info
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Title: feat: Add user authentication
Author: @username
Files: 12 changed
+1,245 -89 lines

✅ Strengths
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Well-structured authentication flow
2. Comprehensive test coverage (92%)
3. Follows existing patterns in auth/

⚠️  Issues Found
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[MEDIUM] Missing rate limiting
  File: src/api/login.ts:45
  → Add rate limiting to prevent brute force

[LOW] Inconsistent error messages
  Files: src/auth/*.ts
  → Use centralized error messages

💡 Suggestions
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

- Consider using existing src/utils/validator.ts
- Add integration tests for token refresh flow

📊 Overall Assessment
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Score: 85/100
Recommendation: ✅ APPROVE with minor changes
```

### Example 2: Security-Focused Review

```bash
/pr-review 42 --security
```

**Output:**
```
╔═══════════════════════════════════════╗
║   Security Review - PR #42            ║
╚═══════════════════════════════════════╝

🔒 OWASP Top 10 Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

❌ [CRITICAL] Password Stored in Plain Text
   File: src/models/user.ts:67
   Issue: Passwords not hashed
   Fix: Use bcrypt with salt rounds >= 12

⚠️  [HIGH] SQL Injection Risk
   File: src/api/users.ts:123
   Issue: String concatenation in query
   Fix: Use parameterized queries

✅ [PASS] XSS Prevention
   All user inputs properly sanitized

✅ [PASS] CSRF Protection
   Tokens implemented correctly

🛡️  Additional Checks
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  Dependencies: 2 vulnerabilities found
   - jsonwebtoken: Upgrade to 9.0.0+
   - express: Upgrade to 4.18.2+

📊 Security Score: 45/100
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Recommendation: ❌ REQUEST CHANGES
Critical issues must be fixed before merge
```

### Example 3: Full Detailed Review

```bash
/pr-review 42 --full
```

**포함 항목:**
- 코드 품질 분석
- 보안 스캔
- 성능 영향
- 아키텍처(architecture) 준수
- Breaking change 감지
- 테스트 커버리지 분석
- 문서화 완성도

## Implementation

### Architecture

다음을 제공하는 **reviewer-unified** 에이전트(agent)를 사용합니다:
- 다층 분석 (기본 → 고급)
- 코드베이스 컨텍스트 이해
- 기존 코드와의 패턴 매칭
- 영향도 평가

### Dependencies

**필수:**
- PR 가져오기를 위한 GitHub CLI (`gh`)
- reviewer-unified 에이전트(agent)
- 리모트가 있는 Git 저장소

**선택:**
- 아키텍처 설정: `.specify/config/architecture.json`
- 품질 게이트(quality gate): `workflow-gates.json`
- 의존성(dependency) 스캔을 위한 npm audit

### Workflow Steps

1. **PR 데이터 가져오기**
   - PR 세부 정보를 위해 `gh pr view <number>` 사용
   - 변경 사항을 위해 `gh pr diff <number>` 가져오기
   - 커밋 메시지 읽기

2. **컨텍스트 로드**
   - 아키텍처(architecture) 설정 로드
   - 품질 게이트(quality gate) 임계값 읽기
   - 코드베이스의 기존 패턴 스캔

3. **분석**
   - **코드 품질**: 스타일, 구조, 네이밍
   - **보안**: OWASP Top 10, 의존성 취약점
   - **성능**: N+1 쿼리, 메모리 누수, 비효율적 알고리즘
   - **아키텍처**: 패턴 준수, 레이어 위반
   - **Breaking Changes**: API 변경, 인터페이스 수정

4. **리포트 생성**
   - 심각도별로 발견 사항 분류
   - 라인 번호와 컨텍스트 제공
   - 구체적인 수정 방법 제안
   - 전체 점수 계산

### Related Resources

- **에이전트(Agent)**: reviewer-unified.md
- **CLI**: GitHub CLI (`gh`)
- **스킬(Skills)**: dependency-tracer, reusability-enforcer

## Review Criteria

### Code Quality (가중치: 30%)
- 가독성과 유지보수성
- 일관된 스타일과 네이밍
- 적절한 에러 처리
- 코드 중복

### Security (가중치: 30%)
- OWASP Top 10 취약점
- 인증 및 권한 부여
- 입력 검증
- 의존성(dependency) 취약점

### Architecture (가중치: 20%)
- 패턴 준수 (FSD, Clean 등)
- 레이어 분리
- 의존성 규칙
- Breaking change

### Performance (가중치: 20%)
- 쿼리 최적화
- 알고리즘 효율성
- 메모리 관리
- 캐싱 기회

## Review Grades

**90-100**: 우수
- 주요 이슈 없음
- 모범 사례 준수
- 포괄적인 테스트
- **조치**: 즉시 승인

**75-89**: 양호
- 경미한 개선 필요
- 전반적으로 견고한 구현
- **조치**: 코멘트와 함께 승인

**60-74**: 수용 가능
- 해결해야 할 여러 이슈
- 기능적이지만 개선 필요
- **조치**: 변경 요청 (비차단)

**60 미만**: 추가 작업 필요
- 치명적 이슈 존재
- 보안 또는 성능 우려
- **조치**: 변경 요청 (차단)

## Error Handling

### "PR not found"
- **원인**: 잘못된 PR 번호 또는 접근 권한 없음
- **해결**: `gh pr list`로 PR 번호 확인

### "gh not authenticated"
- **원인**: GitHub CLI에 로그인하지 않음
- **해결**: `gh auth login` 실행

### "Cannot fetch PR diff"
- **원인**: PR이 닫혔거나 병합됨
- **해결**: GitHub에서 PR 상태 확인

## Tips & Best Practices

### When to Use Each Mode

**기본 리뷰** (`/pr-review <number>`)
- 병합 전 빠른 확인
- 표준 PR 리뷰 프로세스
- 일상적인 개발 워크플로우(workflow)

**보안 중심** (`/pr-review <number> --security`)
- 인증/권한 변경
- API 엔드포인트 추가
- 외부 라이브러리 통합

**전체 리뷰** (`/pr-review <number> --full`)
- 주요 기능(feature)
- 프로덕션 배포 전
- 분기별 코드 감사

### Integration with CI/CD

```bash
# GitHub Actions에서
- name: Automated PR Review
  run: /pr-review ${{ github.event.pull_request.number }}
```

### Optimal Workflow

```bash
# PR 작성자로서
1. PR 생성: /pr
2. 셀프 리뷰: /pr-review <number>
3. 이슈 수정
4. 업데이트 푸시

# 리뷰어로서
1. 리뷰: /pr-review <number> --full
2. GitHub에 코멘트 남기기
3. 승인 또는 변경 요청
```

## Related Commands

- `/pr` - 리뷰 전 PR 생성
- `/review` - PR 전 로컬 변경 사항 리뷰
- `/commit` - 리뷰 수정 후 변경 사항 커밋
- `/major`, `/minor`, `/micro` - PR 생성 및 리뷰 포함

---

**Version**: 4.0.0
**Last Updated**: 2025-11-18
