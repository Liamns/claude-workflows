# 🚀 Start - 프로젝트 초기화 및 Architecture 설정

## Overview

Initialize Claude Workflows in your project with automatic architecture detection and setup.

## Output Language

**IMPORTANT**: 사용자가 확인하는 모든 초기화 메시지와 설정 정보는 반드시 **한글로 작성**해야 합니다.

**한글 작성 대상:**
- 초기화 진행 상황 메시지
- 아키텍처 감지 결과
- 설정 파일 생성 안내
- Constitution 생성 내용
- 검증 결과 및 권장사항

**영어 유지:**
- 아키텍처 이름 (FSD, Clean Architecture 등)
- 파일 경로
- 명령어

**예시 출력:**
```
🚀 Claude Workflows - 프로젝트 초기화
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 프로젝트 구조 분석 중...

✓ 발견: package.json
✓ 발견: src/ 디렉토리
✓ 감지됨: React 애플리케이션

🎯 아키텍처 감지: Feature-Sliced Design (FSD)
신뢰도: 95%

📝 설정 파일 생성 중:
- .specify/memory/constitution.md 생성
- .specify/config/architecture.json 생성
```

This command:
1. **Detects Architecture**: Analyzes existing codebase structure
2. **Configures Templates**: Sets up architecture-specific templates
3. **Creates Constitution**: Generates project-specific rules and guidelines
4. **Initializes Agents**: Configures unified agents for your architecture
5. **Verifies Setup**: Ensures all components are properly configured

**Key Features:**
- 32 architecture templates (Backend, Frontend, Fullstack, Mobile)
- Auto-detection of existing patterns
- Multi-architecture support for fullstack projects
- Constitutional constraints generation
- Quality gates configuration

## Usage

```bash
/start
```

The command will:
- Analyze your project structure
- Detect or prompt for architecture selection
- Generate configuration files
- Set up quality gates
- Verify installation

### Supported Architectures

**Backend (5)**:
- Clean Architecture
- Domain-Driven Design (DDD)
- Hexagonal Architecture
- Layered Architecture
- Serverless

**Frontend (4)**:
- Feature-Sliced Design (FSD)
- Atomic Design
- Model-View-Controller (MVC)
- Micro-Frontend

**Fullstack (2)**:
- JAMStack
- Monorepo

**Mobile (2)**:
- Clean Architecture (Mobile)
- MVVM (Model-View-ViewModel)

## Examples

### Example 1: New React Project (FSD)

```bash
/start
```

**Output:**
```
🚀 Claude Workflows - Project Initialization
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Analyzing project structure...

✓ Found: package.json
✓ Found: src/ directory
✓ Detected: React application

🔍 Architecture Detection:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Analyzing directories...
✓ src/app/
✓ src/pages/
✓ src/widgets/
✓ src/features/
✓ src/entities/
✓ src/shared/

🎯 Detected Architecture: Feature-Sliced Design (FSD)
Confidence: 95%

📝 Configuration:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Creating .specify/memory/constitution.md
- FSD layer rules
- Import constraints
- Naming conventions

Creating .specify/config/architecture.json
- Architecture: "fsd"
- Layers: [app, pages, widgets, features, entities, shared]
- Validation: enabled

Creating workflow-gates.json
- Major workflow gates
- Minor workflow gates
- Reusability checks

✅ Setup Complete!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Next Steps:
1. Review .specify/memory/constitution.md
2. Run: /triage "your first task"
3. Start development with /major, /minor, or /micro

Architecture: Feature-Sliced Design (FSD)
Templates: 15 components ready
Agents: 6 unified agents configured
```

### Example 2: Backend API (Clean Architecture)

```bash
/start
```

