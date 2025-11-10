# Quickstart: 문서 및 설치 검증 시스템

> 이 문서는 spec.md의 시나리오와 data-model.md의 구조를 기반으로 작성되었습니다.
> 참조: [spec.md](./spec.md), [data-model.md](./data-model.md)

## 전제조건
- [ ] Bash 4.0+ 설치됨
- [ ] Git 저장소 (`git rev-parse --git-dir` 성공)
- [ ] 표준 Unix 도구 (grep, sed, diff)
- [ ] jq 설치됨 (선택적, JSON 보고서 생성용)
  ```bash
  # macOS
  brew install jq

  # Ubuntu/Debian
  sudo apt-get install jq

  # CentOS/RHEL
  sudo yum install jq
  ```
- [ ] 충분한 디스크 공간 (임시 디렉토리용 최소 500MB)

## 데이터 모델 개요 (from data-model.md)

이 검증 시스템은 다음 엔티티를 사용합니다:

### ValidationReport
- 전체 검증 결과를 담는 최상위 보고서
- 속성: `id`, `timestamp`, `documentationResults`, `migrationResults`, `crossReferenceResults`, `overallStatus`, `consistencyScore`

### DocumentValidation
- 각 명령어 문서의 검증 결과
- 문서화된 단계 vs 실제 구현 비교
- 일치율 계산

### MigrationValidation
- 마이그레이션 시나리오 검증 결과
- v1.0 → v2.5, v2.4 → v2.5 시나리오
- deprecated 파일 제거 및 critical 파일 존재 확인

### CrossRefValidation
- 교차 참조 검증 결과
- 마크다운 링크, 파일 경로, 에이전트/스킬 참조

## 설정 단계

### 1. 검증 스크립트 생성

프로젝트 루트에 검증 스크립트를 생성합니다:

```bash
# .claude/lib/validate-system.sh 생성 (이 파일은 tasks.md에서 구현)
chmod +x .claude/lib/validate-system.sh
```

### 2. 환경 변수 설정 (선택적)

```bash
# 보고서 저장 위치 (기본값: .claude/cache/validation-reports)
export VALIDATION_REPORT_DIR=".claude/cache/validation-reports"

# 로그 레벨 (DEBUG, INFO, WARNING, ERROR)
export VALIDATION_LOG_LEVEL="INFO"

# 드라이런 모드 (true|false)
export VALIDATION_DRY_RUN="false"
```

### 3. 캐시 디렉토리 생성

```bash
mkdir -p .claude/cache/validation-reports
mkdir -p .claude/cache/validation-tmp
```

### 4. 검증 스크립트 실행

```bash
# 전체 검증 (문서 + 마이그레이션 + 교차참조)
bash .claude/lib/validate-system.sh

# 또는 개별 검증
bash .claude/lib/validate-system.sh --docs-only
bash .claude/lib/validate-system.sh --migration-only
bash .claude/lib/validate-system.sh --crossref-only
```

## 검증 시나리오 (from spec.md User Scenarios)

### 시나리오 1: 문서-코드 일관성 검증

1. **Given**: 슬래시 명령어 문서 파일이 존재함 (`.claude/commands/major.md`)
2. **When**: 검증 스크립트 실행
   ```bash
   bash .claude/lib/validate-system.sh --docs-only
   ```
3. **Then**: 100% 일치 또는 불일치 보고

**예상 결과**:
```
✅ 문서 검증 완료

명령어: major
파일: .claude/commands/major.md
일치율: 95%
불일치:
  - Step 12가 문서에 누락됨 (major.md:450)

전체 일관성 점수: 92%
```

### 시나리오 2: 마이그레이션 시나리오 검증

1. **Given**: 설치 스크립트가 존재함 (`install.sh`, 마이그레이션 스크립트)
2. **When**: 마이그레이션 검증 실행
   ```bash
   bash .claude/lib/validate-system.sh --migration-only
   ```
3. **Then**: 모든 시나리오 통과

**예상 결과**:
```
✅ 마이그레이션 검증 완료

시나리오: v1.0 → v2.5
상태: PASS
종료 코드: 0
Deprecated 파일 제거: 14/14
Critical 파일 존재: 10/10

시나리오: v2.4 → v2.5
상태: PASS
종료 코드: 0
Deprecated 파일 제거: 5/5
Critical 파일 존재: 10/10

전체 마이그레이션 성공률: 100%
```

### 시나리오 3: 교차 참조 검증

1. **Given**: 여러 문서 파일이 서로를 참조함
2. **When**: 교차 참조 검증 실행
   ```bash
   bash .claude/lib/validate-system.sh --crossref-only
   ```
3. **Then**: 모든 링크 유효

**예상 결과**:
```
✅ 교차 참조 검증 완료

검증된 링크: 142
유효한 링크: 138
깨진 링크: 4

깨진 링크 상세:
  - major.md:50 -> ./deprecated/old-spec.md (파일 없음)
  - triage.md:120 -> ../agents/old-agent.md (파일 없음)

전체 링크 유효율: 97%
```

