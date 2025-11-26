# /review - 지능형 코드 리뷰 시스템

---

## Critical Rules

@.claude/CLAUDE.md 의 규칙을 반드시 준수합니다.

이 명령어 실행 시 반드시 다음을 준수해야 합니다:

1. **코드 분석 필수**: 리뷰 전 반드시 대상 파일을 읽고 분석 (절대 건너뛰지 않음)
2. **옵션 검증**: --adv, --arch, --staged 옵션 사용 시 필요 조건 확인
3. **결과 확인 요청**: 리뷰 완료 후 반드시 사용자에게 확인 요청
4. **AskUserQuestion 사용**: 다음 단계 제안 시 필수 (텍스트 질문 금지)
5. **한글 출력**: 리뷰 리포트는 반드시 한글로 작성

---

## 필수 확인 사항

- [ ] 리뷰 대상 파일/디렉토리 존재 여부
- [ ] --staged 옵션 시 스테이징된 파일 존재 여부
- [ ] --adv 옵션 시 npm 설치 여부 (npm audit 사용)
- [ ] --arch 옵션 시 architecture.json 설정 존재 여부

---

**Claude를 위한 필수 지시사항:**

이 명령어가 실행될 때 반드시 다음 단계를 **순서대로** 따라야 합니다:

1. 파일 읽기와 아키텍처 분석을 사용하여 초기 분석 수행
2. 코드 품질, 보안, 성능을 종합적으로 검토
3. OWASP Top 10 및 아키텍처 패턴 준수 여부 확인
4. 이슈, 장점, 개선 제안을 포함한 리뷰 리포트 생성
5. 진행하기 전에 사용자에게 리뷰 결과 확인 요청

**절대로 코드 분석 단계를 건너뛰지 마세요.**

---

## 📋 다음 단계 추천 시 필수 규칙

### 리뷰 후 개선사항 적용 시 커밋 제안 (선택 사항)

코드 리뷰 완료 후, **개선사항을 적용한 경우** 커밋 여부를 물어볼 때 AskUserQuestion 도구를 사용할 수 있습니다.

**✅ 올바른 예시:**
```
"코드 리뷰 완료. 5개의 개선사항을 적용했습니다."

[AskUserQuestion 호출 - 선택 사항]
- question: "개선사항을 커밋하시겠습니까?"
- header: "다음 단계"
- options: ["예, /commit 실행", "나중에"]
```

### 사용자 선택 후 자동 실행

```javascript
{"0": "예, /commit 실행"}  → SlashCommand("/commit")
{"0": "나중에"}            → 실행 안 함
```

---

## Overview

보안, 품질, 성능, 아키텍처(architecture) 준수를 분석하는 종합 코드 리뷰(review) 시스템으로, reviewer-unified 에이전트(agent)를 활용합니다.

## Output Language

**IMPORTANT**: 사용자나 동료가 확인하는 모든 리뷰 결과는 반드시 **한글로 작성**해야 합니다.

**한글 작성 대상:**
- 리뷰 리포트 전체 (이슈, 제안사항, 요약)
- 보안 취약점 설명
- 성능 이슈 분석
- 아키텍처 준수 여부
- 개선 권장사항

**영어 유지:**
- 코드, 변수명, 함수명, 파일 경로
- 기술 용어 및 프레임워크 이름
- OWASP 카테고리 이름

**예시 리포트:**
```
╔═══════════════════════════════════════╗
║     코드 리뷰 리포트                   ║
╚═══════════════════════════════════════╝

📁 파일: src/auth/login.ts
📊 품질 점수: 85/100

✅ 장점:
  - 명확한 함수 분리
  - 적절한 에러 처리
  - TypeScript 타입 안정성

⚠️  발견된 이슈:

1. [MEDIUM] 입력 검증 누락
   45번 줄: user.password
   → 사용자 입력 처리 전 검증 추가 필요

💡 제안사항:
  - 기존 auth/validator.ts 활용 권장
  - 엣지 케이스 단위 테스트 추가
```

이 커맨드는 다음을 제공합니다:
1. **다층 분석**: 기본 구문 → 고급 보안/성능
2. **컨텍스트 기반 리뷰**: 코드베이스 패턴과 아키텍처 이해
3. **실행 가능한 피드백**: 수정 제안이 포함된 구체적 이슈
4. **품질 점수화**: 유지보수성과 신뢰성에 대한 수치 평가

