# /epic - Large Initiative Workflow

## Overview

Manages complex multi-feature initiatives by breaking them into Features and Tasks with dependency tracking and progress management.

## Output Language

**IMPORTANT**: 사용자나 동료가 확인하는 모든 문서와 출력은 반드시 **한글로 작성**해야 합니다.

**한글 작성 대상:**
- epic.md - Epic 정의 및 분해 전체
- progress.md - 진행 상황 추적 문서
- roadmap.md - 타임라인 및 마일스톤
- 각 Feature 문서
- 진행 상황 메시지
- 에러 메시지 및 경고

**영어 유지:**
- 코드, 변수명, 함수명, 파일 경로
- 기술 용어
- 명령어

**예시 문서 구조:**
```markdown
# Epic: 마이크로서비스 마이그레이션

## Vision
모놀리식 애플리케이션을 확장 가능한 마이크로서비스 아키텍처로 전환

## Complexity Assessment
- Score: 15/15 (매우 복잡)
- Duration: 8-12주
- Team Size: 3-5명의 개발자
...
```

This command provides:
1. **Epic Planning**: High-level initiative breakdown
2. **Feature Decomposition**: Epic → 3-5 Features → Multiple Tasks
3. **Dependency Management**: DAG-based dependency validation
4. **Progress Tracking**: Auto-updated progress.md and roadmap.md
5. **Quality Gates**: Ensures all features meet standards

**Key Features:**
- Complexity 10+ projects automatically structured
- Dependency graph prevents circular dependencies
- Auto-generates epic.md, progress.md, roadmap.md
- Integration with /major for feature implementation
- Success criteria tracking

## Usage

```bash
/epic "initiative description"
```

The command will:
- Create `.specify/epics/<epic-id>/` directory
- **Create Epic branch** (`NNN-epic-name`)
- **Ask for merge target branch** (main, develop 등)
- Generate epic.md with decomposition
- Create progress.md for tracking
- Generate roadmap.md with timeline
- Set up dependency graph

### Branch Strategy

- **Branch Creation**: 자동 생성
- **Branch Name**: `NNN-epic-name` (예: `009-ecommerce-platform`)
- **Merge Target**: 실행 시 물어봄 (main, develop 등)
- **Features**: 모든 하위 features는 동일한 Epic 브랜치에서 작업

### Prerequisites

- Complex initiative (complexity >= 10)
- Clear high-level description
- Understanding of overall goals

## Examples

### Example 1: Platform Migration

```bash
/epic "Migrate from monolith to microservices architecture"
```

**Generated Structure:**
```
.specify/epics/011-microservices-migration/
├── epic.md                 # Epic definition
├── progress.md             # Progress tracking
├── roadmap.md              # Timeline and dependencies
├── features/
│   ├── 001-api-gateway.md
│   ├── 002-auth-service.md
│   ├── 003-user-service.md
│   ├── 004-order-service.md
│   └── 005-deployment.md
└── dependencies.json       # Dependency graph
```

**epic.md Content:**
```markdown
# Epic: Microservices Migration

## Vision
Transform monolithic application into scalable microservices architecture

## Complexity Assessment
- Score: 15/15 (Very Complex)
- Duration: 8-12 weeks
- Team Size: 3-5 developers

## Features Breakdown

### Feature 001: API Gateway
- **Complexity**: 8
- **Dependencies**: None
- **Estimated**: 2 weeks
- **Tasks**:
  - Setup Kong/Nginx gateway
  - Configure routing rules
  - Implement rate limiting
  - Add authentication middleware

### Feature 002: Auth Service
- **Complexity**: 7
- **Dependencies**: 001 (API Gateway)
- **Estimated**: 1.5 weeks
- **Tasks**:
  - Extract auth logic from monolith
  - Create standalone auth service
  - Implement JWT tokens
  - Add OAuth2 support

[... features 003-005 ...]

## Success Criteria
- [ ] All services independently deployable
- [ ] <100ms latency overhead
- [ ] Zero downtime migration
- [ ] 99.9% uptime SLA

## Risk Mitigation
- **Risk**: Data consistency during migration
  **Mitigation**: Implement two-phase commit pattern

- **Risk**: Service discovery failures
  **Mitigation**: Use Consul with health checks
```

### Example 2: Multi-Platform App

```bash
/epic "Launch iOS and Android apps with offline-first architecture"
```

**Features:**
1. Offline data sync engine
2. iOS native app (Swift UI)
3. Android native app (Jetpack Compose)
4. Backend API for sync
5. App store deployment pipeline

### Example 3: Security Overhaul

```bash
/epic "Complete security audit and remediation"
```

**Features:**
1. Vulnerability assessment and prioritization
2. Authentication system hardening
3. Data encryption implementation
4. Security monitoring and alerts
5. Compliance documentation

## Implementation

### Architecture

Epic workflow uses:
- **architect-unified**: For high-level design
- **Major workflow**: For each feature implementation
- **Progress tracking**: Auto-updated markdown files
- **Dependency validation**: Prevents circular deps

