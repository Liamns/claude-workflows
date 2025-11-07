# Parallel Orchestrator Patterns

> 검증된 병렬 실행 패턴 라이브러리

## 개요

이 문서는 Parallel Orchestrator에서 사용하는 구체적인 병렬 실행 패턴을 정의합니다. 각 패턴은 실전에서 검증되었으며, 안전하고 효율적인 병렬 처리를 보장합니다.

---

## Pattern 1: 병렬 검증 (Parallel Validation)

### 목적
여러 검증 작업을 동시에 수행하여 사전 검증 시간 단축

### 적용 시점
- 코드 구현 전 검증 단계
- PR 리뷰 시작 시
- Major/Minor 워크플로우 Phase 1

### 병렬 실행 가능 에이전트
```yaml
동시 실행:
  - architect-unified    # 아키텍처 규칙 검증
  - reviewer-unified     # 보안/품질 검토
  - documenter-unified   # 변경사항 분석 (백그라운드)
```

### 구현 예시

#### Claude의 단일 응답 메시지
```markdown
Phase 1 검증을 시작합니다. 세 가지 검증을 병렬로 수행합니다.

<skill>parallel-orchestrator</skill> 활성화

동시 실행:
1. Skill(architect-unified) - FSD 아키텍처 규칙 검증
2. Skill(reviewer-unified) - 보안 취약점 및 코드 품질 검토
3. Skill(documenter-unified) - 변경사항 분석 (백그라운드)
```

#### 에이전트별 독립 작업
```bash
# architect-unified (독립)
→ Read src/features/auth/**/*.tsx
→ Grep "export.*from" src/features/
→ Bash(yarn type-check)
→ FSD 규칙 위반 검출

# reviewer-unified (독립)
→ Bash(git diff HEAD~1)
→ Grep -i "password|secret|token"
→ Bash(npm audit)
→ 보안 취약점 분석

# documenter-unified (독립)
→ Bash(git log --since="1 week ago")
→ Bash(git diff main...HEAD)
→ 변경사항 요약 생성
```

### 예상 효과
- **시간**: 5-6분 → 2-3분 (50-60% 단축)
- **토큰**: 중복 컨텍스트 로드 방지
- **충돌**: 없음 (모두 읽기 전용)

### 주의사항
- 각 에이전트가 서로 다른 파일/디렉토리 스캔
- 동일 파일을 읽는 것은 안전 (캐시 활용 가능)
- Git 정보는 캐시됨 (1분 TTL)

---

## Pattern 2: 순차 구현 (Sequential Implementation)

### 목적
파일 쓰기 충돌 방지 및 의존성 순서 보장

### 적용 시점
- API 타입 정의 생성
- 실제 코드 구현
- Git 커밋 작업

### 순차 실행 필요 에이전트
```yaml
순차 실행:
  1. api-designer        # API 계약 생성 (Write)
     ↓ (완료 대기)
  2. implementer-unified # 코드 구현 (Edit/Write)
     ↓ (완료 대기)
  3. documenter-unified  # Git 커밋 (Bash git)
```

### 구현 예시

#### Claude의 순차 메시지
```markdown
Phase 1 검증 완료. 이제 순차적으로 구현을 진행합니다.

Phase 2: API 설계
Skill(api-designer)
```

(api-designer 완료 후 다음 메시지)

```markdown
API 타입이 생성되었습니다. 이제 구현을 진행합니다.

Phase 3: 구현
Skill(implementer-unified)
```

(implementer-unified 완료 후 다음 메시지)

```markdown
구현이 완료되었습니다. Git 커밋을 생성합니다.

Phase 4: 문서화
Skill(documenter-unified)
```

### 왜 순차인가?
```bash
# api-designer
→ Write src/shared/api/auth/types.ts
   (파일 생성 - 다른 에이전트가 읽어야 함)

# implementer-unified (의존)
→ Read src/shared/api/auth/types.ts  # api-designer 결과 필요
→ Edit src/features/auth/model/store.ts
→ Write src/features/auth/ui/LoginForm.tsx

# documenter-unified (의존)
→ Bash(git add .)                    # implementer 결과 필요
→ Bash(git commit -m "...")
```

