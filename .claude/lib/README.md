# 문서 및 설치 검증 시스템

Claude 워크플로우 프로젝트의 문서-코드 일관성 및 마이그레이션 검증을 자동화하는 시스템입니다.

## 목차

- [개요](#개요)
- [주요 기능](#주요-기능)
- [설치 요구사항](#설치-요구사항)
- [사용 방법](#사용-방법)
- [검증 모듈](#검증-모듈)
- [보고서](#보고서)
- [CI/CD 통합](#cicd-통합)
- [문제 해결](#문제-해결)

## 개요

이 검증 시스템은 다음을 보장합니다:
1. **문서-코드 일관성**: 명령어 문서가 실제 구현과 일치하는지 검증
2. **마이그레이션 안전성**: 이전 버전에서 최신 버전으로의 업그레이드가 정상 동작하는지 검증
3. **교차 참조 무결성**: 마크다운 파일 간 링크가 올바른지 검증

## 주요 기능

### 3가지 검증 모듈

| 모듈 | 목적 | 검증 대상 |
|------|------|-----------|
| 📄 문서 검증 | 문서-코드 일관성 | `.claude/commands/*.md` 파일의 Step 패턴 및 코드 블록 |
| 🔄 마이그레이션 검증 | 버전 업그레이드 안전성 | v1.0→v2.5, v2.4→v2.5 시나리오 |
| 🔗 교차 참조 검증 | 링크 무결성 | `.claude/**/*.md` 파일의 상대 경로 링크 |

### 검증 결과

- **PASS (종료 코드 0)**: 모든 검증 통과
- **WARNING (종료 코드 2)**: 일부 검증 실패했지만 일관성 점수 ≥ 70%
- **FAIL (종료 코드 1)**: 검증 실패 및 일관성 점수 < 70%

### 자동 보고서 생성

- **JSON 보고서**: 프로그래밍 방식 처리용
- **Markdown 보고서**: 사람이 읽기 쉬운 형식
- 타임스탬프 기반 히스토리 관리 (30일 자동 삭제)
- `latest.json`, `latest.md` 심볼릭 링크

## 설치 요구사항

### 필수 도구

```bash
# Bash 4.0 이상 (macOS는 3.2이므로 주의)
bash --version

# Git
git --version

# jq (JSON 보고서 생성용)
brew install jq  # macOS
apt install jq   # Ubuntu
```

### 선택 도구

- `tree`: 디렉토리 구조 시각화 (선택)

## 사용 방법

### 기본 사용

```bash
# 전체 검증 실행
bash .claude/lib/validate-system.sh

# 특정 모듈만 실행
bash .claude/lib/validate-system.sh --docs-only
bash .claude/lib/validate-system.sh --migration-only
bash .claude/lib/validate-system.sh --crossref-only
```

### CLI 옵션

| 옵션 | 설명 |
|------|------|
| `--docs-only` | 문서 검증만 실행 |
| `--migration-only` | 마이그레이션 검증만 실행 |
| `--crossref-only` | 교차 참조 검증만 실행 |
| `--dry-run` | 드라이런 모드 (실제 변경 없음) |
| `--verbose`, `-v` | 상세 출력 |
| `--quiet`, `-q` | 최소 출력 |
| `--help`, `-h` | 도움말 표시 |

### 사용 예시

```bash
# 상세 출력과 함께 전체 검증
bash .claude/lib/validate-system.sh --verbose

# 조용한 모드로 문서만 검증 (CI/CD용)
bash .claude/lib/validate-system.sh --docs-only --quiet

# 마이그레이션 드라이런 (실제 변경 없이 테스트)
bash .claude/lib/validate-system.sh --migration-only --dry-run
```

### 종료 코드 확인

```bash
bash .claude/lib/validate-system.sh
echo "Exit code: $?"

# 스크립트에서 사용
if bash .claude/lib/validate-system.sh --quiet; then
    echo "검증 성공"
else
    exit_code=$?
    if [ $exit_code -eq 2 ]; then
        echo "경고: 일부 검증 실패"
    else
        echo "오류: 검증 실패"
        exit 1
    fi
fi
```

## 검증 모듈

### 1. 문서 검증 (validate-documentation.sh)

**목적**: 명령어 문서가 실제 구현 패턴을 정확히 설명하는지 검증

**검증 항목**:
- Step 패턴 개수 (`### Step N` 형식)
- Bash 코드 블록 개수
- Step/코드 비율의 일관성

**일관성 점수 계산**:
```
Base: 10점 (파일 존재)
+30점: Step 패턴 존재
+30점: 코드 블록 존재
+30점: Step/코드 비율이 50-200% 범위
```

**예시 출력**:
```
📄 문서 검증 시작...
  검증 완료: 3/10 통과 (평균 일치율: 67%)
```

### 2. 마이그레이션 검증 (validate-migration.sh)

**목적**: 이전 버전에서 최신 버전(v2.5)으로의 업그레이드가 안전한지 검증

**테스트 시나리오**:
1. **v1.0 → v2.5**: 대규모 업그레이드 (6개 deprecated 파일)
2. **v2.4 → v2.5**: 소규모 업그레이드 (2개 deprecated 파일)

**검증 항목**:
- Deprecated 파일 제거 확인
- Critical 파일 존재 확인 (workflow-gates.json, .version 등)
- 파일 구조 무결성

**임시 환경 사용**:
- 실제 설치에 영향 없음 (`mktemp -d` 사용)
- 자동 cleanup (trap)

**예시 출력**:
```
🔄 마이그레이션 검증 시작...
  검증 완료: 2/2 시나리오 통과
```

### 3. 교차 참조 검증 (validate-crossref.sh)

**목적**: 마크다운 파일 간 링크가 올바른 경로를 가리키는지 검증

**검증 항목**:
- 상대 경로 링크 (`./`, `../` 패턴)
- 파일 존재 확인
- 에이전트 및 스킬 파일 참조

**제외 대상**:
- 외부 링크 (http/https)
- 앵커 링크 (#)

**예시 출력**:
```
🔗 교차 참조 검증 시작...
  검증 완료: 15/15 유효 (유효율: 100%)
  ✓ 모든 링크 유효
```

## 보고서

### JSON 보고서

**위치**: `.claude/cache/validation-reports/validation-YYYYMMDD-HHMMSS.json`

**구조**:
```json
{
  "id": "report-20251110-153330",
  "timestamp": "2025-11-10T06:33:30Z",
  "overallStatus": "WARNING",
  "consistencyScore": 83,
  "documentationResults": {
    "total": 10,
    "passed": 3,
    "avgConsistency": 67,
    "details": { ... }
  },
  "migrationResults": {
    "total": 2,
    "passed": 2,
    "details": { ... }
  },
  "crossReferenceResults": {
    "totalLinks": 15,
    "validLinks": 15,
    "validity": 100,
    "details": { ... }
  }
}
```

### Markdown 보고서

**위치**: `.claude/cache/validation-reports/validation-YYYYMMDD-HHMMSS.md`

**포함 내용**:
- 📊 요약 테이블
- 📄 문서 검증 상세 결과
- 🔄 마이그레이션 시나리오별 결과
- 🔗 교차 참조 링크 검증 결과
- 📈 상세 메트릭 및 통계
- ⚠️ 경고 및 권장사항

### 보고서 조회

```bash
# 최신 JSON 보고서 조회
cat .claude/cache/validation-reports/latest.json | jq .

# 최신 Markdown 보고서 조회
cat .claude/cache/validation-reports/latest.md

# 특정 날짜 보고서 조회
ls -lh .claude/cache/validation-reports/
cat .claude/cache/validation-reports/validation-20251110-*.json
```

## CI/CD 통합

### GitHub Actions

```yaml
name: 검증

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: jq 설치
        run: sudo apt-get install -y jq

      - name: 문서 및 설치 검증
        run: |
          bash .claude/lib/validate-system.sh --quiet
          exit_code=$?

          if [ $exit_code -eq 0 ]; then
            echo "✅ 모든 검증 통과"
          elif [ $exit_code -eq 2 ]; then
            echo "⚠️ 경고: 일부 검증 실패 (계속 진행)"
          else
            echo "❌ 검증 실패"
            exit 1
          fi

      - name: 보고서 업로드
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: validation-report
          path: .claude/cache/validation-reports/latest.*
```

### Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "🔍 검증 실행 중..."

# 문서 검증만 실행 (빠른 피드백)
if ! bash .claude/lib/validate-system.sh --docs-only --quiet; then
    exit_code=$?

    if [ $exit_code -eq 2 ]; then
        echo "⚠️ 경고: 문서 일관성 낮음 (커밋 허용)"
        exit 0
    else
        echo "❌ 문서 검증 실패"
        echo "보고서: .claude/cache/validation-reports/latest.md"
        exit 1
    fi
fi

echo "✅ 검증 통과"
exit 0
```

설치:
```bash
cp .claude/hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

## 문제 해결

### macOS Bash 버전 문제

macOS는 기본적으로 Bash 3.2를 사용합니다. Bash 4.0+ 기능이 필요한 경우:

```bash
# Homebrew로 최신 Bash 설치
brew install bash

# 설치된 Bash로 실행
/usr/local/bin/bash .claude/lib/validate-system.sh
```

### jq 미설치 경고

JSON 보고서 생성을 위해 jq가 필요합니다:

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq

# CentOS/RHEL
sudo yum install jq
```

### 권한 오류

```bash
# 실행 권한 부여
chmod +x .claude/lib/validate-system.sh
chmod +x .claude/lib/validate-*.sh
```

### 교차 참조 검증 오류

상대 경로가 올바른지 확인:
```bash
# 깨진 링크 보고서 생성
bash .claude/lib/validate-crossref.sh .claude
```

## 테스트 실행

### 단위 테스트

```bash
# 문서 검증 테스트
bash .claude/lib/__tests__/test-validate-documentation.sh

# 마이그레이션 검증 테스트
bash .claude/lib/__tests__/test-validate-migration.sh

# 교차 참조 검증 테스트
bash .claude/lib/__tests__/test-validate-crossref.sh
```

**전체 테스트**: 60개 테스트 (모두 통과 예상)
- 문서 검증: 22개
- 마이그레이션 검증: 23개
- 교차 참조 검증: 15개

## 아키텍처

```
.claude/lib/
├── validation-utils.sh         # 공통 유틸리티 함수
├── validate-system.sh          # 메인 오케스트레이터
├── validate-documentation.sh   # 문서 검증 모듈
├── validate-migration.sh       # 마이그레이션 검증 모듈
├── validate-crossref.sh        # 교차 참조 검증 모듈
├── report-generator.sh         # 보고서 생성 모듈
└── __tests__/                  # 테스트 스크립트
    ├── test-validate-documentation.sh
    ├── test-validate-migration.sh
    └── test-validate-crossref.sh
```

## 기여

이 검증 시스템은 TDD(Test-Driven Development) 방식으로 개발되었습니다:
1. 테스트 먼저 작성
2. 최소 구현으로 테스트 통과
3. 리팩토링 및 개선

## 라이선스

Claude Workflow 프로젝트와 동일한 라이선스를 따릅니다.

## 문의

문제 발생 시 `.claude/cache/validation-reports/latest.md` 보고서를 확인하거나
이슈를 등록해주세요.

---

**v2.5 검증 시스템**
자동화된 품질 보증으로 안전한 워크플로우 운영을 지원합니다.
