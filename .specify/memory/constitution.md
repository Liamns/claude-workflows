# Constitution

## Metadata
- Version: 1.0.0
- Created: {YYYY-MM-DD}
- Last Amended: {YYYY-MM-DD}
- Status: Active

## Preamble

{프로젝트 타입 및 목적 설명}

This Constitution establishes the inviolable principles governing the development of {Project Name}. These articles form the foundation of all technical decisions and development processes.

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
