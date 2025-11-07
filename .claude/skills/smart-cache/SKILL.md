---
name: smart-cache
description: 파일, 테스트, Git, 분석 결과를 자동 캐싱하여 토큰 사용량 70% 절감 및 속도 5-10배 향상
allowed-tools: [Read, Bash, Glob]
---

# Smart Cache Skill

> 반복적인 작업을 캐싱하여 토큰 절감 및 속도 향상

## 목표
- **토큰 절감**: 평균 70% 절감
- **속도 향상**: 5-10배 빠른 응답
- **캐시 히트율**: 60% 이상 목표

## 사용 원칙

### 언제 사용하는가?
- ✅ 모든 워크플로우에서 자동 활성화
- ✅ 파일 읽기 전 항상 캐시 확인
- ✅ 테스트 실행 전 결과 캐시 확인
- ✅ Git 정보 조회 시 캐시 활용

### 언제 사용하지 않는가?
- ❌ 실시간 데이터 (항상 최신 정보 필요)
- ❌ 민감한 보안 정보
- ❌ 사용자 입력 처리

## 기본 사용법

### 1. 초기화
```bash
# 캐시 시스템 로드
source .claude/lib/cache-helper.sh

# 자동으로 초기화됨 (jq 설치 필요)
# 수동 초기화가 필요한 경우:
cache_init
```

### 2. 파일 읽기 (자동 캐싱)
```bash
# BEFORE (기존 방식 - 매번 파일 읽기)
content=$(Read "$file_path")

# AFTER (캐시 적용 - 5분간 재사용)
if ! content=$(cache_file_get "$file_path"); then
    # 캐시 미스 -> 원본 읽기
    content=$(Read "$file_path")
    # 캐시에 저장 (TTL: 300초 = 5분)
    cache_file_save "$file_path" 300
fi

# 이제 content 변수 사용
echo "$content" | grep "pattern"
```

### 3. 테스트 결과 캐싱
```bash
# 테스트 스펙 정의
test_spec="yarn test src/components/Form.test.tsx"

# 캐시 확인
if test_result=$(cache_test_get "$test_spec"); then
    # 캐시된 결과 사용
    exit_code=$(echo "$test_result" | jq -r '.exit_code')
    output=$(echo "$test_result" | jq -r '.output')
    echo "✨ Using cached test result: exit code $exit_code"
else
    # 테스트 실행
    echo "🔄 Running tests..."
    output=$(yarn test src/components/Form.test.tsx 2>&1)
    exit_code=$?

    # 결과 캐싱 (TTL: 600초 = 10분)
    cache_test_save "$test_spec" "$exit_code" "$output" 600
fi
```

### 4. Git 정보 캐싱
```bash
# Git status 캐싱 (1분)
git_cmd="git status --porcelain"

if ! git_status=$(cache_git_get "$git_cmd"); then
    # 캐시 미스 -> Git 실행
    git_status=$(git status --porcelain)
    cache_git_save "$git_cmd" "$git_status" 60
fi

echo "$git_status"
```

### 5. 분석 결과 캐싱
```bash
# 복잡한 분석 결과 캐싱 (30분)
analysis_key="fsd-compliance:src/features/auth"

if ! result=$(cache_analysis_get "$analysis_key"); then
    # 분석 수행
    result=$(analyze_fsd_compliance "src/features/auth")

    # 결과 캐싱 (TTL: 1800초 = 30분)
    cache_analysis_save "$analysis_key" "$result" 1800
fi

echo "$result" | jq '.'
```

## 명령어에서 활용

### /review 명령어 예시
```markdown
# .claude/commands/review.md

## Stage 0: 준비

```bash
# 캐시 시스템 활성화
source .claude/lib/cache-helper.sh
cache_init

echo "📊 Current cache stats:"
cache_stats
```

## Stage 1: 파일 수집 (캐시 적용)

```bash
# 대상 파일 목록
files=$(Glob "src/**/*.tsx")

# 각 파일 읽기 (캐시 활용)
for file in $files; do
    if ! content=$(cache_file_get "$file"); then
        content=$(Read "$file")
        cache_file_save "$file" 300  # 5분 캐시
    fi

    # content 변수로 분석 진행
    echo "$content" | grep -i "TODO\|FIXME"
done
```
```

### /test 명령어 예시
```markdown
# .claude/commands/test.md

## 테스트 실행 (캐시 적용)

```bash
source .claude/lib/cache-helper.sh

# 각 테스트 파일
for test_file in $test_files; do
    # 파일 해시로 캐시 키 생성
    file_hash=$(md5sum "$test_file" | awk '{print $1}')
    cache_key="test:${test_file}:${file_hash}"

    if result=$(cache_test_get "$cache_key"); then
        echo "✨ Using cached test result for $test_file"
    else
        echo "🔄 Running test: $test_file"
        yarn test "$test_file"
        cache_test_save "$cache_key" "$?" "$(cat /tmp/test_output)" 600
    fi
done
```
```

