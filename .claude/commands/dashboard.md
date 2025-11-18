# 📊 실시간 메트릭스 대시보드

## Overview

Real-time monitoring dashboard for Claude Workflows performance metrics, token usage, and quality indicators.

This command provides:
1. **Token Usage**: Track token consumption by workflow and agent
2. **Performance Metrics**: Monitor execution times and throughput
3. **Quality Indicators**: View test coverage, code quality scores
4. **Session Statistics**: Current session and historical data

**Key Features:**
- Real-time metric updates
- Workflow-specific breakdowns
- Agent performance comparison
- Token efficiency tracking
- Visual progress indicators

## Usage

```bash
/dashboard
```

The command will display:
- Current session metrics
- Today's statistics
- Top consuming workflows/agents
- Quality gate pass rates

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `--full` | Show detailed breakdown | `false` |
| `--history` | Show last N days | `7` |
| `--export` | Export to JSON file | `false` |

## Examples

### Example 1: Basic Dashboard

```bash
/dashboard
```

**Output:**
```
╔═══════════════════════════════════════════════════╗
║     Claude Workflows - Metrics Dashboard          ║
╚═══════════════════════════════════════════════════╝

📊 Current Session (2025-11-18 13:00)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Tokens Used:        45,230 / 200,000 (22.6%)
Tasks Completed:    8
Success Rate:       100%
Avg. Time/Task:     2m 15s

🎯 Workflow Breakdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Major    ████████░░  3 tasks   18,450 tokens
Minor    ██████░░░░  3 tasks   12,300 tokens
Micro    ████░░░░░░  2 tasks    8,240 tokens

🤖 Agent Performance
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

architect-unified     5 calls    8,450 tokens
reviewer-unified      6 calls    11,230 tokens
implementer-unified   8 calls    15,670 tokens
documenter-unified    8 calls    6,120 tokens

✅ Quality Metrics
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Test Coverage:       87%  ████████▌░
Code Quality:        92%  █████████▏░
Architecture Gates:  100% ██████████

💾 Cache Efficiency
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Cache Hit Rate:      73%  ███████▎░░
Tokens Saved:        32,450
Performance Gain:    5.2x
```

### Example 2: Full Details

```bash
/dashboard --full
```

**Shows additional info:**
- Per-file analysis
- Detailed agent breakdowns
- Cache statistics
- Historical trends

### Example 3: Export Metrics

```bash
/dashboard --export metrics.json
```

**Creates:** `.claude/cache/metrics/metrics-20251118.json`

## Implementation

### Architecture

The dashboard aggregates data from:
- **Cache System**: `.claude/cache/metrics/`
- **Git Statistics**: Recent commit activity
- **Session Tracking**: Current workflow state
- **Quality Gates**: workflow-gates.json validation results

### Dependencies

**Required:**
- Metrics collection system (auto-enabled)
- Cache directory: `.claude/cache/metrics/`

**Optional:**
- Git repository for commit stats
- Quality gate configuration

### Workflow Steps

1. **Data Collection**
   - Read current session metrics
   - Aggregate historical data
   - Calculate derived metrics

2. **Analysis**
   - Compute averages and trends
   - Identify top consumers
   - Calculate efficiency scores

3. **Presentation**
   - Format data with visual indicators
   - Apply color coding for status
   - Generate summary statistics

### Related Resources

- **Cache Files**:
  - `current-session.json`: Active session data
  - `stats.json`: Historical aggregates
  - `summary.json`: Daily/weekly summaries
- **Configuration**: `.claude/config/cache-config.yaml`

### Metric Types

**Token Metrics:**
- Total tokens used
- Per-workflow breakdown
- Per-agent consumption
- Cache savings

**Performance Metrics:**
- Task completion time
- Agent execution time
- Workflow overhead
- Cache hit/miss rates

**Quality Metrics:**
- Test coverage percentage
- Code quality score
- Architecture compliance
- Documentation completeness

## 옵션

### --full
전체 상세 정보 표시:
- 파일별 분석
- 에이전트별 호출 내역
- 캐시 상세 통계
- 주간/월간 트렌드

### --history <days>
지정된 일수만큼의 히스토리 표시:
```bash
/dashboard --history 30  # 최근 30일
```

### --export <file>
JSON 형식으로 메트릭 내보내기:
```bash
/dashboard --export report.json
```

### --reset
세션 통계 초기화 (주의!):
```bash
/dashboard --reset
```

## 표시 항목

### 1. 세션 정보
- 시작 시간
- 경과 시간
- 완료된 태스크 수
- 성공률

### 2. 토큰 사용량
- 총 사용 토큰
- 워크플로우별 분포
- 에이전트별 분포
- 예상 비용 (API 호출 기준)

### 3. 성능 지표
- 평균 태스크 완료 시간
- 에이전트 실행 시간
- 캐시 효율성
- 속도 향상 배수

### 4. 품질 지표
- 테스트 커버리지
- 코드 품질 점수
- 아키텍처 게이트 통과율
- 문서화 완성도

### 5. 캐시 통계
- 히트율
- 절약된 토큰
- 파일/테스트/분석 캐시별 분류

## 실행

### 자동 수집
메트릭은 자동으로 수집됩니다:
- 워크플로우 실행 시
- 에이전트 호출 시
- 캐시 사용 시

### 수동 확인
언제든지 대시보드를 실행하여 현재 상태 확인:
```bash
/dashboard
```

### 주기적 모니터링
워크플로우 진행 중 주기적으로 확인하여:
- 토큰 예산 관리
- 성능 병목 지점 파악
- 캐시 효율성 최적화

### 문제 해결

**"No metrics data found"**
- **원인**: 아직 워크플로우를 실행하지 않음
- **해결**: 먼저 /major, /minor, 또는 /micro 실행

**"Cache directory missing"**
- **원인**: .claude/cache/metrics/ 디렉토리 없음
- **해결**: 자동으로 생성됨, 권한 확인 필요

**통계가 부정확함**
- **원인**: 캐시 손상 또는 불완전한 세션
- **해결**: `--reset` 옵션으로 초기화 후 재시작

---

**Version**: 3.3.1
**Last Updated**: 2025-11-18
