# 📊 실시간 메트릭스 대시보드

**Claude를 위한 필수 지시사항:**

이 명령어가 실행될 때 반드시 다음 단계를 **순서대로** 따라야 합니다:

1. 사전 조건 확인 (메트릭 데이터 존재 - .claude/cache/metrics/)
2. 메트릭 표시 스크립트 실행
3. 결과를 파싱하고 표시
4. 데이터 분석 및 인사이트 제공
5. AskUserQuestion을 사용하여 권장사항 제공

**절대로 사전 조건 확인 단계를 건너뛰지 마세요.**

---

## Overview

Claude 워크플로우(Workflow) 성능 메트릭(metric), 토큰(token) 사용량, 품질 지표를 위한 실시간 모니터링 대시보드입니다.

## Output Language

**IMPORTANT**: 사용자가 확인하는 모든 메트릭 출력은 반드시 **한글로 작성**해야 합니다.

**한글 작성 대상:**
- 대시보드 전체 출력
- 메트릭 설명 및 레이블
- 성능 지표 분석
- 통계 요약

**영어 유지:**
- 명령어
- 파일 경로
- 에이전트 이름 (architect-unified 등)

**예시 출력:**
```
╔═══════════════════════════════════════════════════╗
║     Claude Workflows - 메트릭 대시보드            ║
╚═══════════════════════════════════════════════════╝

📊 현재 세션 (2025-11-18 13:00)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

사용 토큰:        45,230 / 200,000 (22.6%)
완료된 작업:      8개
성공률:           100%
평균 소요시간:    2분 15초

🎯 워크플로우 분석
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Major    ████████░░  3개 작업   18,450 토큰
Minor    ██████░░░░  3개 작업   12,300 토큰
Micro    ████░░░░░░  2개 작업    8,240 토큰
```

이 커맨드는 다음을 제공합니다:
1. **토큰 사용량**: 워크플로우(workflow)와 에이전트(agent)별 토큰 소비 추적
2. **성능 메트릭**: 실행 시간과 처리량 모니터링
3. **품질 지표**: 테스트 커버리지, 코드 품질 점수 확인
4. **세션 통계**: 현재 세션 및 히스토리 데이터

**주요 기능:**
- 실시간 메트릭 업데이트
- 워크플로우(workflow)별 상세 분석
- 에이전트(agent) 성능 비교
- 토큰 효율성 추적
- 시각적 진행 표시기

## Usage

```bash
/dashboard
```

이 커맨드는 다음을 표시합니다:
- 현재 세션 메트릭
- 오늘의 통계
- 토큰을 가장 많이 소비하는 워크플로우(workflow)/에이전트(agent)
- 품질 게이트(quality gate) 통과율

### Options

| 옵션 | 설명 | 기본값 |
|--------|-------------|---------|
| `--full` | 상세 분석 표시 | `false` |
| `--history` | 최근 N일 표시 | `7` |
| `--export` | JSON 파일로 내보내기 | `false` |

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

**추가 정보 표시:**
- 파일별 분석
- 에이전트(agent) 상세 분석
- 캐시(cache) 통계
- 히스토리 추세

### Example 3: Export Metrics

```bash
/dashboard --export metrics.json
```

**생성됨:** `.claude/cache/metrics/metrics-20251118.json`

## Implementation

### Architecture

대시보드는 다음에서 데이터를 수집합니다:
- **캐시 시스템(Cache System)**: `.claude/cache/metrics/`
- **Git 통계**: 최근 커밋 활동
- **세션 추적**: 현재 워크플로우(workflow) 상태
- **품질 게이트(Quality Gates)**: workflow-gates.json 검증 결과

### Dependencies

**필수:**
- 메트릭 수집 시스템 (자동 활성화)
- 캐시 디렉토리: `.claude/cache/metrics/`

**선택:**
- 커밋 통계를 위한 Git 저장소
- 품질 게이트(quality gate) 설정

### Workflow Steps

1. **데이터 수집**
   - 현재 세션 메트릭 읽기
   - 히스토리 데이터 집계
   - 파생 메트릭 계산

2. **분석**
   - 평균 및 추세 계산
   - 최다 소비자 식별
   - 효율성 점수 계산

3. **표시**
   - 시각적 표시기로 데이터 포맷
   - 상태별 색상 코딩 적용
   - 요약 통계 생성

### Related Resources

- **캐시 파일(Cache Files)**:
  - `current-session.json`: 활성 세션 데이터
  - `stats.json`: 히스토리 집계
  - `summary.json`: 일간/주간 요약
- **설정(Configuration)**: `.claude/config/cache-config.yaml`

### Metric Types

**토큰 메트릭:**
- 총 사용 토큰
- 워크플로우(workflow)별 분석
- 에이전트(agent)별 소비량
- 캐시 절감량

**성능 메트릭:**
- 작업(task) 완료 시간
- 에이전트(agent) 실행 시간
- 워크플로우(workflow) 오버헤드
- 캐시(cache) 적중/실패율

**품질 메트릭:**
- 테스트 커버리지 비율
- 코드 품질 점수
- 아키텍처(architecture) 준수도
- 문서화 완성도

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

**Version**: 3.3.2
**Last Updated**: 2025-11-18
