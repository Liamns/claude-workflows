# /start - 프로젝트 초기화 및 Architecture 설정

프로젝트에 Specification-Driven Development 환경과 아키텍처를 설정합니다.

## 실행 순서

### Step 1: 프로젝트 타입 선택

"프로젝트 타입을 선택하세요:"
1. Frontend (React, Vue, Angular, Next.js...)
2. Backend (Node.js, Python, Java, Go...)
3. Fullstack (Frontend + Backend)
4. Mobile (React Native, Flutter, Ionic...)
5. Custom (직접 정의)

### Step 2: 아키텍처 패턴 선택

선택한 프로젝트 타입에 따라 적절한 아키텍처를 제안:

#### Frontend 선택 시:
"Frontend 아키텍처를 선택하세요:"
1. **FSD (Feature-Sliced Design)** - 레이어와 슬라이스 기반 [추천: 대규모 프로젝트]
2. **Atomic Design** - 원자부터 페이지까지 계층 구조 [추천: 컴포넌트 라이브러리]
3. **MVC/MVP/MVVM** - Model-View 분리 패턴 [추천: 엔터프라이즈]
4. **Micro Frontend** - 독립 배포 가능한 모듈 [추천: 대규모 팀]
5. **None** - 아키텍처 중립 (자유 구조)

#### Backend 선택 시:
"Backend 아키텍처를 선택하세요:"
1. **Clean Architecture** - 도메인 중심 설계 [추천: 복잡한 비즈니스 로직]
2. **Hexagonal (Ports & Adapters)** - 테스트 용이성 극대화 [추천: 다양한 외부 연동]
3. **DDD (Domain-Driven Design)** - 복잡한 도메인 모델링 [추천: 엔터프라이즈]
4. **Layered Architecture** - 전통적인 n-tier [추천: 간단한 CRUD]
5. **Serverless** - 함수 기반 아키텍처 [추천: 이벤트 기반]
6. **None** - 아키텍처 중립

#### Fullstack 선택 시:
"Fullstack 아키텍처를 선택하세요:"
1. **Monorepo** - 단일 저장소 다중 프로젝트 [추천: 코드 공유 필요]
2. **JAMstack** - JavaScript, APIs, Markup [추천: 정적 사이트]
3. **Microservices** - 분산 서비스 아키텍처 [추천: 대규모 시스템]
4. **Custom** - Frontend + Backend 개별 선택

### Step 3: .specify 디렉토리 구조 생성

```
.specify/
├── config/
│   ├── architecture.json        # 선택된 아키텍처 설정
│   └── architecture-rules.json  # 커스텀 규칙
├── memory/
│   └── constitution.md          # 프로젝트 거버넌스 규칙
├── scripts/
│   └── bash/
│       ├── common.sh
│       ├── create-new-feature.sh
│       └── check-prerequisites.sh
├── templates/
│   ├── spec-template.md
│   ├── plan-template.md
│   └── tasks-template.md
├── steering/
│   ├── product.md
│   ├── tech.md
│   └── structure.md
└── specs/
```

### Step 4: architecture.json 생성

선택에 따라 `.specify/config/architecture.json` 생성:

```json
{
  "projectType": "frontend|backend|fullstack|mobile",
  "architecture": {
    "primary": "fsd|clean|ddd|atomic|...",
    "secondary": null,  // fullstack의 경우
    "version": "1.0.0"
  },
  "config": {
    "strictness": "high|medium|low",
    "autoValidation": true,
    "customRules": []
  },
  "createdAt": "2025-01-07",
  "lastModified": "2025-01-07"
}
```

### Step 5: 아키텍처별 디렉토리 구조 생성

선택된 아키텍처에 따라 기본 디렉토리 구조 생성:

#### FSD 예시:
```bash
mkdir -p src/{app,pages,widgets,features,entities,shared}
```

#### Clean Architecture 예시:
```bash
mkdir -p src/{domain,application,infrastructure,presentation}
```

#### Atomic Design 예시:
```bash
mkdir -p src/components/{atoms,molecules,organisms,templates,pages}
```

### Step 6: Constitution 생성

아키텍처와 독립적으로 프로젝트 원칙을 설정:

