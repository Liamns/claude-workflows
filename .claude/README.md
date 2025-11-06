# 🤖 Claude Workflows for 배차킹

Claude Code를 통한 개발 효율성 극대화를 위한 워크플로우 시스템

## 🚀 Quick Start

### 작업 시작하기 (NEW!)

```bash
# 작업 복잡도를 자동으로 분석하여 최적 워크플로우 선택
/triage "작업 설명"

# 예시
/triage "타입 에러 수정"
→ Minor 워크플로우 자동 선택 (75% 토큰 절약)
```

### 수동 워크플로우 선택 (기존 방식)

```bash
# Major: 새 기능, API 설계 (4시간+)
/major

# Minor: 버그 수정, 개선 (30분-4시간)
/minor

# Micro: 오타, 스타일 수정 (30분 미만)
/micro
```

## 📊 워크플로우 비교

| 워크플로우 | 용도 | 토큰 절약 | 품질 수준 | 예상 시간 |
|-----------|------|---------|----------|----------|
| **Major** | 새 기능, 아키텍처 | 60% | 최상 (TDD, 80%+ 커버리지) | 4시간+ |
| **Minor** | 버그 수정, 개선 | 75% | 상 (타입체크, 관련 테스트) | 30분-4시간 |
| **Micro** | 오타, 로그 제거 | 85% | 표준 (문법 검사) | 30분 미만 |

## 🎯 /triage 명령어 (NEW!)

작업을 자동으로 분류하여 적절한 워크플로우를 선택합니다.

### 작동 원리

1. **패턴 분석**: 작업 설명에서 키워드 추출
2. **복잡도 계산**: 점수 기반 분류
3. **추가 질문**: 필요시 구체적 정보 요청
4. **워크플로우 결정**: Major/Minor/Micro 자동 선택

### 사용 예시

```bash
# 간단한 버그
/triage "null 참조 에러 수정"
→ Minor 선택, quick-fixer 자동 실행

# 새 기능
/triage "주문 API 연동 및 폼 검증 추가"
→ Major 선택, spec-kit 프로세스 시작

# 애매한 경우
/triage "성능 개선"
→ 추가 질문 후 적절한 워크플로우 선택
```

## 🤖 Sub-Agents (7개)

### 개발 지원
- **quick-fixer**: 버그 수정 전문가 (Minor 전용)
- **api-designer**: API 계약 설계 (Major 전용)
- **test-guardian**: TDD 강제 집행관 (Major 전용)

### 아키텍처
- **fsd-architect**: FSD 규칙 검증
- **code-reviewer**: 보안/성능/품질 검토

### 자동화
- **changelog-writer**: Git → Notion 문서화
- **mobile-specialist**: Capacitor 빌드 자동화

## 🛠 Skills (7개)

자동으로 활성화되는 작업 패턴:

- **bug-fix-pattern**: 타입 에러, null check 자동 수정
- **api-integration**: httpClient + React Query 패턴
- **form-validation**: React Hook Form + Zod 검증
- **fsd-component-creation**: FSD 컴포넌트 생성
- **platform-detection**: 플랫폼별 조건부 렌더링
- **mobile-build**: Android/iOS 빌드 자동화
- **daily-changelog-notion**: 변경사항 Notion 문서화

## 📁 프로젝트 구조

```
.claude/
├── commands/        # 워크플로우 명령어
│   ├── triage.md   # 🆕 자동 워크플로우 선택
│   ├── major.md
│   ├── minor.md
│   └── micro.md
├── agents/         # Sub-agents
├── skills/         # 자동화 패턴
├── docs/           # 상세 문서
│   ├── SUB-AGENTS-GUIDE.md
│   ├── SKILLS-GUIDE.md
│   └── IMPROVEMENT-PROPOSALS.md
└── workflow-gates.json  # 품질 게이트 설정
```

## 📈 효과

- **토큰 절약**: 60-85% 감소
- **개발 속도**: 2.5배 향상
- **품질 보장**: 자동화된 검증
- **일관성**: 표준화된 프로세스

## 🔧 커스터마이징

### FSD 검증 비활성화
```json
// workflow-gates.json
"fsd-validation": false
```

### Notion 연동 제거
```bash
rm -rf .claude/skills/daily-changelog-notion
rm .claude/agents/changelog-writer.md
```

### 품질 게이트 조정
```json
// workflow-gates.json
"major": {
  "test-coverage": 60  // 80에서 60으로 낮춤
}
```

## 📚 상세 가이드

- [Sub-agents 상세 가이드](./docs/SUB-AGENTS-GUIDE.md)
- [Skills 상세 가이드](./docs/SKILLS-GUIDE.md)
- [개선 제안서](./docs/IMPROVEMENT-PROPOSALS.md)

## 💡 Tips

1. **작업 시작 전 `/triage` 사용**: 최적 워크플로우 자동 선택
2. **병렬 실행 활용**: 독립적인 작업은 동시 실행
3. **캐싱 활용**: 반복 작업 시 자동 캐싱
4. **점진적 접근**: Micro → Minor → Major 순으로 확대

## 🆘 문제 해결

### "워크플로우를 잘못 선택했어요"
```bash
# triage로 다시 분석
/triage "실제 작업 내용"
```

### "토큰이 너무 많이 사용됩니다"
```bash
# Micro 워크플로우로 전환
/micro
```

### "테스트가 실패합니다"
```bash
# quick-fixer 활성화
Task(quick-fixer, "테스트 실패 수정")
```

---

**Version**: 1.0.0
**Last Updated**: 2025-01-06
**License**: MIT