### 예상 효과
- **안전성**: 파일 충돌 0%
- **정확성**: 의존성 순서 보장
- **시간**: 순차 필요 (병렬 불가능)

---

## Pattern 3: 혼합 실행 (Hybrid Execution)

### 목적
병렬 가능한 작업은 병렬로, 순차 필요한 작업은 순차로 최적화

### 적용 시점
- Major 워크플로우 전체
- Minor 워크플로우 전체

### 실행 전략

#### Phase 구분
```yaml
Phase 1 (병렬):
  - architect-unified
  - reviewer-unified
  - documenter-unified (분석만)

Phase 2 (순차):
  - api-designer

Phase 3 (순차):
  - implementer-unified

Phase 4 (순차):
  - documenter-unified (커밋)
```

### 구현 예시

#### /major 워크플로우
```markdown
Major 워크플로우를 시작합니다.

=== Phase 1: 병렬 검증 (2-3분) ===

동시 실행:
1. Skill(architect-unified)
2. Skill(reviewer-unified)
3. Skill(documenter-unified) - 분석 모드
```

(Phase 1 완료 후)

```markdown
=== Phase 2: API 설계 (3-4분) ===

Skill(api-designer)
```

(Phase 2 완료 후)

```markdown
=== Phase 3: 구현 (4-5분) ===

Skill(implementer-unified)
```

(Phase 3 완료 후)

```markdown
=== Phase 4: 문서화 (1분) ===

Skill(documenter-unified) - Git 커밋 모드
```

### 예상 효과
- **총 시간**: 15-18분 → 10-13분
- **속도 향상**: 33-40%
- **안정성**: 100% (충돌 없음)

---

## Pattern 4: Fallback 재시도 (Fallback Retry)

### 목적
병렬 실행 실패 시 자동으로 순차 모드로 전환하여 안정성 보장

### 적용 시점
- 병렬 실행 중 에러 발생 시
- 타임아웃 발생 시
- 예상치 못한 충돌 발생 시

### 오류 감지 및 전환

#### 시나리오: reviewer-unified 타임아웃
```markdown
Phase 1 병렬 검증 중...

결과:
- architect-unified: ✅ 완료 (120초)
- reviewer-unified: ❌ 타임아웃 (600초 초과)
- documenter-unified: ✅ 완료 (90초)

⚠️ 병렬 실행 중 오류가 발생했습니다.
🔄 순차 모드로 자동 전환합니다...
```

#### 순차 재시도
```markdown
순차 재시도 시작:

1. architect-unified
   → 이미 완료 (캐시 재사용) ✅

2. reviewer-unified
   → 재실행 (순차) 🔄
   → Bash(git diff) - 성공
   → Bash(npm audit) - 성공
   → 완료 (180초) ✅

3. documenter-unified
   → 이미 완료 (캐시 재사용) ✅

✅ 순차 모드로 모든 작업 완료
⏱️ 총 소요 시간: 180초 (재시도)
```

### Fallback 전략 상세

#### 1단계: 오류 감지
```bash
if [[ $parallel_success == false ]]; then
    echo "⚠️ 병렬 실행 실패 감지"

    # 성공한 에이전트 결과는 보존
    # 실패한 에이전트만 재실행
fi
```

#### 2단계: 캐시 재사용
```bash
for agent in $agents; do
    if cache_exists "$agent"; then
        echo "→ $agent: 캐시 재사용 ✅"
    else
        echo "→ $agent: 순차 재실행 🔄"
        run_agent_sequential "$agent"
    fi
done
```

#### 3단계: 사용자 알림
```markdown
✅ Fallback 완료

병렬 실행: 실패 (1개 타임아웃)
순차 재시도: 성공
추가 소요 시간: +2-3분
최종 상태: 모든 작업 완료 ✅
```