**Output:**
```
🚀 Claude Workflows - Project Initialization
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Analyzing project structure...

✓ Found: package.json
✓ Found: src/ directory
✓ Detected: Node.js backend

🔍 Architecture Detection:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Analyzing directories...
✓ src/domain/
✓ src/application/
✓ src/infrastructure/
✓ src/presentation/

🎯 Detected Architecture: Clean Architecture
Confidence: 92%

📝 Configuration:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Creating .specify/memory/constitution.md
- Dependency rules (inward only)
- Entity independence
- Use case patterns

Creating .specify/config/architecture.json
- Architecture: "clean"
- Layers: [domain, application, infrastructure, presentation]
- Dependency direction: inward

✅ Setup Complete!

Next Steps:
1. Review architectural constraints
2. Run: /triage "Add new use case"
3. Implement with strict layer separation
```

### Example 3: Fullstack (Manual Selection)

```bash
/start
```

**Prompt:**
```
🔍 Multiple architectures detected:
- Frontend: React in src/client/
- Backend: Node.js in src/server/

Please specify architectures:
```

**User selects:**
- Frontend: FSD
- Backend: Clean Architecture

**Output:**
```
📝 Multi-Architecture Configuration:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Frontend (src/client/):
- Architecture: FSD
- Layers: [app, pages, widgets, features, entities, shared]

Backend (src/server/):
- Architecture: Clean Architecture
- Layers: [domain, application, infrastructure, presentation]

Creating unified constitution...
✅ Multi-architecture setup complete!
```

## Implementation

### Architecture

The command uses:
- **architect-unified**: Architecture detection and validation
- **File system analysis**: Pattern matching for structure detection
- **Template engine**: Architecture-specific file generation

### Dependencies

**Required:**
- architect-unified agent
- Architecture templates in `.claude/architectures/`
- File system access

**Optional:**
- Git repository (for version tracking)
- Existing configuration files

### Workflow Steps

1. **Project Analysis**
   - Scan directory structure
   - Detect package manager (npm, yarn, pnpm)
   - Identify framework (React, Vue, Angular, etc.)
   - Analyze existing patterns

2. **Architecture Detection**
   - Match patterns to known architectures
   - Calculate confidence scores
   - Handle ambiguous cases
   - Support multi-architecture projects

3. **Configuration Generation**
   - Create constitution.md (project rules)
   - Generate architecture.json (structure config)
   - Set up workflow-gates.json (quality gates)
   - Initialize agent configurations

4. **Verification**
   - Validate configuration files
   - Check template availability
   - Ensure agent compatibility
   - Test quality gate definitions

### Related Resources

- **Templates**: `.claude/architectures/*/`
- **Constitution**: `.specify/memory/constitution.md`
- **Config**: `.specify/config/architecture.json`
- **Gates**: `.claude/workflow-gates.json`
- **Agents**: architect-unified, reviewer-unified

## 실행 순서

### 1. 프로젝트 분석

```
📊 Analyzing project...
└── package.json 확인
└── 디렉토리 구조 스캔
└── 프레임워크 감지
└── 기존 패턴 분석
```

### 2. 아키텍처 감지

**자동 감지 패턴**:
- **FSD**: app/, pages/, widgets/, features/, entities/, shared/
- **Clean**: domain/, application/, infrastructure/, presentation/
- **Hexagonal**: core/, adapters/, ports/
- **DDD**: domain/, application/, infrastructure/
- **Atomic**: atoms/, molecules/, organisms/, templates/, pages/

### 3. 설정 파일 생성

**Constitution (`.specify/memory/constitution.md`)**:
```markdown
# Project Architecture: FSD

## Layer Rules
- app: Application initialization only
- pages: Route-level composition
- widgets: Large UI blocks
- features: User-facing features
- entities: Business entities
- shared: Reusable utilities

## Import Constraints
✓ Lower layers → Upper layers
✗ Upper layers → Lower layers
```

**Architecture Config (`.specify/config/architecture.json`)**:
```json
{
  "architecture": "fsd",
  "layers": ["app", "pages", "widgets", "features", "entities", "shared"],
  "validation": {
    "enabled": true,
    "strictMode": true
  }
}
```

### 4. 검증

```
✓ Constitution created
✓ Architecture config valid
✓ Workflow gates configured
✓ Agents initialized
```

## 구조

### FSD (Feature-Sliced Design)

