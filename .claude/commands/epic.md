# /epic - Large Initiative Workflow

**Claude를 위한 필수 지시사항:**

이 명령어가 실행될 때 반드시 다음 단계를 **순서대로** 따라야 합니다:

1. **아직 코드를 작성하지 마세요**
2. 대화 맥락에서 epic 비전과 범위를 수집하세요
3. 기능으로 분해하세요 (3-10개 기능)
4. 재사용 가능한 아키텍처 패턴을 검색하세요
5. **.specify/epics/NNN-epic-name/epic-plan.md 문서를 생성하세요**
6. 기능 계획으로 진행하기 전에 사용자 승인을 기다리세요

**절대로 epic-plan.md 생성 단계를 건너뛰지 마세요.**

---

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

### Branch State 처리

`branch-state-handler.sh` 실행 시:

1. **변경사항 감지 시 중단**
   - 스크립트가 uncommitted changes를 감지하면 자동으로 중단됩니다

2. **AskUserQuestion으로 5가지 옵션 제공**
   - 커밋 후 계속 (Commit and continue)
   - 변경사항과 함께 이동 (Move with changes)
   - Stash 후 계속 (Stash and continue)
   - 변경사항 삭제 - ⚠️ 복구 불가 (Discard and continue)
   - 취소 (Cancel)

3. **사용자 선택을 환경 변수로 전달**
   ```bash
   BRANCH_ACTION="commit"  # 또는 move_with_changes, stash, discard, cancel
   ```

4. **스크립트 재실행하여 선택 처리**
   - 선택된 동작이 자동으로 수행됩니다

### Prerequisites

- 복잡한 이니셔티브 (복잡도(complexity) >= 10)
- 명확한 상위 수준 설명
- 전체 목표에 대한 이해

### 흐름 중단 시 대처

명령어 실행 중 수정이 필요한 경우:

1. **자유롭게 수정 요청**
   - "이 부분을 먼저 수정해줘"
   - "다시 설명해줄래?"
   - "파일 X를 수정하고 올게"

2. **수정 완료 후 복귀**
   - 수정 완료 후 "계속" 또는 "진행" 입력
   - 저장된 컨텍스트에서 자동으로 재개

3. **컨텍스트 복귀 옵션**
   - **계속하기**: 중단된 위치에서 재개
   - **새로 시작**: 기존 진행 상황 삭제하고 처음부터

**예시 시나리오:**
```
사용자: /epic "마이크로서비스 전환"
Claude: [Feature 분해 진행 중...]

사용자: "잠깐, 아키텍처 문서를 먼저 검토할게"
Claude: [작업 컨텍스트 저장]

[사용자가 문서 검토 완료]

사용자: "계속"
Claude: [Feature 분해부터 재개]
```

## Notion Integration

**사용자가 Notion 연동을 선택한 경우**, 다음 단계를 수행합니다:

### 1. Notion MCP 조회

먼저 연결된 Notion MCP 서버 목록을 확인합니다:

```bash
# 사용 가능한 MCP 서버 확인
# mcp__notion-personal 또는 mcp__notion-company 등
```

### 2. MCP 선택

사용자에게 어떤 Notion MCP를 사용할지 물어봅니다:

**AskUserQuestion 사용:**
- question: "어떤 Notion workspace를 사용하시겠습니까?"
- header: "Notion 선택"
- options: 조회된 MCP 목록 (동적 생성)
  - mcp__notion-personal → "개인 workspace"
  - mcp__notion-company → "회사 workspace"

### 3. 페이지 정보 입력

사용자에게 Epic을 작성할 페이지 정보를 물어봅니다:

**AskUserQuestion 사용:**
- question: "Epic을 어디에 작성하시겠습니까?"
- header: "페이지 선택"
- options:
  - "새 페이지 생성" → 자동으로 Epic 페이지 생성
  - "기존 페이지 사용" → 페이지명 또는 페이지 ID 입력받기

**페이지 ID/이름 입력 시:**
```
사용자 입력 예시:
- 페이지명: "2025 Product Roadmap"
- 페이지 ID: "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
- 페이지 URL: "https://notion.so/workspace/Page-Title-abc123"
```

### 4. Epic 페이지 생성

선택된 Notion MCP를 사용하여 Epic 페이지를 생성하고 진행상황을 추적합니다:

```markdown
# Epic 페이지 구조
- Epic 개요
- Features 체크리스트
- 진행률 (%)
- 타임라인 (roadmap.md 연동)
- 주간 리포트 (자동 업데이트)
```

### 5. 자동 동기화

Epic 진행 중 자동으로 Notion 페이지를 업데이트합니다:
- Feature 완료 시 체크리스트 업데이트
- 진행률 자동 계산
- 주간 리포트 생성 (매주 자동)

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