### 예상 효과
- **성공률**: 95% (병렬) + 5% (fallback) = 100%
- **추가 시간**: +2-3분 (병렬 대비)
- **사용자 경험**: 투명한 알림

---

## Pattern 5: 조건부 병렬화 (Conditional Parallelization)

### 목적
작업 크기와 복잡도에 따라 동적으로 병렬/순차 결정

### 적용 시점
- 변경 파일 개수 확인 후
- 프로젝트 크기 확인 후
- 리소스 가용성 확인 후

### 조건 분기 로직

#### 파일 개수 기반
```bash
changed_files=$(git diff --name-only HEAD~1 | wc -l)

if [[ $changed_files -lt 10 ]]; then
    # 작은 변경 → 병렬 불필요 (순차가 더 빠름)
    echo "변경 파일 $changed_files개 → 순차 실행"
    run_sequential
elif [[ $changed_files -lt 50 ]]; then
    # 중간 변경 → 병렬 2개
    echo "변경 파일 $changed_files개 → 병렬 2개"
    run_parallel 2
else
    # 큰 변경 → 병렬 3개
    echo "변경 파일 $changed_files개 → 병렬 3개"
    run_parallel 3
fi
```

#### 프로젝트 크기 기반
```bash
project_size=$(find src -name "*.tsx" -o -name "*.ts" | wc -l)

if [[ $project_size -lt 100 ]]; then
    # 소규모 → 순차
    max_parallel=1
elif [[ $project_size -lt 500 ]]; then
    # 중규모 → 병렬 2개
    max_parallel=2
else
    # 대규모 → 병렬 3개
    max_parallel=3
fi
```

### 예상 효과
- **자원 효율**: 작은 작업에 과도한 병렬 방지
- **최적 성능**: 크기에 맞는 병렬도 선택
- **비용 절감**: 불필요한 토큰 사용 방지

---

## Pattern 6: 백그라운드 분석 (Background Analysis)

### 목적
메인 작업 중 백그라운드에서 문서화 준비 작업 수행

### 적용 시점
- 구현 중 changelog 수집
- 리뷰 중 변경사항 분석
- 테스트 중 커버리지 분석

### 실행 전략

#### documenter-unified 백그라운드 모드
```markdown
Phase 1: 병렬 검증

동시 실행:
1. architect-unified (포그라운드)
2. reviewer-unified (포그라운드)
3. documenter-unified (백그라운드 분석만)
   → Git log 수집
   → 변경사항 파싱
   → 커밋 메시지 초안 작성
   (Git 쓰기 작업은 하지 않음)
```

#### Phase 4에서 재사용
```markdown
Phase 4: 문서화

documenter-unified (Git 커밋 모드)
→ Phase 1에서 준비한 초안 사용
→ 최종 검토 및 커밋만 수행
→ 시간 절약: 3분 → 1분
```

### 예상 효과
- **시간 절약**: Phase 4 시간 단축
- **병렬 효율**: 유휴 시간 활용
- **품질**: 충분한 분석 시간 확보

---

## Pattern 7: 캐시 활용 병렬화 (Cache-Aware Parallelization)

### 목적
Smart Cache Layer와 연계하여 중복 파일 읽기 최소화

### 적용 시점
- 여러 에이전트가 동일 파일 접근 시
- 반복 실행 시 (재시도, 디버깅)

### 캐시 전략

#### 파일 캐시 공유
```bash
# architect-unified
→ Read src/features/auth/index.ts
→ cache_file_save "src/features/auth/index.ts" 300

# reviewer-unified (동시 실행)
→ cache_file_get "src/features/auth/index.ts"  # HIT!
→ 파일 읽기 생략 (토큰 절감)

# documenter-unified (동시 실행)
→ cache_file_get "src/features/auth/index.ts"  # HIT!
→ 파일 읽기 생략 (토큰 절감)
```

