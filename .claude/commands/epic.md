# /epic - Large Initiative Workflow

## Overview

복잡한 다중 기능(feature) 이니셔티브를 Feature와 Task로 분해하고 의존성(dependency) 추적 및 진행 상황 관리를 제공합니다.

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

이 커맨드는 다음을 제공합니다:
1. **Epic 계획**: 상위 수준 이니셔티브 분해
2. **Feature 분해**: Epic → 3-5개 Feature → 다수의 Task
3. **의존성(Dependency) 관리**: DAG 기반 의존성(dependency) 검증
4. **진행 상황 추적**: progress.md 및 roadmap.md 자동 업데이트
5. **품질 게이트(Quality Gate)**: 모든 기능(feature)이 표준 충족하도록 보장

**주요 기능:**
- 복잡도(complexity) 10+ 프로젝트 자동 구조화
- 의존성(dependency) 그래프가 순환 의존성(circular dependency) 방지
- epic.md, progress.md, roadmap.md 자동 생성
- 기능(feature) 구현을 위한 /major와 통합
- 성공 기준 추적

## Usage

```bash
/epic "initiative description"
```

이 커맨드는 다음을 수행합니다:
- `.specify/epics/<epic-id>/` 디렉토리 생성
- **Epic 브랜치 생성** (`NNN-epic-name`)
- **병합 대상 브랜치 물어봄** (main, develop 등)
- 분해 내용이 포함된 epic.md 생성
- 추적을 위한 progress.md 생성
- 타임라인이 포함된 roadmap.md 생성
- 의존성(dependency) 그래프 설정

### Branch Strategy

- **Branch Creation**: 자동 생성
- **Branch Name**: `NNN-epic-name` (예: `009-ecommerce-platform`)
- **Merge Target**: 실행 시 물어봄 (main, develop 등)
- **Features**: 모든 하위 features는 동일한 Epic 브랜치에서 작업

### Prerequisites

- 복잡한 이니셔티브 (복잡도(complexity) >= 10)
- 명확한 상위 수준 설명
- 전체 목표에 대한 이해

## Examples

### Example 1: Platform Migration

```bash
/epic "Migrate from monolith to microservices architecture"
```

**생성되는 구조:**
```
.specify/epics/011-microservices-migration/
├── epic.md                 # Epic 정의
├── progress.md             # 진행 상황 추적
├── roadmap.md              # 타임라인 및 의존성
├── features/
│   ├── 001-api-gateway.md
│   ├── 002-auth-service.md
│   ├── 003-user-service.md
│   ├── 004-order-service.md
│   └── 005-deployment.md
└── dependencies.json       # 의존성 그래프
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
1. 오프라인 데이터 동기화 엔진
2. iOS 네이티브 앱 (Swift UI)
3. Android 네이티브 앱 (Jetpack Compose)
4. 동기화를 위한 백엔드 API
5. 앱 스토어 배포 파이프라인

### Example 3: Security Overhaul

```bash
/epic "Complete security audit and remediation"
```

**Features:**
1. 취약점 평가 및 우선순위 지정
2. 인증 시스템 강화
3. 데이터 암호화 구현
4. 보안 모니터링 및 알림
5. 규정 준수 문서화

## Implementation

### Architecture

Epic 워크플로우(workflow)는 다음을 사용합니다:
- **architect-unified**: 상위 수준 설계용
- **Major 워크플로우(workflow)**: 각 기능(feature) 구현용
- **진행 상황 추적**: 자동 업데이트되는 마크다운 파일
- **의존성(Dependency) 검증**: 순환 의존성(circular dependency) 방지

### Dependencies

**필수:**
- `.specify/` 디렉토리 구조
- Git 저장소
- 모든 통합 에이전트(unified agent)

**선택:**
- 프로젝트 관리 통합 (Notion, Jira)
- 기능(feature)을 위한 CI/CD 파이프라인

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