## 자동 무효화 전략

### 파일 변경 감지
- **자동**: mtime (수정 시간) 비교로 자동 감지
- 파일이 변경되면 자동으로 캐시 무효화

### Git 이벤트 기반 무효화
```bash
# .git/hooks/post-commit
#!/bin/bash
source .claude/lib/cache-helper.sh
cache_invalidate_on_commit
```

### 수동 무효화
```bash
# 전체 캐시 삭제
cache_invalidate_all

# 특정 패턴 무효화
cache_invalidate_pattern "src/features/auth/*"

# 만료된 캐시 정리
cache_cleanup
```

## 통계 및 모니터링

### 캐시 성능 확인
```bash
# 통계 대시보드 출력
cache_stats

# 결과:
# ╔════════════════════════════════════════════╗
# ║        Smart Cache Performance             ║
# ╠════════════════════════════════════════════╣
# ║ 📊 Cache Statistics                        ║
# ║   Total Requests: 150
# ║   Cache Hits: 98
# ║   Cache Misses: 52
# ║   Hit Rate: 65%
# ║                                            ║
# ║ ⚡ Performance Impact                      ║
# ║   Tokens Saved: ~49,000
# ║   Time Saved: ~196s
# ║                                            ║
# ║ 💾 Storage                                 ║
# ║   Cache Size: 3.2MB
# ║   Files Cached: 47
# ║   Tests Cached: 12
# ║                                            ║
# ║ 🎯 Quality Target                          ║
# ║   Hit Rate Goal: 60%+ ✅
# ║   Token Savings: 70%+ target              ║
# ╚════════════════════════════════════════════╝
```

### Top Cached Files
```bash
# 가장 많이 캐시된 파일 확인
cache_top_files 10
```

## 고급 사용법

### 계층적 캐싱
```bash
# 레벨별 다른 TTL 적용
cache_file_save "$file" 300       # Level 1: 5분
cache_file_save "$parsed" 900     # Level 2: 15분
cache_file_save "$analyzed" 1800  # Level 3: 30분
```

### 조건부 캐싱
```bash
# 큰 파일만 캐싱 (1KB 이상)
file_size=$(wc -c < "$file")
if [[ $file_size -gt 1024 ]]; then
    cache_file_save "$file" 300
fi
```

### 배치 캐싱
```bash
# 여러 파일 한 번에 캐싱
for file in $(Glob "src/**/*.tsx"); do
    cache_file_save "$file" 300 &  # 백그라운드 실행
done
wait  # 모든 캐싱 완료 대기
```

## 설정 파일

캐시 동작은 `.claude/config/cache-config.yaml`에서 설정 가능:

```yaml
cache:
  enabled: true

  files:
    ttl: 300  # 5분
    max_size: 100

  tests:
    ttl: 600  # 10분

  git:
    ttl: 60   # 1분

  analysis:
    ttl: 1800 # 30분
```

## 예상 효과

| 시나리오 | 토큰 절감 | 속도 향상 |
|---------|----------|----------|
| 코드 리뷰 (50개 파일) | 70% | 10배 |
| 테스트 반복 실행 | 80% | 20배 |
| Git 정보 조회 | 90% | 5배 |
| 분석 결과 재사용 | 75% | 15배 |

## 문제 해결

### jq not found 에러
```bash
# macOS
brew install jq

# Linux (Ubuntu/Debian)
sudo apt-get install jq

# Linux (CentOS/RHEL)
sudo yum install jq
```

### 캐시가 업데이트되지 않음
```bash
# 특정 파일 캐시 무효화
rm .claude/cache/metadata/$(echo -n "$file_path" | md5sum | awk '{print $1}').json

# 또는 전체 캐시 삭제
cache_invalidate_all
```

### 디스크 공간 부족
```bash
# 만료된 캐시 자동 정리
cache_cleanup

# 또는 전체 캐시 삭제
cache_invalidate_all
```

## 모범 사례

### DO ✅
- 반복적으로 읽는 파일은 항상 캐싱
- 테스트 결과는 파일 해시 기반으로 캐싱
- 정기적으로 `cache_cleanup` 실행
- 캐시 통계 모니터링

### DON'T ❌
- 실시간 데이터 캐싱하지 말 것
- TTL을 너무 길게 설정하지 말 것 (stale data 위험)
- 민감한 정보 캐싱하지 말 것
- 캐시 무효화 없이 배포하지 말 것

## 성공 지표

- ✅ 캐시 히트율 60% 이상
- ✅ 토큰 절감 평균 70% 이상
- ✅ 속도 향상 5배 이상
- ✅ 디스크 사용 100MB 이하
- ✅ 캐시 관련 에러 1% 이하

## 다음 단계

1. 기본 명령어에 캐시 통합
2. 에이전트에서 캐시 활용
3. 성능 모니터링 및 최적화
4. 고급 기능 추가 (의존성 기반 무효화)

---

**v1.0.0** | Smart Cache Layer | 토큰 70% 절감, 속도 10배 향상
