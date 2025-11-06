---
name: reusability-metrics
description: 코드 재사용성 메트릭을 측정하고 추적합니다. 중복 코드를 감지하고, 재사용률을 계산하며, 개선 기회를 제안합니다.
allowed-tools: [Read, Grep, Glob, Bash(wc*)]
activation: |
  - 코드 리뷰 시
  - 워크플로우 완료 후
  - 주간/월간 리포트 생성 시
  - "재사용률 확인" 요청 시
---

# Reusability Metrics Skill

## 핵심 목표
코드 재사용성을 정량적으로 측정하고 지속적으로 개선하기 위한 메트릭 추적 시스템

## 측정 메트릭

### 1. 재사용률 (Reusability Rate)
```typescript
interface ReusabilityMetrics {
  totalModules: number;          // 전체 모듈 수
  reusedModules: number;         // 재사용된 모듈 수
  reusabilityRate: number;       // (reusedModules / totalModules) * 100
  targetRate: 60;                // 목표: 60% 이상
}
```

### 2. 중복 코드 비율 (Duplication Rate)
```typescript
interface DuplicationMetrics {
  totalLines: number;             // 전체 코드 라인 수
  duplicatedLines: number;        // 중복된 라인 수
  duplicationRate: number;        // (duplicatedLines / totalLines) * 100
  targetRate: 5;                  // 목표: 5% 이하
}
```

### 3. 공유 컴포넌트 사용률 (Shared Component Usage)
```typescript
interface SharedUsageMetrics {
  sharedComponentsTotal: number;   // 전체 shared 컴포넌트 수
  sharedComponentsUsed: number;    // 사용된 shared 컴포넌트 수
  averageUsagePerFeature: number;  // feature당 평균 사용
  targetPerFeature: 10;             // 목표: feature당 10개 이상
}
```

## 측정 프로세스

### 1. 중복 코드 감지

#### 1.1 완전 중복 감지 (10줄 이상)
```bash
# 중복 함수 감지
grep -rh "function\|const.*=.*(" src/ | sort | uniq -d

# 중복 컴포넌트 구조 감지
find src -name "*.tsx" -exec md5sum {} \; | sort | uniq -d -w 32

# 유사 코드 블록 감지 (AST 기반 - 가상)
# 실제로는 jscpd 같은 도구 사용 권장
```

#### 1.2 패턴 중복 감지
```bash
# 유사한 import 패턴
grep -r "^import.*from" src/ | sort | uniq -c | sort -rn | head -20

# 유사한 useState 패턴
grep -r "useState<.*>" src/ | sort | uniq -c | sort -rn

# 유사한 useEffect 패턴
grep -r "useEffect.*{$" src/ -A 5 | sort | uniq -c
```

### 2. 재사용 모듈 사용률 측정

#### 2.1 Shared 컴포넌트 사용 횟수
```bash
# 각 shared 컴포넌트의 import 횟수 계산
for component in src/shared/ui/*; do
  name=$(basename $component)
  count=$(grep -r "from.*shared/ui/$name" src/ --exclude-dir=shared | wc -l)
  echo "$name: $count times"
done
```

#### 2.2 유틸리티 함수 사용률
```bash
# shared/lib 함수들의 사용 횟수
for util in src/shared/lib/*/*.ts; do
  funcname=$(basename $util .ts)
  count=$(grep -r "import.*$funcname" src/ | wc -l)
  echo "$funcname: $count imports"
done
```

### 3. 메트릭 계산

```typescript
function calculateMetrics(): MetricsReport {
  const report = {
    timestamp: new Date().toISOString(),
    reusability: {
      rate: 0,
      trend: 'improving', // improving | stable | declining
      details: {}
    },
    duplication: {
      rate: 0,
      hotspots: [], // 중복이 많은 파일들
      suggestions: []
    },
    sharedUsage: {
      topUsed: [],    // 가장 많이 사용되는 컴포넌트
      unused: [],     // 사용되지 않는 컴포넌트
      underused: []   // 사용률이 낮은 컴포넌트
    }
  };

  // 계산 로직...

  return report;
}
```

## 리포트 생성

