# 🏗️ Multi-Architecture Support Guide

Claude Workflows v2.0은 다양한 아키텍처 패턴을 지원하여 모든 프로젝트 타입에서 사용할 수 있습니다.

## 📚 목차

1. [개요](#개요)
2. [지원 아키텍처](#지원-아키텍처)
3. [시작하기](#시작하기)
4. [아키텍처별 가이드](#아키텍처별-가이드)
5. [마이그레이션](#마이그레이션)
6. [커스터마이징](#커스터마이징)

## 개요

### 왜 다중 아키텍처 지원이 필요한가?

- **범용성**: Frontend, Backend, Mobile, Fullstack 모든 프로젝트 지원
- **유연성**: 프로젝트 특성에 맞는 아키텍처 선택
- **학습 곡선**: 팀이 익숙한 패턴 사용 가능
- **마이그레이션**: 아키텍처 간 전환 지원

### 핵심 특징

- 🎯 **자동 감지**: 기존 프로젝트 구조 자동 인식
- 🔄 **손쉬운 전환**: 아키텍처 간 마이그레이션 도구
- 📏 **일관된 품질**: 아키텍처별 맞춤 검증 규칙
- 🛠️ **통합 도구**: 모든 아키텍처에서 동일한 워크플로우

## 지원 아키텍처

### Frontend (4종)

| 아키텍처 | 설명 | 추천 상황 |
|---------|------|----------|
| **FSD** | Feature-Sliced Design | 대규모 SPA, 복잡한 상태 관리 |
| **Atomic Design** | 원자-분자-유기체 계층 | 컴포넌트 라이브러리, 디자인 시스템 |
| **MVC/MVP/MVVM** | Model-View 분리 | 엔터프라이즈, 전통적 구조 |
| **Micro Frontend** | 독립 배포 모듈 | 대규모 팀, MSA 프론트엔드 |

### Backend (5종)

| 아키텍처 | 설명 | 추천 상황 |
|---------|------|----------|
| **Clean Architecture** | 도메인 중심 설계 | 복잡한 비즈니스 로직 |
| **Hexagonal** | Ports & Adapters | 다양한 외부 연동, 테스트 중심 |
| **DDD** | Domain-Driven Design | 복잡한 도메인, 엔터프라이즈 |
| **Layered** | 전통적 n-tier | 간단한 CRUD, 빠른 개발 |
| **Serverless** | 함수 기반 | 이벤트 드리븐, 스케일링 |

### Fullstack (3종)

| 아키텍처 | 설명 | 추천 상황 |
|---------|------|----------|
| **Monorepo** | 단일 저장소 | 코드 공유, 일관된 빌드 |
| **JAMstack** | JavaScript-API-Markup | 정적 사이트, 고성능 |
| **Microservices** | 분산 서비스 | 대규모 시스템, 독립 배포 |

## 시작하기

### 1. 프로젝트 초기화

```bash
/start
```

대화형 설정:
```
프로젝트 타입을 선택하세요:
1. Frontend ✨
2. Backend 🔧
3. Fullstack 🚀
4. Mobile 📱
5. Custom 🎨

> 1

Frontend 아키텍처를 선택하세요:
1. FSD (Feature-Sliced Design) [추천: 대규모]
2. Atomic Design [추천: 컴포넌트 라이브러리]
3. MVC/MVP/MVVM [추천: 엔터프라이즈]
4. Micro Frontend [추천: 대규모 팀]
5. None (아키텍처 중립)

> 2
```

### 2. 자동 감지

기존 프로젝트에서:
```bash
# 아키텍처 자동 감지
npx ts-node architectures/tools/detector.ts

🔍 Architecture Detection Results
📦 Project Type: frontend
🏗️ Detected Architecture: atomic
📊 Confidence: 85%
```

### 3. 설정 확인

```bash
cat .specify/config/architecture.json
```

```json
{
  "projectType": "frontend",
  "architecture": {
    "primary": "atomic",
    "version": "1.0.0"
  },
  "config": {
    "strictness": "high",
    "autoValidation": true
  }
}
```

## 아키텍처별 가이드

### Frontend: Atomic Design

#### 디렉토리 구조
```
src/components/
├── atoms/           # 기본 블록 (Button, Input)
│   └── Button/
│       ├── Button.tsx
│       ├── Button.styles.ts
│       ├── Button.test.tsx
│       └── index.ts
├── molecules/       # 원자 조합 (SearchBar, Card)
├── organisms/       # 복잡한 컴포넌트 (Header, Footer)
├── templates/       # 페이지 템플릿
└── pages/          # 실제 페이지
```

#### 컴포넌트 생성
```bash
"Button 원자 컴포넌트 만들어줘"
→ src/components/atoms/Button/ 생성

"SearchBar 분자 만들어줘"
→ src/components/molecules/SearchBar/ 생성
```

#### 검증 규칙
- ✅ 원자는 다른 컴포넌트 import 금지
- ✅ 계층 순서 준수 (하위만 import)
- ✅ 각 컴포넌트는 단일 책임

### Backend: Clean Architecture

#### 디렉토리 구조
```
src/
├── domain/          # 비즈니스 규칙 (순수)
│   ├── entities/
│   └── repositories/
├── application/     # 유스케이스
│   └── useCases/
├── infrastructure/  # 외부 의존성
│   ├── repositories/
│   └── services/
└── presentation/    # API 엔드포인트
    └── controllers/
```

#### 모듈 생성
```bash
"CreateOrder 유스케이스 만들어줘"
→ src/application/useCases/CreateOrderUseCase.ts

"Order 엔티티 만들어줘"
→ src/domain/entities/Order.ts
```

#### 검증 규칙
- ✅ 도메인 레이어 순수성 (외부 의존 없음)
- ✅ 의존성 역전 원칙
- ✅ 유스케이스당 하나의 비즈니스 규칙

### Fullstack: Monorepo

#### 디렉토리 구조
```
packages/
├── frontend/        # React 앱
│   └── (Atomic Design 적용)
├── backend/         # Node.js API
│   └── (Clean Architecture 적용)
├── shared/          # 공유 타입, 유틸
└── mobile/          # React Native
```

#### 워크스페이스 설정
```json
// package.json
{
  "workspaces": [
    "packages/*"
  ]
}
```

## 마이그레이션

### 아키텍처 변경

기존 MVC → FSD 마이그레이션:

```bash
npx ts-node architectures/tools/migrator.ts mvc fsd

📊 Migration Impact Analysis
Files to migrate: 152
Estimated time: 2-4 hours

⚠️ Breaking Changes:
- All import paths will change
- Component structure reorganization

🔄 Migration Plan: mvc → fsd
Step 1: Create backup
Step 2: Create FSD structure
Step 3: Move controllers → features
Step 4: Move models → entities
Step 5: Update imports
```

### 실행

```bash
# Dry run (기본)
npx ts-node architectures/tools/migrator.ts mvc fsd

# 실제 실행
npx ts-node architectures/tools/migrator.ts mvc fsd --execute
```

## 커스터마이징

### 1. 커스텀 아키텍처 추가

```json
// architectures/custom/my-pattern/config.json
{
  "name": "My Custom Pattern",
  "type": "frontend",
  "structure": {
    "directories": {
      "modules": "Feature modules",
      "core": "Core functionality",
      "shared": "Shared resources"
    }
  }
}
```

### 2. 검증 규칙 조정

```json
// .specify/config/architecture-rules.json
{
  "strictness": "medium",  // high, medium, low
  "customRules": [
    {
      "name": "no-circular-deps",
      "severity": "error",
      "pattern": "circular dependency detected"
    }
  ]
}
```

### 3. 워크플로우 게이트 커스터마이징

```json
// workflow-gates-v2.json
{
  "architectureProfiles": {
    "custom": {
      "myPattern": {
        "gates": {
          "customValidation": {
            "enabled": true,
            "required": true
          }
        }
      }
    }
  }
}
```

## 명령어 레퍼런스

### 아키텍처 관리

```bash
# 초기 설정
/start

# 아키텍처 변경
/switch-architecture

# 아키텍처 감지
npx ts-node architectures/tools/detector.ts

# 마이그레이션
/migrate-architecture [from] [to]
```

### 컴포넌트 생성

```bash
# 아키텍처별 자동 생성
"새 [컴포넌트타입] 만들어줘"

# 예시
"Button 원자 만들어줘"           # Atomic
"dispatch Feature 만들어줘"      # FSD
"CreateOrder 유스케이스 만들어줘"  # Clean
```

### 검증

```bash
# 아키텍처 규칙 검증
"아키텍처 규칙 검사해줘"

# 의존성 검증
"의존성 체크해줘"
```

## 베스트 프랙티스

### 1. 프로젝트 시작 시

1. `/start`로 아키텍처 설정
2. 기본 구조 생성
3. 팀 교육 및 가이드 공유

### 2. 개발 중

1. 컴포넌트 생성 시 자동 도구 사용
2. 정기적인 아키텍처 검증
3. PR 시 자동 검증 (workflow-gates)

### 3. 마이그레이션

1. 점진적 마이그레이션 권장
2. 기능 브랜치에서 테스트
3. 팀 합의 후 진행

## FAQ

### Q: 아키텍처 없이 사용할 수 있나요?
A: 네, "None" 선택으로 아키텍처 중립적 사용 가능합니다.

### Q: 여러 아키텍처를 혼용할 수 있나요?
A: Fullstack 프로젝트에서 Frontend/Backend 개별 설정 가능합니다.

### Q: 기존 프로젝트에 적용 가능한가요?
A: 자동 감지 기능으로 기존 구조를 인식하고 점진적 적용 가능합니다.

### Q: 커스텀 아키텍처를 추가할 수 있나요?
A: `architectures/custom/` 디렉토리에 설정 추가로 가능합니다.

## 지원

- Issues: [GitHub Issues](https://github.com/Liamns/claude-workflows/issues)
- Discussions: [GitHub Discussions](https://github.com/Liamns/claude-workflows/discussions)
- Documentation: [Architecture Docs](./architectures/README.md)