#### 핵심 원칙 선택:
"프로젝트에 적용할 원칙을 선택하세요 (다중 선택):"
- [x] **Library-First** - 외부 라이브러리 우선 사용
- [x] **Test-First** - TDD (구현 전 테스트 작성)
- [x] **Architecture-First** - 아키텍처 규칙 엄격 준수
- [x] **Reusability-First** - 재사용성 우선 (Article X)
- [ ] **Performance-First** - 성능 최적화 우선
- [ ] **Security-First** - 보안 우선
- [ ] **Accessibility-First** - 접근성 우선
- [ ] **Mobile-First** - 모바일 우선

### Step 7: 아키텍처별 템플릿 설치

선택된 아키텍처의 템플릿을 복사:

```bash
# 예: FSD 선택 시
cp -r architectures/frontend/fsd/templates/* .specify/templates/architecture/

# 예: Clean Architecture 선택 시
cp -r architectures/backend/clean/templates/* .specify/templates/architecture/
```

### Step 8: workflow-gates.json 업데이트

아키텍처에 맞는 품질 게이트 활성화:

```json
{
  "activeArchitecture": "fsd|clean|ddd|...",
  "architectureGates": {
    // 아키텍처별 게이트 로드
  }
}
```

### Step 9: 아키텍처 가이드 생성

`.specify/docs/architecture-guide.md` 생성:

```markdown
# ${ARCHITECTURE_NAME} 가이드

## 구조
[선택된 아키텍처의 디렉토리 구조 설명]

## 규칙
[아키텍처별 핵심 규칙]

## 컴포넌트 생성
[컴포넌트/모듈 생성 방법]

## 베스트 프랙티스
[권장 패턴]

## 안티패턴
[피해야 할 패턴]
```

### Step 10: 완료 보고

```
✅ 프로젝트 초기화 완료!

📊 설정된 아키텍처:
- 프로젝트 타입: ${PROJECT_TYPE}
- 아키텍처: ${ARCHITECTURE_NAME}
- 엄격도: ${STRICTNESS}

📁 생성된 구조:
.specify/
├── config/
│   ├── architecture.json        ✅
│   └── architecture-rules.json  ✅
├── memory/constitution.md       ✅
├── templates/                   ✅
└── docs/architecture-guide.md   ✅

src/
└── [아키텍처별 디렉토리]       ✅

📋 다음 단계:
1. 새 기능 추가: /major [feature-name]
2. 컴포넌트 생성: "새 [아키텍처 용어] 만들어줘"
3. 아키텍처 검증: "아키텍처 규칙 검사해줘"

💡 Tips:
- 아키텍처 변경: /switch-architecture
- 규칙 조정: .specify/config/architecture-rules.json 편집
- 마이그레이션: /migrate-architecture [from] [to]
```

## 아키텍처 자동 감지

`.specify/config/architecture.json`이 없는 경우:

1. **디렉토리 구조 분석**:
```typescript
function detectArchitecture(): string {
  const patterns = {
    'fsd': ['src/entities', 'src/features', 'src/widgets'],
    'atomic': ['components/atoms', 'components/molecules'],
    'clean': ['domain/', 'application/', 'infrastructure/'],
    'hexagonal': ['core/ports', 'adapters/'],
    'ddd': ['boundedContexts/', 'domain/aggregates'],
    'mvc': ['models/', 'views/', 'controllers/']
  };

  // 패턴 매칭으로 아키텍처 추론
  return matchPatterns(patterns);
}
```

2. **package.json 분석**:
- 의존성에서 힌트 찾기 (예: atomic-design, clean-architecture 패키지)

3. **사용자 확인**:
"감지된 아키텍처: ${DETECTED}. 맞습니까? (y/n)"

## 다중 아키텍처 지원 (Fullstack)

Fullstack 프로젝트의 경우 Frontend/Backend 개별 설정:

```json
{
  "projectType": "fullstack",
  "architecture": {
    "frontend": {
      "type": "atomic",
      "path": "frontend/"
    },
    "backend": {
      "type": "clean",
      "path": "backend/"
    }
  }
}
```

## 에러 처리

- `.specify/` 이미 존재 → "기존 설정을 덮어쓰시겠습니까? (y/N)"
- 아키텍처 충돌 → "기존 구조와 충돌. 마이그레이션 하시겠습니까?"
- Git 저장소 아님 → "Git 저장소를 초기화하시겠습니까? (y/N)"