### 1. 즉시 피드백 (실시간)
```markdown
## 🔍 재사용성 체크 결과

✅ **재사용 성공**
- `Button` 컴포넌트 재사용 (3회째 사용)
- `formatDate` 유틸리티 재사용 (15회째 사용)

⚠️ **중복 감지**
- `OrderForm`과 70% 유사한 코드 발견
- 제안: 공통 부분을 `BaseForm`으로 추출

📊 **현재 메트릭**
- 재사용률: 62% ✅ (목표: 60%)
- 중복률: 4.2% ✅ (목표: <5%)
- Shared 사용: 12개/feature ✅ (목표: 10+)
```

### 2. 주간 리포트
```markdown
# 📈 주간 재사용성 리포트

**기간**: 2025-01-06 ~ 2025-01-13

## 핵심 지표
| 메트릭 | 이번 주 | 지난 주 | 변화 | 목표 | 상태 |
|--------|---------|---------|------|------|------|
| 재사용률 | 65% | 61% | +4% | 60% | ✅ |
| 중복률 | 3.8% | 4.5% | -0.7% | <5% | ✅ |
| Shared 사용 | 11/feature | 9/feature | +2 | 10+ | ✅ |

## 🏆 Top 5 재사용 컴포넌트
1. Button (45회)
2. Input (38회)
3. formatDate (32회)
4. Modal (28회)
5. validateEmail (24회)

## 🔴 사용되지 않는 모듈
- shared/ui/Tooltip (0회) - 제거 고려
- shared/lib/arrays/unique (0회) - 제거 고려

## 💡 개선 기회
1. **UserForm과 ProfileForm**
   - 65% 코드 중복
   - 제안: BaseUserForm 추출

2. **날짜 처리 로직**
   - 3개 feature에서 유사 구현
   - 제안: shared/lib/dates에 통합

## 📊 트렌드 분석
- 재사용률 지속 상승 중 (4주 연속)
- 새 feature 추가 시 shared 사용률 높음
- 중복 코드 감소 추세
```

### 3. 월간 상세 리포트
```markdown
# 📊 월간 재사용성 상세 분석

**기간**: 2025년 1월

## 종합 평가: A- (우수)

### 성과 요약
- ✅ 목표 재사용률 달성 (65% > 60%)
- ✅ 중복 코드 최소화 (3.8% < 5%)
- ✅ 개발 속도 32% 향상
- ✅ 버그 발생률 28% 감소

### 레이어별 분석

#### Shared Layer
- 컴포넌트: 15개 (+3)
- 평균 사용률: 8.2회/컴포넌트
- 신규 추가: Button, Modal, DatePicker

#### Entities Layer
- 도메인 컴포넌트: 8개
- 순수성 유지율: 100%
- 재사용률: 72%

#### Features Layer
- 총 features: 12개
- Shared 의존도: 85%
- 중복 코드: 2.1%

### 코드 품질 영향
| 지표 | 변화 | 영향 |
|------|------|------|
| 개발 속도 | +32% | 재사용으로 인한 시간 단축 |
| 버그 발생 | -28% | 검증된 모듈 재사용 |
| 코드 리뷰 시간 | -45% | 표준화된 패턴 |
| 온보딩 시간 | -40% | 명확한 구조 |

### 추천 액션 아이템
1. **즉시 실행**
   - [ ] 미사용 모듈 3개 제거
   - [ ] UserForm 중복 코드 추출

2. **다음 스프린트**
   - [ ] 컴포넌트 카탈로그 구축
   - [ ] 재사용성 자동 테스트 추가

3. **장기 계획**
   - [ ] 디자인 시스템 문서화
   - [ ] 컴포넌트 버전 관리
```

## 중복 감지 알고리즘

### 1. 구조적 유사도 (Structural Similarity)
```typescript
function calculateStructuralSimilarity(code1: string, code2: string): number {
  // AST 파싱
  const ast1 = parseToAST(code1);
  const ast2 = parseToAST(code2);

  // 구조 비교
  const similarity = compareASTNodes(ast1, ast2);

  return similarity; // 0-100%
}
```

### 2. 패턴 유사도 (Pattern Similarity)
```typescript
function detectPatternDuplication(files: string[]): DuplicationReport {
  const patterns = {
    stateManagement: /useState.*\n.*useEffect/g,
    formHandling: /handleSubmit.*\n.*preventDefault/g,
    apiCalling: /fetch.*\n.*then.*catch/g,
    validation: /validate.*\n.*errors/g
  };

  const duplications = [];

  for (const pattern of Object.entries(patterns)) {
    const matches = findPatternMatches(files, pattern[1]);
    if (matches.length > 2) {
      duplications.push({
        type: pattern[0],
        occurrences: matches.length,
        files: matches
      });
    }
  }

  return duplications;
}
```

