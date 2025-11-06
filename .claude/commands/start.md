# /start - 프로젝트 초기화 및 Constitution 설정

프로젝트에 Specification-Driven Development 환경을 초기화합니다.

## 실행 순서

### 1단계: .specify 디렉토리 구조 생성

프로젝트 루트에 다음 구조를 생성합니다:

```
.specify/
├── memory/
│   └── constitution.md          # 프로젝트 거버넌스 규칙 (9개 Article)
├── scripts/
│   └── bash/
│       ├── common.sh            # 공통 유틸리티 함수
│       ├── create-new-feature.sh # 자동 브랜치 생성 및 번호 부여
│       └── check-prerequisites.sh # 파일 유효성 검증
├── templates/
│   ├── spec-template.md         # WHAT/WHY만 포함 (HOW 제외)
│   ├── plan-template.md         # Phase 0+1, Constitution 체크
│   └── tasks-template.md        # [T001] [P?] [Story?] 형식
├── steering/                    # 선택사항
│   ├── product.md               # 제품 컨텍스트 (60-80% 토큰 절감)
│   ├── tech.md                  # 기술 스택 및 아키텍처
│   └── structure.md             # 프로젝트 구조 설명
└── specs/                       # 기능별 spec 저장소 (명령 실행 시 자동 생성)
    └── 001-feature-name/
        ├── spec.md
        ├── plan.md
        ├── tasks.md
        ├── research.md
        ├── data-model.md
        ├── contracts/
        │   └── openapi.yaml
        ├── quickstart.md
        └── checklists/
            └── requirements.md
```

**실행**:
```bash
mkdir -p .specify/{memory,scripts/bash,templates,steering,specs}
```

### 2단계: Constitution 생성

사용자에게 다음 질문을 통해 Constitution을 생성합니다:

#### Q1: 프로젝트 타입
"이 프로젝트는 어떤 유형인가요?"
- Web Application
- Mobile App (iOS/Android)
- API/Backend Service
- Library/Package
- Desktop Application
- Full-stack (Multiple projects)

#### Q2: 핵심 원칙 선택 (다중 선택 가능)
"프로젝트에 적용할 핵심 개발 원칙을 선택하세요:"
- [x] Library-First (외부 라이브러리 우선 사용)
- [x] Test-First (구현 전 테스트 작성)
- [x] Anti-Abstraction (과도한 추상화 금지)
- [x] Integration-First Testing (통합 테스트 우선)
- [ ] Contract-First (API 계약 우선 설계)
- [ ] Mobile-First (모바일 우선 설계)
- [ ] Accessibility-First (접근성 우선)

#### Q3: 기술 스택 제약사항
"반드시 지켜야 할 기술 스택이 있나요? (있으면 입력, 없으면 Enter)"
예시: "React 19, TypeScript, FSD 아키텍처"

#### Q4: 프로젝트 복잡도
"초기 프로젝트 복잡도는?"
- Simple (단일 프로젝트, ≤3 주요 모듈)
- Moderate (2-3 프로젝트, 통합 필요)
- Complex (다중 프로젝트, 복잡한 의존성)

### 3단계: Constitution 파일 생성

답변을 기반으로 `.specify/memory/constitution.md` 파일을 생성합니다.

**템플릿 구조**:
```markdown
# Constitution

## Metadata
- Version: 1.0.0
- Created: {YYYY-MM-DD}
- Last Amended: {YYYY-MM-DD}
- Status: Active

## Preamble
{프로젝트 타입 및 목적 설명}

## Article I: Library-First Principle
{enabled/disabled 및 근거}

## Article II: External Configuration
{설정 파일 외부화 규칙}

## Article III: Test-First Imperative
{TDD 적용 규칙}

## Article IV: Repository Structure
{Git 저장소 구조}

## Article V: Issue Tracking
{이슈 트래킹 시스템}

## Article VI: Deployment
{배포 전략}

## Article VII: Simplicity
{복잡도 제한: ≤3 projects initially}

## Article VIII: Anti-Abstraction
{과도한 추상화 금지}

## Article IX: Integration-First Testing
{통합 테스트 우선 전략}

## Amendment Procedure
{Constitution 수정 절차}
```

### 4단계: 템플릿 파일 생성

**spec-template.md** (`.specify/templates/spec-template.md`):
- WHAT/WHY만 포함 (HOW 제외)
- User Scenarios & Testing 중심
- 우선순위별 분류 ([P1], [P2], [P3+])
- Story 단위 구분 ([US1], [US2], ...)

**plan-template.md** (`.specify/templates/plan-template.md`):
- Technical Foundation 섹션
- Constitution Check 테이블
- Phase 0: Research
- Phase 1: Design Artifacts
- Source Code Structure

