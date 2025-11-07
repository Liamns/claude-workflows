# Constitution

## Metadata
- Version: 1.0.0
- Created: {YYYY-MM-DD}
- Last Amended: {YYYY-MM-DD}
- Status: Active

## Preamble

{프로젝트 타입 및 목적 설명}

이 헌장(Constitution)은 {Project Name} 개발을 관장하는 불가침의 원칙들을 수립합니다. 이 조항들은 모든 기술적 의사결정과 개발 프로세스의 기반을 형성합니다.

## Article 0: Official Language Policy

**Status:** Enabled

**Principle:**
이 프로젝트의 공식 언어는 **한글**입니다. 모든 문서, 설명, Claude의 응답은 한글로 작성됩니다.

**Scope:**
- **한글로 작성:** 문서(README, 가이드, 튜토리얼), 코드 주석, 커밋 메시지 본문, PR/이슈 설명, CHANGELOG, Claude 응답
- **영어 사용 가능:** 코드(변수명, 함수명, 클래스명), Conventional Commits 키워드(feat, fix, docs 등), 외부 라이브러리 인용
- **병기 원칙:** 기술 용어는 한글 번역 후 괄호 안에 영어 표기 (예: 컴포넌트(Component), 엔드포인트(Endpoint))

**Implementation:**
```
# 커밋 메시지 예시
feat: 사용자 프로필 편집 기능 추가

사용자가 이름, 이메일, 프로필 사진을 수정할 수 있도록
프로필 편집 폼과 API 연동을 구현했습니다.

# 코드 주석 예시
// 사용자 인증 토큰을 검증하고 갱신합니다
function validateAndRefreshToken() { ... }
```

**Rationale:**
- 팀 커뮤니케이션 효율성 극대화
- 도메인 지식의 명확한 전달
- 문서 접근성 향상
- 유지보수 용이성

**Documentation Migration:**
기존 영어 문서는 점진적으로 한글로 전환합니다:
1. 우선순위 높음: README, 주요 가이드, constitution
2. 우선순위 중간: agent/skill/command 설명, CHANGELOG, ARCHITECTURE
3. 우선순위 낮음: 예제 코드 주석, 템플릿

## Article I: Library-First Principle

**Status:** {Enabled/Disabled}

**Principle:**
Always prefer external, battle-tested libraries over custom implementations.

**Rationale:**
- Reduces development time
- Leverages community testing and maintenance
- Avoids reinventing the wheel

**Exceptions:**
- Library does not exist for specific use case
- External library has critical security vulnerabilities
- License incompatibility

**Implementation:**
{프로젝트별 구체적 적용 방법}

## Article II: External Configuration

**Status:** Enabled

**Principle:**
All configuration values must be externalized (environment variables, config files).

**Rationale:**
- Enables environment-specific deployments
- Prevents hardcoded secrets in code
- Facilitates CI/CD pipelines

**Implementation:**
- Use `.env` files for local development
- Use environment variables for production
- Never commit secrets to version control

## Article III: Test-First Imperative

**Status:** {Enabled/Disabled}

**Principle:**
Write tests BEFORE implementation (TDD).

**Rationale:**
- Ensures testability
- Clarifies requirements
- Prevents regression

**Implementation:**
- Unit tests: Vitest
- Integration tests: Vitest + Testing Library
- E2E tests: Playwright
- Target coverage: 80%+

**Exceptions:**
- Rapid prototyping phase
- Exploratory coding
- Configuration files

## Article IV: Repository Structure

**Status:** Enabled

**Principle:**
{Single Repository / Multiple Repositories}

**Structure:**
```
{프로젝트 구조}
```

## Article V: Issue Tracking

**Status:** Enabled

**Principle:**
All work must be tracked via issue tracking system.

**System:** {GitHub Issues / Jira / Linear / Notion}

**Process:**
1. Create issue before starting work
2. Link commits to issues
3. Close issues with PR merge

## Article VI: Deployment

**Status:** Enabled

**Principle:**
Automated deployment via CI/CD pipeline.

**Strategy:**
- Development: Auto-deploy on merge to `develop` branch
- Staging: Auto-deploy on merge to `staging` branch
- Production: Manual approval required

**Tools:**
- CI/CD: {GitHub Actions / GitLab CI / AWS Amplify}
- Hosting: {Vercel / Netlify / AWS}

## Article VII: Simplicity

**Status:** Enabled

**Principle:**
Start with ≤3 projects initially. Add complexity only when necessary.

**Rationale:**
- Reduces cognitive load
- Faster onboarding
- Easier maintenance