### Dependencies

**Required:**
- `.specify/` directory structure
- Git repository
- All unified agents

**Optional:**
- Project management integration (Notion, Jira)
- CI/CD pipeline for features

### Workflow Steps

1. **Epic Creation**
   - Parse epic description
   - Assess complexity (must be >= 10)
   - Create epic directory structure

2. **Feature Decomposition**
   - Break into 3-5 major features
   - Assign complexity scores
   - Identify dependencies
   - Estimate timelines

3. **Dependency Graph**
   - Create DAG (Directed Acyclic Graph)
   - Validate no circular dependencies
   - Determine feature order

4. **Documentation Generation**
   - epic.md: Full spec and decomposition
   - progress.md: Feature checklist and status
   - roadmap.md: Timeline and milestones
   - dependencies.json: Graph data

5. **Feature Implementation**
   - Use `/major` for each feature
   - Update progress.md automatically
   - Track completion percentage

### Related Resources

- **Agents**: architect-unified, all unified agents
- **Commands**: /major (for feature implementation)
- **Files**: .specify/epics/<epic-id>/

## Epic vs Major

### When to Use /epic

- Complexity score 10-15
- Multiple related features
- 4+ weeks estimated duration
- Team collaboration needed
- Requires architectural changes

### When to Use /major

- Complexity score 5-9
- Single feature scope
- 1-3 weeks duration
- Individual developer work
- Fits existing architecture

### Relationship

```
Epic: Microservices Migration (.specify/epics/011-microservices-migration/)
├── Feature 1: API Gateway → /major "API Gateway"
├── Feature 2: Auth Service → /major "Auth Service"
├── Feature 3: User Service → /major "User Service"
└── Feature 4: Deployment → /major "Deployment Pipeline"

All features work in the same Epic branch: 011-microservices-migration
```

## Progress Tracking

### progress.md Format

```markdown
# Epic Progress: Microservices Migration

**Status**: In Progress (60%)
**Started**: 2025-11-01
**Target**: 2025-12-31

## Features

- [x] ✅ Feature 001: API Gateway (100%)
- [x] ✅ Feature 002: Auth Service (100%)
- [ ] 🚧 Feature 003: User Service (70%)
- [ ] ⏳ Feature 004: Order Service (0%)
- [ ] ⏳ Feature 005: Deployment (0%)

## Milestones

- [x] Architecture design complete
- [x] API Gateway deployed to staging
- [ ] First service migrated to production
- [ ] All services deployed
- [ ] Monolith decommissioned

## Blockers

- Feature 003: Need database migration strategy
- Feature 004: Waiting for payment provider API
```

### Auto-Update

Progress is automatically updated when:
- Feature tasks completed
- /major workflow finishes
- Manual updates to task status

## Dependency Management

### dependencies.json Format

```json
{
  "features": {
    "001": {
      "name": "API Gateway",
      "dependencies": [],
      "dependents": ["002", "003", "004"]
    },
    "002": {
      "name": "Auth Service",
      "dependencies": ["001"],
      "dependents": ["003", "004"]
    },
    "003": {
      "name": "User Service",
      "dependencies": ["001", "002"],
      "dependents": ["004"]
    }
  }
}
```

### Validation Rules

- No circular dependencies
- All dependencies must exist
- Dependency order determines implementation sequence
- Blocked features cannot start until deps complete

## Error Handling

### "Complexity too low"
- **Cause**: Epic scope < 10 complexity
- **Fix**: Use `/major` instead or expand scope

### "Circular dependency detected"
- **Cause**: Feature A depends on B, B depends on A
- **Fix**: Redesign to remove cycle

### "Feature count out of range"
- **Cause**: < 3 or > 7 features
- **Fix**: Rebalance feature breakdown

## Tips & Best Practices

### Epic Planning

1. **Start with Vision**: Clear end goal
2. **Identify Major Features**: 3-5 distinct areas
3. **Map Dependencies**: Which features need what
4. **Estimate Realistically**: Add buffer time
5. **Define Success**: Measurable criteria

### Feature Breakdown

- Each feature should be independently valuable
- Aim for 1-3 week duration per feature
- Keep dependencies minimal
- Start with foundation features first

### Progress Management

```bash
# Start epic
/epic "initiative description"

# Implement features in dependency order
/major "Feature 001"  # No deps, start first
/major "Feature 002"  # Depends on 001

# Check progress anytime
cat .specify/epics/<epic-id>/progress.md

# Update roadmap as needed
# Edit roadmap.md manually or regenerate
```

### Team Collaboration

- Assign features to team members
- Review progress.md daily
- Update blockers immediately
- Celebrate milestone completion

## Related Commands

- `/major` - Implement individual features
- `/triage` - Determine if task is Epic-worthy
- `/review` - Review feature implementations
- `/pr` - Create PRs for completed features

---

**Version**: 3.3.1
**Last Updated**: 2025-11-18
