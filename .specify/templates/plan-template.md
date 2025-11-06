# Implementation Plan: {Feature Name}

## Technical Foundation

### Language/Version
{구체적 값 또는 NEEDS CLARIFICATION}

예시:
- TypeScript: 5.x
- Node.js: 20.x

### Primary Dependencies
{주요 라이브러리 및 버전}

예시:
- React: 19.x
- React Query: 5.x
- Zustand: 4.x
- Zod: 3.x
- React Hook Form: 7.x

### Storage
{데이터 저장 방식}

예시:
- Local State: Zustand
- Server State: React Query
- Persistence: localStorage
- Database: PostgreSQL (Backend)

### Testing Framework
{테스트 프레임워크}

예시:
- Unit: Vitest
- Integration: Vitest + Testing Library
- E2E: Playwright
- API Mocking: MSW

## Constitution Check

| Article | Status | Violations | Justification | Alternatives Rejected |
|---------|--------|------------|---------------|---------------------|
| I: Library-First | {✅/⚠️/❌} | {None/설명} | {근거} | {대안} |
| II: External Config | {✅/⚠️/❌} | {None/설명} | {근거} | {대안} |
| III: Test-First | {✅/⚠️/❌} | {None/설명} | {근거} | {대안} |
| IV: Repository Structure | {✅/⚠️/❌} | {None/설명} | {근거} | {대안} |
| V: Issue Tracking | {✅/⚠️/❌} | {None/설명} | {근거} | {대안} |
| VI: Deployment | {✅/⚠️/❌} | {None/설명} | {근거} | {대안} |
| VII: Simplicity | {✅/⚠️/❌} | {None/설명} | {근거} | {대안} |
| VIII: Anti-Abstraction | {✅/⚠️/❌} | {None/설명} | {근거} | {대안} |
| IX: Integration-First | {✅/⚠️/❌} | {None/설명} | {근거} | {대안} |

**Summary:**
- ✅ Feasible / ⚠️ Violations with justification / ❌ Blocked

## Phase 0: Research

[Link to research.md](./research.md)

**Key Findings:**
- {주요 발견 사항 1}
- {주요 발견 사항 2}
- {주요 발견 사항 3}

**Risks Identified:**
- {리스크 1}: {완화 방안}
- {리스크 2}: {완화 방안}

## Phase 1: Design Artifacts

### Data Model
[Link to data-model.md](./data-model.md)

**Entities:**
- {Entity1}: {간단한 설명}
- {Entity2}: {간단한 설명}

### API Contracts
[Link to contracts/openapi.yaml](./contracts/openapi.yaml)

**Endpoints:**
- POST /{endpoint1}: {설명}
- GET /{endpoint2}: {설명}

### Quickstart Guide
[Link to quickstart.md](./quickstart.md)

**Setup Steps:**
1. {단계 1}
2. {단계 2}
3. {단계 3}

## Source Code Structure

{프로젝트 타입에 따라 작성}

### Single Project
```
src/
├── features/
│   └── {feature-name}/
│       ├── api/
│       ├── model/
│       ├── lib/
│       └── ui/
├── entities/
│   └── {entity}/
│       ├── model/
│       └── ui/
├── shared/
│   ├── api/
│   ├── lib/
│   └── ui/
└── app/
    ├── model/
    └── config/
```

### Web App
```
packages/
├── web/
│   └── src/
│       └── {위와 동일}
└── shared/
    └── types/
```

### Mobile + API
```
projects/
├── mobile/
│   └── src/
│       └── {위와 동일}
├── api/
│   └── src/
│       ├── controllers/
│       ├── services/
│       └── models/
└── shared/
    └── contracts/
```

## Implementation Phases

{실제 구현은 tasks.md에서 관리}

### Phase 1: Setup & Prerequisites
{초기 설정 작업}

### Phase 2: Foundation
{핵심 인프라 구축}

### Phase 3: User Stories Implementation
{사용자 스토리별 구현}

### Phase N: Polish & Documentation
{마무리 작업}

## Notes

{추가 참고사항}