**tasks-template.md** (`.specify/templates/tasks-template.md`):
- Task Format: `[T001] [P?] [Story?] Description /absolute/path`
- Phase별 그룹핑
- Test-First 강제 (Tests → Implementation 순서)

### 5단계: Steering Documents 생성 (선택사항)

사용자에게 물어봅니다:
"Steering Documents를 생성하여 AI 컨텍스트를 최적화하시겠습니까? (60-80% 토큰 절감)"
- Yes → product.md, tech.md, structure.md 생성
- No → 건너뛰기

**Steering Documents 내용**:
- `product.md`: 제품 비전, 타겟 사용자, 핵심 기능
- `tech.md`: 기술 스택, 아키텍처 패턴, 의존성
- `structure.md`: 디렉토리 구조, 모듈 관계도

### 6단계: Bash 스크립트 생성

**common.sh** (공통 유틸리티):
```bash
#!/bin/bash

# Get next feature number
get_next_feature_number() {
    local max_num=0
    if [ -d ".specify/specs" ]; then
        for dir in .specify/specs/*/; do
            num=$(basename "$dir" | grep -oE '^[0-9]+')
            if [ "$num" -gt "$max_num" ]; then
                max_num=$num
            fi
        done
    fi
    printf "%03d" $((max_num + 1))
}

# Validate spec file
validate_spec() {
    local spec_file="$1"
    # Check required sections
    grep -q "## Overview" "$spec_file" || return 1
    grep -q "## User Scenarios & Testing" "$spec_file" || return 1
    grep -q "## Success Criteria" "$spec_file" || return 1
    return 0
}
```

**create-new-feature.sh** (자동 브랜치 생성):
```bash
#!/bin/bash
source "$(dirname "$0")/common.sh"

FEATURE_NAME="$1"
FEATURE_NUM=$(get_next_feature_number)
BRANCH_NAME="${FEATURE_NUM}-${FEATURE_NAME}"

# Create spec directory
mkdir -p ".specify/specs/$BRANCH_NAME"/{contracts,checklists}

# Copy templates
cp .specify/templates/spec-template.md ".specify/specs/$BRANCH_NAME/spec.md"
cp .specify/templates/plan-template.md ".specify/specs/$BRANCH_NAME/plan.md"
cp .specify/templates/tasks-template.md ".specify/specs/$BRANCH_NAME/tasks.md"

# Create git branch
git checkout -b "$BRANCH_NAME"

echo "Created feature: $BRANCH_NAME"
echo "Spec directory: .specify/specs/$BRANCH_NAME"
```

**check-prerequisites.sh** (파일 검증):
```bash
#!/bin/bash
source "$(dirname "$0")/common.sh"

SPEC_DIR="$1"

# Check required files
[ -f "$SPEC_DIR/spec.md" ] || { echo "spec.md missing"; exit 1; }
[ -f "$SPEC_DIR/plan.md" ] || { echo "plan.md missing"; exit 1; }
[ -f "$SPEC_DIR/tasks.md" ] || { echo "tasks.md missing"; exit 1; }

# Validate spec
validate_spec "$SPEC_DIR/spec.md" || { echo "spec.md invalid"; exit 1; }

echo "All prerequisites met"
```

### 7단계: Git 초기화 (필요시)

프로젝트가 Git 저장소가 아닌 경우:
```bash
git init
echo ".specify/specs/*/research.md" >> .gitignore
echo ".specify/specs/*/data-model.md" >> .gitignore
```

### 8단계: 완료 보고

사용자에게 다음을 보고합니다:

```
✅ 프로젝트 초기화 완료!

📁 생성된 구조:
.specify/
├── memory/constitution.md       ✅
├── templates/                   ✅
│   ├── spec-template.md
│   ├── plan-template.md
│   └── tasks-template.md
├── scripts/bash/                ✅
│   ├── common.sh
│   ├── create-new-feature.sh
│   └── check-prerequisites.sh
├── steering/                    {선택사항 여부}
│   ├── product.md
│   ├── tech.md
│   └── structure.md
└── specs/                       (빈 디렉토리)

📋 다음 단계:
1. 새 기능 추가: /major [feature-name]
2. 기존 기능 수정: /minor [feature-number]
3. 버그 수정: /micro [description]

💡 Tip: Steering Documents를 생성하면 AI 응답 속도가 빨라집니다 (60-80% 토큰 절감)
```

## 실행 조건

- 프로젝트 루트 디렉토리에서 실행
- `.specify/` 디렉토리가 없어야 함 (이미 있으면 경고 후 덮어쓰기 여부 확인)

## 에러 처리

- `.specify/` 이미 존재 → "기존 설정을 덮어쓰시겠습니까? (y/N)"
- Git 저장소 아님 → "Git 저장소를 초기화하시겠습니까? (y/N)"
- 파일 생성 실패 → 권한 확인 및 재시도 안내