**Current Structure:**
{프로젝트 개수 및 구조}

## Article VIII: Anti-Abstraction

**Status:** {Enabled/Disabled}

**Principle:**
Avoid premature abstraction. Prefer duplication over wrong abstraction.

**Rationale:**
- Abstractions are hard to change
- Duplication can be refactored later
- Wrong abstractions increase complexity

**Guidelines:**
- Use the "Rule of Three": Abstract only after 3+ instances
- Prefer composition over inheritance
- Keep abstractions close to usage

**Exceptions:**
- Framework-required abstractions
- Proven abstraction patterns (e.g., Repository pattern)
- Cross-cutting concerns (logging, error handling)

## Article IX: Integration-First Testing

**Status:** {Enabled/Disabled}

**Principle:**
Prioritize integration tests over unit tests.

**Rationale:**
- Tests user workflows, not implementation details
- More robust against refactoring
- Higher confidence in system behavior

**Implementation:**
- Write integration tests for all user scenarios
- Unit tests for complex business logic only
- E2E tests for critical paths

## Article X: Reusability-First Principle

**Status:** Enabled

**Principle:**
모든 코드 작성 시 다음 우선순위를 따른다:
1. **기존 패턴 검색**: 프로젝트에 이미 구현된 유사 기능/패턴 확인
2. **기존 패턴 활용**: 발견된 패턴을 그대로 따라 일관성 유지
3. **새 패턴 정립**: 기존 패턴이 없을 경우, 재사용 가능한 형태로 설계하여 향후 표준으로 사용

**Rationale:**
- 코드 일관성 최우선
- 기존 패턴 존중
- 개발 속도 향상
- 유지보수성 대폭 개선

**Implementation Process:**

### 1. 코드 작성 전 (Pre-Implementation)
**필수 실행 단계:**
1. **기존 패턴 검색**
   - API 호출 패턴: 어떤 방식으로 API를 호출하는가?
   - 상태 관리 패턴: 어떻게 상태를 관리하는가?
   - 폼 처리 패턴: 폼 제출을 어떻게 처리하는가?
   - 에러 처리 패턴: 에러를 어떻게 처리하는가?
   - 스타일링 패턴: 스타일을 어떻게 적용하는가?

2. **패턴 분석 및 적용**
   - 기존 패턴 발견 → 완전히 동일한 방식으로 구현
   - 유사 패턴 발견 → 최대한 비슷하게 맞춰 구현
   - 패턴 없음 → 팀과 협의 후 새 표준 정립

### 2. 새 모듈 작성 시 (During Implementation)
**재사용성 체크리스트:**
- [ ] 2회 이상 사용 예상되는가?
- [ ] 도메인 독립적인가?
- [ ] Props/파라미터가 10개 이하인가?
- [ ] 테스트 가능한 형태인가?
- [ ] 명확한 단일 책임을 가지는가?

**배치 규칙:**
- 3개 이상 feature에서 사용 → `shared/`
- 도메인 독립적 → `shared/lib/`
- 도메인 특정적 (순수) → `entities/{domain}/`
- 비즈니스 로직 포함 → `features/{action}/`

### 3. 코드 작성 후 (Post-Implementation)
- 10줄 이상 중복 코드 발견 시 → 추출 및 재사용 모듈화
- 유사 패턴 3회 이상 발견 시 → 추상화 필수
- 새 모듈은 반드시 문서화 (JSDoc + 예제)

**Enforcement:**
- `/triage` 실행 시 자동으로 재사용성 체크 실행
- Major 워크플로우: 필수 적용
- Minor 워크플로우: 권장 적용
- Micro 워크플로우: 선택 적용

**Metrics:**
- 목표 재사용률: 60% 이상
- 허용 중복 코드: 5% 이하
- shared 컴포넌트 사용률: feature당 10개 이상

**Exceptions:**
- 프로토타입 코드 (명시적으로 "prototype" 표시)
- 일회성 마이그레이션 스크립트
- 외부 API 특정 어댑터 코드
## Amendment Procedure

**Process:**
1. Propose amendment with justification
2. Team review and discussion
3. Majority approval required
4. Update Constitution version
5. Document in Amendment History

**Amendment History:**
- {Version} - {Date} - {Change Description}

## Enforcement

**Violations:**
Violations of Constitution principles must be:
1. Documented in `plan.md` with justification
2. Reviewed by team
3. Approved before implementation

**Review Process:**
- Pre-implementation: Constitution Check in `plan.md`
- During-implementation: Automated checks where possible
- Post-implementation: Code review verification