**주요 기능:**
- OWASP Top 10 보안 스캔
- 성능 병목 현상 감지
- 아키텍처 패턴 준수 확인
- 의존성(dependency) 분석 및 영향도 평가
- 기존 코드베이스로부터 재사용성(reusability) 제안

## Usage

```bash
/review [options] [path]
```

### 옵션

| 옵션 | 설명 | 기본값 |
|--------|-------------|---------|
| `--staged` | 스테이징된 파일만 리뷰 | `false` |
| `--adv` | 고급 리뷰 (보안 + 성능) | `false` |
| `--arch` | 아키텍처 준수 확인 | `false` |
| `[path]` | 특정 파일 또는 디렉토리 | 현재 디렉토리 |

### 기본 명령어

```bash
/review                  # 모든 변경사항 리뷰
/review src/            # 특정 디렉토리 리뷰
/review --staged        # 스테이징된 파일만 리뷰
/review --adv           # 심층 보안/성능 분석
/review --arch          # 아키텍처 검증
```

## Examples

### Example 1: Basic Review

```bash
/review src/auth/login.ts
```

**Output:**
```
╔═══════════════════════════════════════╗
║     Code Review Report                ║
╚═══════════════════════════════════════╝

📁 File: src/auth/login.ts
📊 Quality Score: 85/100

✅ Strengths:
  - Clear function separation
  - Proper error handling
  - Type safety with TypeScript

⚠️  Issues Found:

1. [MEDIUM] Missing input validation
   Line 45: user.password
   → Add validation before processing user input

2. [LOW] Inconsistent naming
   Line 23: getUserData vs get_user_session
   → Use consistent camelCase naming

💡 Suggestions:
  - Consider using existing auth/validator.ts
  - Add unit tests for edge cases
```

### Example 2: Advanced Security Review

```bash
/review --adv src/api/
```

**Output:**
```
╔═══════════════════════════════════════╗
║  Advanced Security & Performance      ║
╚═══════════════════════════════════════╝

🔒 Security Scan (OWASP Top 10)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

❌ [HIGH] SQL Injection Risk
   File: api/users.ts:67
   Issue: Direct string concatenation in query
   Fix: Use parameterized queries

⚠️  [MEDIUM] XSS Vulnerability
   File: api/comments.ts:34
   Issue: Unsanitized user input in response
   Fix: Use DOMPurify or similar sanitizer

⚡ Performance Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  [MEDIUM] N+1 Query Problem
   File: api/posts.ts:89
   Impact: 50+ DB queries for single request
   Fix: Use JOIN or eager loading

📊 Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Security Issues:   2 high, 1 medium
Performance:       1 medium, 3 low
Overall Score:     68/100
```

### Example 3: Architecture Compliance

```bash
/review --arch
```

**Output:**
```
╔═══════════════════════════════════════╗
║  Architecture Compliance Check        ║
╚═══════════════════════════════════════╝

🏗  Detected: Feature-Sliced Design (FSD)

✅ Compliant:
  - features/auth follows FSD structure
  - Proper layer separation (ui → model → api)
  - No forbidden cross-slice imports

❌ Violations:

1. features/posts/ui → features/user/model
   → Shared logic should move to entities/

2. widgets/header → features/auth/api
   → Widgets shouldn't import feature internals

📋 Recommendations:
  - Extract shared user logic to entities/user
  - Use public API from features/auth/index.ts
```

## Implementation

### 아키텍처(Architecture)

**reviewer-unified** 에이전트(agent)를 사용하며, 다음을 결합합니다:
- 코드 품질 분석
- 보안 스캔 (OWASP Top 10)
- 성능 프로파일링
- 영향도 분석

### 의존성(Dependencies)

**필수:**
- reviewer-unified 에이전트
- 코드 분석을 위한 Grep/Read 도구

**선택:**
- 아키텍처 설정: `.specify/config/architecture.json`
- 품질 게이트(quality gate): `workflow-gates.json`
- 의존성 스캔을 위한 npm audit

### 워크플로우 단계

1. **범위 감지**
   - 리뷰할 파일 결정 (staged, path, 또는 전체)
   - 아키텍처 설정 읽기
   - 품질 게이트 임계값 로드

2. **분석**
   - **기본**: 구문, 네이밍, 구조
   - **고급**: 보안 취약점, 성능 이슈
   - **아키텍처**: 패턴 준수, 의존성 규칙