## 자동화 트리거

### 1. Pre-commit Hook
```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "🔍 재사용성 체크 중..."

# 중복 코드 체크
duplication_rate=$(calculate_duplication)
if [ "$duplication_rate" -gt 5 ]; then
  echo "❌ 중복 코드가 5% 이상입니다!"
  echo "💡 shared 모듈로 추출을 고려하세요."
  exit 1
fi

# 재사용 가능 모듈 체크
reusability_check=$(check_reusable_modules)
if [ "$reusability_check" = "found" ]; then
  echo "⚠️ 재사용 가능한 모듈이 있습니다!"
  echo "💡 기존 모듈을 먼저 확인하세요."
fi
```

### 2. CI/CD Pipeline
```yaml
# .github/workflows/reusability-check.yml
name: Reusability Metrics

on: [pull_request]

jobs:
  metrics:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Calculate Metrics
        run: |
          npm run metrics:calculate

      - name: Check Thresholds
        run: |
          npm run metrics:check

      - name: Comment on PR
        uses: actions/github-script@v6
        with:
          script: |
            const metrics = require('./metrics-report.json');
            const comment = `
            ## 📊 재사용성 메트릭
            - 재사용률: ${metrics.reusabilityRate}%
            - 중복률: ${metrics.duplicationRate}%
            - Shared 사용: ${metrics.sharedUsage}
            `;
            github.issues.createComment({...});
```

## 개선 제안 생성

### 자동 제안 시스템
```typescript
function generateImprovementSuggestions(metrics: MetricsReport): Suggestion[] {
  const suggestions = [];

  // 중복 코드 발견 시
  if (metrics.duplication.rate > 5) {
    suggestions.push({
      priority: 'high',
      type: 'refactoring',
      message: `${metrics.duplication.hotspots[0]} 파일에 중복 코드가 많습니다.`,
      action: `shared/lib로 추출을 고려하세요.`,
      estimatedSaving: '200 lines'
    });
  }

  // 미사용 모듈 발견 시
  if (metrics.sharedUsage.unused.length > 0) {
    suggestions.push({
      priority: 'low',
      type: 'cleanup',
      message: `${metrics.sharedUsage.unused.length}개의 미사용 모듈이 있습니다.`,
      action: '제거를 고려하세요.',
      modules: metrics.sharedUsage.unused
    });
  }

  // 재사용 기회 발견 시
  if (metrics.reusability.opportunities.length > 0) {
    suggestions.push({
      priority: 'medium',
      type: 'extraction',
      message: '재사용 가능한 패턴을 발견했습니다.',
      patterns: metrics.reusability.opportunities
    });
  }

  return suggestions;
}
```

## 성공 지표

### 단기 목표 (1개월)
- ✅ 재사용률 60% 달성
- ✅ 중복 코드 5% 이하
- ✅ Feature당 shared 사용 10개 이상

### 중기 목표 (3개월)
- 📈 재사용률 70% 달성
- 📈 중복 코드 3% 이하
- 📈 개발 속도 40% 향상

### 장기 목표 (6개월)
- 🎯 재사용률 80% 달성
- 🎯 중복 코드 2% 이하
- 🎯 버그 발생률 50% 감소

## 대시보드 뷰

```markdown
╔══════════════════════════════════════════╗
║      재사용성 메트릭 대시보드             ║
╠══════════════════════════════════════════╣
║                                          ║
║  재사용률:  ████████░░ 65% ✅           ║
║  중복률:    ██░░░░░░░░  4% ✅           ║
║  Shared:    ███████░░░ 11/feature ✅    ║
║                                          ║
║  트렌드: ↗️ 상승 (4주 연속)              ║
║                                          ║
║  최다 사용:                              ║
║  1. Button (45회)                        ║
║  2. Input (38회)                         ║
║  3. formatDate (32회)                    ║
║                                          ║
║  개선 기회: 3건                          ║
║  [상세 보기]                             ║
╚══════════════════════════════════════════╝
```