```
src/
├── app/              # 앱 초기화, 라우터
├── pages/            # 페이지 레벨 컴포넌트
├── widgets/          # 복합 UI 블록
├── features/         # 사용자 기능
├── entities/         # 비즈니스 엔티티
└── shared/           # 공유 유틸리티
    ├── ui/           # UI 컴포넌트
    ├── lib/          # 헬퍼 함수
    ├── api/          # API 클라이언트
    └── config/       # 설정
```

### Clean Architecture

```
src/
├── domain/           # 비즈니스 로직 (순수)
│   ├── entities/     # 핵심 엔티티
│   └── usecases/     # 비즈니스 규칙
├── application/      # 애플리케이션 로직
│   ├── services/     # 서비스
│   └── dtos/         # 데이터 전송 객체
├── infrastructure/   # 외부 의존성
│   ├── database/     # DB 구현
│   ├── api/          # 외부 API
│   └── config/       # 설정
└── presentation/     # UI/API 레이어
    ├── controllers/  # 컨트롤러
    └── routes/       # 라우트 정의
```

## 규칙

### FSD 규칙

**Layer 순서** (하위 → 상위):
1. shared: 어디서든 사용 가능
2. entities: shared만 import
3. features: entities, shared만 import
4. widgets: features, entities, shared만 import
5. pages: widgets, features, entities, shared만 import
6. app: 모든 레이어 import 가능

**금지 사항**:
- ✗ 상위 레이어 → 하위 레이어 import
- ✗ 같은 레벨 간 import (features A → features B)
- ✗ Public API 우회 (index.ts 무시)

### Clean Architecture 규칙

**의존성 방향**: 외부 → 내부만 허용
- ✓ infrastructure → application → domain
- ✗ domain → application (금지)
- ✗ domain → infrastructure (금지)

**Entity 규칙**:
- 외부 의존성 없음 (순수 TypeScript/JavaScript)
- 프레임워크 독립적
- DB 독립적

## 컴포넌트 생성

### FSD 컴포넌트

```bash
# Feature 생성 (자동으로 올바른 구조)
/major "Add user authentication feature"
→ features/auth/
  ├── ui/
  │   └── LoginForm.tsx
  ├── model/
  │   └── useAuth.ts
  ├── api/
  │   └── authApi.ts
  └── index.ts  # Public API
```

### Clean Architecture Entity

```bash
# Domain Entity 생성
/major "Add Order entity with validation"
→ domain/entities/
  └── Order.ts  # 순수 비즈니스 로직
→ domain/usecases/
  └── CreateOrder.ts  # Use case
→ application/dtos/
  └── OrderDto.ts  # 데이터 전송 객체
```

## 베스트 프랙티스

### 1. Public API 사용

**FSD**:
```typescript
// ✓ Good: Public API 사용
import { LoginForm } from 'features/auth'

// ✗ Bad: 내부 구조 직접 접근
import { LoginForm } from 'features/auth/ui/LoginForm'
```

### 2. 순수 Entity 유지

**Clean Architecture**:
```typescript
// ✓ Good: 순수 도메인 로직
export class User {
  constructor(
    private name: string,
    private email: string
  ) {}

  validate(): boolean {
    return this.email.includes('@')
  }
}

// ✗ Bad: 외부 의존성 포함
import { api } from 'infrastructure/api'
export class User {
  async save() {
    await api.post('/users', this)
  }
}
```

### 3. Layer 분리 준수

```typescript
// ✓ Good: 올바른 레이어 사용
// features/order/api/orderApi.ts
import { apiClient } from 'shared/api'

// ✗ Bad: 레이어 건너뛰기
// entities/order/api/orderApi.ts (entities는 API 호출 없음)
```

## 안티패턴

### 1. 순환 의존성

```typescript
// ✗ Bad: features A → features B → features A
// features/auth/model.ts
import { getUserProfile } from 'features/profile'

// features/profile/model.ts
import { logout } from 'features/auth'
```

**해결**: shared로 공통 로직 추출

### 2. God 컴포넌트

```typescript
// ✗ Bad: 너무 많은 책임
export const Dashboard = () => {
  // 인증, 데이터 페칭, UI, 라우팅 모두 포함
}
```