## 검증 결과 확인

### 터미널 출력

검증 스크립트는 색상 코딩된 요약을 출력합니다:

```bash
bash .claude/lib/validate-system.sh
```

출력 예시:
```
🔍 문서 및 설치 검증 시작...

📄 문서 검증 중... (10개 명령어)
  ✓ major.md - 95%
  ✓ triage.md - 100%
  ✓ commit.md - 100%
  ✗ review.md - 75% (5개 불일치)
  ...

🔄 마이그레이션 검증 중... (2개 시나리오)
  ✓ v1.0 → v2.5 - PASS
  ✓ v2.4 → v2.5 - PASS

🔗 교차 참조 검증 중... (142개 링크)
  ✓ 138개 유효
  ✗ 4개 깨짐

📊 전체 결과:
  상태: WARNING (일부 문제 발견)
  일관성 점수: 92/100

  세부 보고서: .claude/cache/validation-reports/2025-11-10-143000.md
```

### JSON 보고서 (기계 판독용)

```bash
cat .claude/cache/validation-reports/latest.json | jq .
```

출력:
```json
{
  "id": "uuid-12345",
  "timestamp": "2025-11-10T14:30:00Z",
  "documentationResults": [...],
  "migrationResults": [...],
  "crossReferenceResults": [...],
  "overallStatus": "WARNING",
  "consistencyScore": 92
}
```

### Markdown 보고서 (사람 판독용)

```bash
cat .claude/cache/validation-reports/latest.md
```

### 히스토리 보기

```bash
# 최근 10개 보고서
ls -lt .claude/cache/validation-reports/*.md | head -10

# 특정 날짜 보고서
ls .claude/cache/validation-reports/2025-11-10-*.md
```

## 트러블슈팅

### 문제: jq가 설치되지 않음

**증상**:
```
ERROR: jq not found
```

**해결**:
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq

# 또는 JSON 보고서 없이 실행
export VALIDATION_SKIP_JSON=true
bash .claude/lib/validate-system.sh
```

### 문제: 임시 디렉토리 생성 실패

**증상**:
```
ERROR: Failed to create temporary directory
```

**해결**:
```bash
# 디스크 공간 확인
df -h /tmp

# 권한 확인
ls -ld /tmp

# 대체 tmp 디렉토리 지정
export TMPDIR="$HOME/tmp"
mkdir -p "$TMPDIR"
bash .claude/lib/validate-system.sh
```

### 문제: 마이그레이션 검증 실패

**증상**:
```
ERROR: Migration validation failed for v1.0 → v2.5
Exit code: 1
```

**해결**:
```bash
# 상세 로그 활성화
export VALIDATION_LOG_LEVEL="DEBUG"
bash .claude/lib/validate-system.sh --migration-only

# 드라이런 모드로 문제 확인
export VALIDATION_DRY_RUN="true"
bash .claude/lib/validate-system.sh --migration-only

# 로그 파일 확인
cat .claude/cache/validation-tmp/migration-v1-to-v25.log
```

### 문제: 메모리 부족

**증상**:
```
ERROR: Cannot allocate memory
```

**해결**:
```bash
# 단계별 검증 (메모리 절약)
bash .claude/lib/validate-system.sh --docs-only
bash .claude/lib/validate-system.sh --migration-only
bash .claude/lib/validate-system.sh --crossref-only

# 또는 개별 명령어만 검증
bash .claude/lib/validate-single-doc.sh .claude/commands/major.md
```

## CI/CD 통합

### GitHub Actions 예시

```yaml
# .github/workflows/validation.yml
name: Documentation & Installation Validation

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Install dependencies
        run: sudo apt-get install -y jq

      - name: Run validation
        run: bash .claude/lib/validate-system.sh

      - name: Upload report
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: validation-report
          path: .claude/cache/validation-reports/latest.md
```

### Pre-commit Hook 예시

```bash
# .git/hooks/pre-commit
#!/bin/bash

echo "Running documentation validation..."
bash .claude/lib/validate-system.sh --docs-only --quick

if [ $? -ne 0 ]; then
  echo "❌ Validation failed. Please fix documentation inconsistencies."
  exit 1
fi

echo "✅ Validation passed"
exit 0
```

## 다음 단계

1. ✅ 전제조건 확인 완료
2. ✅ 검증 스크립트 설치
3. ✅ 첫 검증 실행 및 결과 확인
4. ⏭️ 불일치 수정 (spec.md 참조)
5. ⏭️ CI/CD 통합
6. ⏭️ 정기 검증 스케줄 설정

---

**참고**: 이 가이드는 spec.md의 사용자 시나리오(US1, US2, US3)를 바탕으로 작성되었으며, data-model.md의 엔티티 구조를 따릅니다.
