# 프로젝트 문서 경로 표준 (Document Path Standards)

## 공식 경로 정책

### 핵심 원칙
1. **단일 진실 공급원(Single Source of Truth)**: 동일한 내용의 문서를 여러 곳에 만들지 않습니다
2. **명확한 소유권**: 각 문서는 명확한 디렉토리에 속합니다
3. **일관된 명명**: 파일명과 경로는 예측 가능해야 합니다

---

## 디렉토리 구조

### `.specify/` - 프로젝트 전체 사양 및 메모리
**용도:** 프로젝트 레벨의 설정, 헌장, 사양 문서

```
.specify/
├── memory/
│   ├── constitution.md          # 프로젝트 헌장 (공식 경로)
│   └── project-memory.md        # 프로젝트 컨텍스트 메모리
└── templates/
    ├── spec-template.md         # 사양 템플릿
    ├── plan-template.md         # 계획 템플릿
    └── tasks-template.md        # 작업 템플릿
```

**중요:**
- `constitution.md`는 **반드시** `.specify/memory/` 에만 존재해야 합니다
- 다른 위치에 constitution 파일을 만들지 마세요

---

### `.claude/` - Claude Code 워크플로우 설정
**용도:** Claude Code 실행 관련 설정, 에이전트, 스킬, 커맨드

```
.claude/
├── config/
│   ├── user-preferences.yaml    # 사용자 설정 (언어 설정 포함)
│   └── model-router.yaml        # 모델 라우팅 설정
├── agents/
│   ├── code-reviewer.md
│   ├── quick-fixer.md
│   └── ...
├── commands/
│   ├── commit.md
│   ├── review.md
│   └── ...
├── skills/
│   └── {skill-name}/
│       └── SKILL.md
└── docs/
    ├── SKILLS-GUIDE.md
    ├── SUB-AGENTS-GUIDE.md
    └── REUSABILITY-GUIDE.md
```

---

### 루트 레벨 문서

```
/
├── README.md                    # 프로젝트 소개 (한글)
├── CHANGELOG.md                 # 변경 이력 (한글)
├── ARCHITECTURE.md              # 아키텍처 설명 (한글)
└── EXAMPLES.md                  # 사용 예제 (한글)
```

---

## 문서별 경로 매핑

| 문서 유형 | 공식 경로 | 금지 경로 |
|----------|---------|----------|
| Constitution | `.specify/memory/constitution.md` | `.claude/constitution.md` |
| User Preferences | `.claude/config/user-preferences.yaml` | `.specify/config/` |
| Project Memory | `.specify/memory/project-memory.md` | `.claude/memory/` |
| Agents | `.claude/agents/{name}.md` | `.specify/agents/` |
| Commands | `.claude/commands/{name}.md` | `.specify/commands/` |
| Skills | `.claude/skills/{name}/SKILL.md` | `.specify/skills/` |

---

## 참조 시 주의사항

### Constitution 참조 방법
```bash
# 올바른 경로
.specify/memory/constitution.md

# 잘못된 경로 (절대 사용 금지)
.claude/constitution.md
constitution.md
```

### 새 문서 생성 시 체크리스트
- [ ] 이미 동일한 내용의 문서가 다른 곳에 존재하는가?
- [ ] 이 문서의 소유권이 명확한가? (`.specify` vs `.claude`)
- [ ] 파일명이 프로젝트 표준을 따르는가?
- [ ] 해당 디렉토리의 목적에 부합하는가?

---

## 마이그레이션 가이드

### 잘못된 위치에 문서가 생성된 경우

1. **확인**: 올바른 경로 확인
2. **이동**: `mv` 명령어로 올바른 위치로 이동
3. **검증**: 참조하는 다른 파일이 있는지 확인 및 수정
4. **삭제**: 잘못된 위치의 파일 삭제

```bash
# 예시: constitution.md가 잘못된 위치에 있는 경우
mv .claude/constitution.md .specify/memory/constitution.md
```

---

**마지막 업데이트:** 2025-11-07
**버전:** 1.0.0