**해결**: features와 widgets로 분리

### 3. 의존성 역전 위반

```typescript
// ✗ Bad: domain → infrastructure
// domain/entities/User.ts
import { database } from 'infrastructure/database'
```

**해결**: Repository 패턴 사용 (Clean Architecture)

## 아키텍처 자동 감지

### 감지 로직

1. **디렉토리 패턴 매칭**
   - 각 아키텍처의 특징적 디렉토리 찾기
   - 신뢰도 점수 계산 (0-100%)

2. **파일 구조 분석**
   - index.ts 패턴 (FSD Public API)
   - useCase 패턴 (Clean Architecture)
   - Adapter 패턴 (Hexagonal)

3. **Import 패턴 분석**
   - 의존성 방향 확인
   - Layer 간 관계 파악

### 신뢰도 임계값

- **90%+**: 자동 적용
- **70-89%**: 확인 후 적용
- **<70%**: 사용자 선택 요청

## 다중 아키텍처 지원 (Fullstack)

### 설정 예시

```json
{
  "architectures": {
    "frontend": {
      "type": "fsd",
      "path": "src/client",
      "layers": ["app", "pages", "widgets", "features", "entities", "shared"]
    },
    "backend": {
      "type": "clean",
      "path": "src/server",
      "layers": ["domain", "application", "infrastructure", "presentation"]
    }
  }
}
```

### 검증

각 아키텍처별로 독립적 검증:
- Frontend: FSD 규칙 적용
- Backend: Clean Architecture 규칙 적용

## 에러 처리

### "Architecture not detected"

**원인**: 표준 구조가 아님
**해결**:
1. 수동으로 아키텍처 선택
2. 커스텀 템플릿 생성
3. 기존 구조를 표준으로 마이그레이션

### "Conflicting architectures"

**원인**: 여러 패턴 혼재
**해결**:
1. 가장 강한 패턴 선택
2. 다중 아키텍처로 설정
3. 리팩토링 계획 수립

### "Constitution generation failed"

**원인**: 템플릿 파일 누락
**해결**:
```bash
# 최신 템플릿 다운로드
curl -fsSL https://raw.githubusercontent.com/Liamns/claude-workflows/main/install.sh | bash --reinstall
```

## 고급 기능

### 커스텀 아키텍처

```bash
# 커스텀 템플릿 생성
.claude/architectures/custom-arch/
├── constitution.template.md
├── architecture.template.json
└── rules.json
```

### 점진적 마이그레이션

기존 코드베이스를 새 아키텍처로:
1. /start로 목표 아키텍처 설정
2. /review로 현재 구조 분석
3. /major로 단계적 마이그레이션 계획
4. 점진적으로 파일 이동/리팩토링

### 아키텍처 검증

```bash
# 정기적 검증
/review --architecture

# 출력:
# ✓ 95% FSD compliant
# ✗ 3 violations found:
#   - features/auth imports from features/profile
#   - widgets/header missing Public API
#   - entities/user has external dependency
```

## 문제 해결

### "여러 아키텍처가 감지되어요"

**원인**: Fullstack 프로젝트 또는 혼재된 패턴
**해결**:
- Frontend/Backend 분리 명시
- 주 아키텍처 선택
- 다중 설정 사용

### "Constitution이 프로젝트에 안 맞아요"

**원인**: 프로젝트 특성 미반영
**해결**:
- `.specify/memory/constitution.md` 수동 편집
- 프로젝트별 규칙 추가
- 검증 규칙 조정

### "기존 코드가 규칙을 위반해요"

**원인**: 레거시 코드
**해결**:
- 점진적 마이그레이션 계획
- 예외 규칙 추가 (임시)
- /review로 우선순위 파악

## 관련 명령어

```bash
# 초기 설정 후
/start

# 첫 작업 시작
/triage "Add login feature"

# 아키텍처 검증
/review --architecture

# 메트릭 확인
/dashboard
```

---

**Version**: 3.3.1
**Last Updated**: 2025-11-18
