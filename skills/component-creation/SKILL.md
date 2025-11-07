---
name: component-creation
description: 프로젝트의 아키텍처 패턴에 맞는 컴포넌트를 자동 생성합니다. 설정된 아키텍처(FSD, Atomic, Clean, DDD 등)의 규칙과 템플릿에 따라 적절한 위치에 컴포넌트를 생성하고 타입 안전성을 검증합니다.
allowed-tools: Read, Write, Grep, Glob, Bash(yarn type-check), mcp__context7*
context7_enabled: conditional
context7_conditions:
  - new_component: true
  - architecture: "fsd|atomic"
context7_loading:
  max_tokens: 1000
  scope:
    - "entities/*/ui/*.tsx"
    - "features/*/ui/*.tsx"
    - "shared/ui/*.tsx"
    - "components/**/*.tsx"
  filters:
    - "component templates"
    - "props patterns"
    - "styling patterns"
---

# Component Creation Skill (Architecture-Agnostic)

프로젝트에 설정된 아키텍처 패턴에 따라 컴포넌트를 자동 생성합니다.

## Context7 통합

### 자동 활성화 조건
```yaml
Context7 활성화:
  - 새 컴포넌트 생성 요청
  - FSD 또는 Atomic Design 아키텍처
  - 템플릿 검색 필요
```

### Context7 로딩 전략
```yaml
🔍 Context7 로딩 (최대 1000 토큰):
  ├─ 컴포넌트 템플릿 (400 토큰)
  │  └─ entities/*/ui/*.tsx
  │  └─ shared/ui/*.tsx
  ├─ Props 패턴 (300 토큰)
  │  └─ 타입 정의 및 인터페이스
  └─ 스타일링 패턴 (300 토큰)
     └─ CSS-in-JS 또는 Tailwind
```

### 활용 예시
```
사용자: "Button 컴포넌트 만들어줘"

🔍 Context7 활성화: 유사 컴포넌트 템플릿 검색 중...
✅ 발견: shared/ui/BaseButton 템플릿
✅ Props 패턴: variant, size, disabled 표준 props
💡 제안: BaseButton 확장하여 생성
```

## 실행 조건

다음 요청 시 자동으로 실행됩니다:
- "새 컴포넌트 생성"
- "컴포넌트 추가"
- "[아키텍처별 용어] 만들어줘"
- Major 워크플로우에서 신규 기능 추가

## 아키텍처 감지

### Step 1: 프로젝트 아키텍처 확인

```bash
# .specify/config/architecture.json 확인
cat .specify/config/architecture.json
```

아키텍처가 설정되지 않은 경우:
1. 디렉토리 구조 분석으로 자동 감지
2. 사용자에게 확인 요청
3. 기본값: 아키텍처 중립적 생성

## 아키텍처별 생성 패턴

### Frontend Architectures

#### FSD (Feature-Sliced Design)
```
src/
├── entities/[name]/
│   ├── ui/
│   ├── model/
│   └── index.ts
├── features/[name]/
├── widgets/[name]/
└── pages/[name]/
```

#### Atomic Design
```
src/components/
├── atoms/[Name]/
│   ├── [Name].tsx
│   ├── [Name].styles.ts
│   └── index.ts
├── molecules/[Name]/
├── organisms/[Name]/
└── templates/[Name]/
```

#### MVC/MVP/MVVM
```
src/
├── models/[Name]Model.ts
├── views/[Name]View.tsx
├── controllers/[Name]Controller.ts
└── presenters/[Name]Presenter.ts
```

### Backend Architectures

#### Clean Architecture
```
src/
├── domain/entities/[Name].ts
├── application/useCases/[Name]UseCase.ts
├── infrastructure/repositories/[Name]Repository.ts
└── presentation/controllers/[Name]Controller.ts
```

#### Hexagonal
```
src/
├── core/domain/[Name].ts
├── core/ports/I[Name]Port.ts
├── adapters/inbound/[Name]Controller.ts
└── adapters/outbound/[Name]Repository.ts
```

#### DDD
```
src/boundedContexts/[context]/
├── domain/
│   ├── aggregates/[Name]Aggregate.ts
│   ├── valueObjects/[Name].ts
│   └── events/[Name]Event.ts
└── application/[Name]Service.ts
```

## 생성 프로세스

### Step 1: 컴포넌트 타입 결정

사용자 요청 분석:
- 아키텍처별 키워드 매칭
- 컨텍스트 기반 추론
- 불확실한 경우 사용자 확인

### Step 2: 위치 결정

```typescript
const location = architectureAdapter.suggestLocation(
  componentType,
  componentName
);
```

### Step 3: 템플릿 로드

```typescript
const template = await loadTemplate(
  architecture,
  componentType
);
```

### Step 4: 파일 생성

```typescript
const files = architectureAdapter.generateComponent(
  type,
  name,
  options
);
```

### Step 5: 검증

```typescript
// 구조 검증
const validation = await architectureAdapter.validateStructure(files);

// 타입 검증
await bash('yarn type-check');

// 의존성 검증
const depsValid = architectureAdapter.checkDependencies(from, to);
```

## 품질 검증

### 공통 규칙
- 네이밍 컨벤션 준수
- 타입 안전성 확보
- 테스트 파일 생성
- 문서화 주석 포함

### 아키텍처별 규칙
- 각 아키텍처의 config.json에 정의된 규칙 적용
- 의존성 방향 검증
- 레이어/계층 규칙 준수

## 에러 처리

### 아키텍처 미설정
```
⚠️ 아키텍처가 설정되지 않았습니다.
실행: /start 명령으로 아키텍처를 선택하세요.
```

### 잘못된 의존성
```
❌ 의존성 규칙 위반
[하위 레이어]는 [상위 레이어]를 참조할 수 없습니다.
```

### 중복 컴포넌트
```
⚠️ 동일한 이름의 컴포넌트가 이미 존재합니다.
기존: [경로]
덮어쓰시겠습니까? (y/n)
```

## 사용 예시

### Frontend 예시
```bash
# FSD 아키텍처
"운송 신청 폼 Feature 만들어줘"
→ src/features/dispatch-form/

# Atomic Design
"Button 컴포넌트 만들어줘"
→ src/components/atoms/Button/

# MVC
"User 모델과 컨트롤러 만들어줘"
→ src/models/UserModel.ts
→ src/controllers/UserController.ts
```

### Backend 예시
```bash
# Clean Architecture
"CreateOrder 유스케이스 만들어줘"
→ src/application/useCases/CreateOrderUseCase.ts

# DDD
"Payment 애그리게이트 만들어줘"
→ src/domain/aggregates/PaymentAggregate.ts

# Hexagonal
"UserRepository 어댑터 만들어줘"
→ src/adapters/outbound/UserRepository.ts
```

## 아키텍처 마이그레이션 지원

기존 컴포넌트를 다른 아키텍처로 변환:
1. 현재 아키텍처 분석
2. 대상 아키텍처 매핑
3. 구조 변환
4. 의존성 재구성
5. 테스트 업데이트