#### Git 정보 캐시
```bash
# 첫 번째 에이전트
→ Bash(git status)
→ cache_git_save "git status" "$output" 60

# 두 번째, 세 번째 에이전트
→ cache_git_get "git status"  # HIT!
→ Git 명령 실행 생략
```

### 예상 효과
- **토큰 절감**: 70% (중복 파일 읽기 제거)
- **속도**: 2-3배 향상 (캐시 히트 시)
- **안정성**: 파일 일관성 보장 (동일 mtime)

---

## Pattern 8: 점진적 병렬화 (Progressive Parallelization)

### 목적
처음엔 순차로 시작, 안정성 확인 후 점진적으로 병렬도 증가

### 적용 시점
- 새로운 프로젝트 초기
- 워크플로우 테스트 중
- 신뢰성 우선 시

### 단계별 증가 전략

#### Level 1: 완전 순차 (Fully Sequential)
```yaml
max_parallel: 1
모든 에이전트 순차 실행
```

#### Level 2: 제한 병렬 (Limited Parallel)
```yaml
max_parallel: 2
검증 에이전트만 2개 병렬
나머지는 순차
```

#### Level 3: 전체 병렬 (Full Parallel)
```yaml
max_parallel: 3
모든 읽기 전용 에이전트 병렬
```

### 전환 조건
```bash
# 성공률 기반 자동 전환
success_rate=$(calculate_success_rate)

if [[ $success_rate -gt 95 ]]; then
    # Level 3로 승급
    max_parallel=3
elif [[ $success_rate -gt 85 ]]; then
    # Level 2 유지
    max_parallel=2
else
    # Level 1로 강등
    max_parallel=1
fi
```

### 예상 효과
- **안정성**: 점진적 검증으로 위험 최소화
- **신뢰**: 충분한 테스트 후 병렬도 증가
- **유연성**: 프로젝트별 최적화

---

## 패턴 선택 가이드

### 워크플로우별 권장 패턴

| 워크플로우 | 권장 패턴 | 이유 |
|-----------|----------|------|
| /major | Pattern 3 (혼합) | 검증 병렬, 구현 순차 |
| /minor | Pattern 1 + 2 (병렬→순차) | 간단한 2단계 |
| /review | Pattern 1 (병렬) | 검증만 수행 |
| /test | Pattern 5 (조건부) | 테스트 개수 기반 |

### 프로젝트 상황별 권장 패턴

| 상황 | 권장 패턴 | 이유 |
|------|----------|------|
| 신규 프로젝트 | Pattern 8 (점진적) | 안정성 우선 |
| 성숙한 프로젝트 | Pattern 3 (혼합) | 최대 효율 |
| 대규모 변경 | Pattern 7 (캐시) | 중복 최소화 |
| 실패 빈번 | Pattern 4 (Fallback) | 재시도 보장 |

---

## 구현 체크리스트

### Pattern 적용 전 확인사항

- [ ] 에이전트 도구 권한 확인 (읽기/쓰기)
- [ ] 파일 충돌 가능성 검토
- [ ] 의존성 그래프 작성
- [ ] TTL 설정 (캐시 전략)
- [ ] Fallback 전략 정의
- [ ] 타임아웃 설정
- [ ] 성공률 목표 설정

### Pattern 적용 후 모니터링

- [ ] 실제 속도 향상 측정
- [ ] 병렬 성공률 추적
- [ ] Fallback 발생 빈도 확인
- [ ] 토큰 절감 효과 측정
- [ ] 사용자 피드백 수집

---

## 참고 자료

- **SKILL.md**: Parallel Orchestrator 전체 가이드
- **parallel-config.yaml**: 설정 옵션
- **smart-cache/SKILL.md**: 캐시 연계 전략
- **IMPROVEMENT-PROPOSALS.md**: 설계 배경

---

**v1.0.0** | Parallel Orchestrator Patterns | 8가지 검증된 패턴