3. **점수 산정**
   - 품질 점수 계산 (0-100)
   - 치명적/높음/중간/낮음 이슈 식별
   - 품질 게이트와 비교

4. **리포트 생성**
   - 심각도 수준별로 결과 포맷
   - 구체적인 라인 번호와 수정 방법 제공
   - 재사용 가능한 기존 패턴 제안

### 관련 리소스

- **에이전트**: reviewer-unified.md
- **스킬**: reusability-enforcer, dependency-tracer
- **설정**: workflow-gates.json

## 프로세스 흐름

```
1. 인자 파싱
   ├─ --staged → 스테이징된 파일 가져오기
   ├─ --adv    → 보안/성능 스캔 활성화
   ├─ --arch   → 아키텍처 검증 활성화
   └─ [path]   → 특정 경로 스캔

2. 컨텍스트 로드
   ├─ 아키텍처 설정 읽기
   ├─ 품질 게이트 로드
   └─ 기존 패턴 스캔

3. 리뷰 실행
   ├─ 기본: 구문, 네이밍, 구조
   ├─ 보안: OWASP Top 10 체크
   ├─ 성능: 병목 현상 감지
   └─ 아키텍처: 패턴 준수 확인

4. 리포트 생성
   ├─ 심각도별로 분류
   ├─ 라인 번호 및 컨텍스트 추가
   ├─ 수정 방법 제안
   └─ 품질 점수 계산
```

## 모델 선택 로직

- **기본 리뷰**: 빠른 분석을 위해 `haiku` 사용
- **고급 리뷰**: 심층 보안/성능 분석을 위해 `sonnet` 사용
- **아키텍처 리뷰**: 패턴 이해를 위해 `sonnet` 사용

다음의 경우 자동으로 `sonnet`으로 업그레이드:
- 보안 이슈 감지
- 복잡한 아키텍처 패턴
- 성능 최적화 필요

## 통합 지점

### 워크플로우와 함께

```bash
# 커밋 전
/review --staged
/commit

# 기능 개발 중
/major "new feature"
# ... 구현 ...
/review --adv     # PR 전 심층 리뷰
/pr
```

### 품질 게이트와 함께

`workflow-gates.json`의 임계값을 준수합니다:
- 코드 품질: 80% 이상
- 테스트 커버리지: 80% 이상
- 보안: 높음/치명적 이슈 없음
- 성능: 차단 이슈 없음

### 아키텍처 검증과 함께

다음에 대한 규칙을 자동으로 강제합니다:
- FSD (Feature-Sliced Design)
- Clean Architecture
- Hexagonal Architecture
- DDD (Domain-Driven Design)

## 에러 처리

### "No files to review"
- **원인**: 빈 디렉토리 또는 변경사항 없음
- **해결**: 파일 스테이징 또는 유효한 경로 지정

### "Architecture config not found"
- **원인**: `.specify/config/architecture.json` 파일 누락
- **해결**: `/start` 실행으로 초기화 또는 수동 생성

### "Quality gate failed"
- **원인**: 임계값 이하의 점수
- **해결**: 높음/치명적 이슈를 먼저 해결 후 재시도

## 팁 및 모범 사례

### 각 모드 사용 시점

**기본 리뷰** (`/review`)
- 빠른 구문 및 스타일 검사
- 커밋 전
- 개발 중

**고급 리뷰** (`/review --adv`)
- PR 생성 전
- 보안에 민감한 코드 추가 후
- 성능 중요 기능(feature)

**아키텍처 리뷰** (`/review --arch`)
- 대규모 리팩토링 후
- 신규 개발자 온보딩
- 분기별 코드베이스 건강도 확인

### 최적의 워크플로우

```bash
# 개발 사이클
1. 기능 구현
2. /review --staged          # 빠른 확인
3. 이슈 수정
4. /review --adv            # 심층 분석
5. 보안/성능 문제 해결
6. /commit
7. /pr
```

### 성능 팁

- 전체 코드베이스 대신 특정 경로 리뷰
- 증분 리뷰를 위해 `--staged` 사용
- 필요할 때만 `--arch` 실행 (느림)

## 관련 커맨드

- `/commit` - 리뷰 통과 후 자동 커밋
- `/pr` - 리뷰 성공 후 PR 생성
- `/major` - 내장 리뷰 단계 포함
- `/minor` - 타겟 리뷰 포함

---

**Version**: 3.3.2
**Last Updated**: 2025-11-18
