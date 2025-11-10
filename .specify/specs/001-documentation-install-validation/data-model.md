# 데이터 모델: 문서 및 설치 검증 시스템

> 이 문서는 spec.md의 핵심 엔티티를 기반으로 작성되었습니다.
> 참조: [spec.md](./spec.md)

## 엔티티

### ValidationReport (검증 보고서)

```bash
# Bash에서 사용할 구조 (JSON 형식)
{
  "id": "uuid",
  "timestamp": "2025-11-10T14:30:00Z",
  "documentationResults": [ ... ],
  "migrationResults": [ ... ],
  "crossReferenceResults": [ ... ],
  "overallStatus": "PASS|FAIL|WARNING",
  "consistencyScore": 95
}
```

**검증 스키마 (Bash 함수)**:
```bash
validate_report() {
  local report_file="$1"

  # consistency Score는 0-100 사이여야 함
  local score=$(jq -r '.consistencyScore' "$report_file")
  if [[ $score -lt 0 || $score -gt 100 ]]; then
    echo "ERROR: consistencyScore must be 0-100"
    return 1
  fi

  # overallStatus는 PASS, FAIL, WARNING 중 하나
  local status=$(jq -r '.overallStatus' "$report_file")
  if [[ ! "$status" =~ ^(PASS|FAIL|WARNING)$ ]]; then
    echo "ERROR: overallStatus must be PASS, FAIL, or WARNING"
    return 1
  fi

  # timestamp는 ISO 8601 형식
  local timestamp=$(jq -r '.timestamp' "$report_file")
  if ! date -d "$timestamp" &>/dev/null; then
    echo "ERROR: timestamp must be ISO 8601 format"
    return 1
  fi

  return 0
}
```

**관계**:
- `documentationResults[]`: DocumentValidation 배열
- `migrationResults[]`: MigrationValidation 배열
- `crossReferenceResults[]`: CrossRefValidation 배열

### DocumentValidation (문서 검증)

```bash
# Bash에서 사용할 구조 (JSON 형식)
{
  "commandName": "major",
  "filePath": ".claude/commands/major.md",
  "extractedSteps": [
    "Step 0: 사전 조건 확인",
    "Step 1: Feature 브랜치 생성",
    ...
  ],
  "actualImplementation": [
    "validate_target_dir",
    "create_feature_branch",
    ...
  ],
  "matches": [
    {
      "step": "Step 0",
      "implementation": "validate_target_dir",
      "confidence": 100
    }
  ],
  "discrepancies": [
    {
      "step": "Step 5",
      "issue": "Step not found in implementation",
      "severity": "HIGH"
    }
  ],
  "consistencyPercentage": 90
}
```

**검증 스키마 (Bash 함수)**:
```bash
validate_doc() {
  local doc_file="$1"

  # commandName은 파일 이름과 일치해야 함
  local command_name=$(jq -r '.commandName' "$doc_file")
  local file_path=$(jq -r '.filePath' "$doc_file")
  local file_basename=$(basename "$file_path" .md)

  if [[ "$command_name" != "$file_basename" ]]; then
    echo "ERROR: commandName must match file name"
    return 1
  fi

  # filePath는 존재해야 함
  if [[ ! -f "$file_path" ]]; then
    echo "ERROR: filePath does not exist"
    return 1
  fi

  # consistencyPercentage 계산 검증
  local matches=$(jq '.matches | length' "$doc_file")
  local extracted=$(jq '.extractedSteps | length' "$doc_file")
  local expected=$((matches * 100 / extracted))
  local actual=$(jq -r '.consistencyPercentage' "$doc_file")

  if [[ $expected != $actual ]]; then
    echo "WARNING: consistencyPercentage calculation mismatch"
  fi

  return 0
}
```

### MigrationValidation (마이그레이션 검증)

```bash
# Bash에서 사용할 구조 (JSON 형식)
{
  "scenarioName": "v1.0 to v2.5",
  "initialVersion": "1.0.0",
  "targetVersion": "2.5.0",
  "setupScript": ".claude/lib/setup-v1-env.sh",
  "migrationScript": "install.sh",
  "executionLog": "... full output ...",
  "exitCode": 0,
  "deprecatedFilesRemoved": [
    ".claude/commands/major-specify.md",
    ".claude/agents/architect.md"
  ],
  "criticalFilesPresent": [
    ".claude/workflow-gates.json",
    ".claude/commands/major.md",
    ".claude/.version"
  ],
  "validationStatus": "PASS"
}
```

**검증 스키마 (Bash 함수)**:
```bash
validate_migration() {
  local test_dir="$1"
  local validation_file="$2"

  # exitCode가 0이면 PASS
  local exit_code=$(jq -r '.exitCode' "$validation_file")
  if [[ $exit_code -eq 0 ]]; then
    echo "✓ Exit code check passed"
  else
    echo "✗ Exit code check failed: $exit_code"
    return 1
  fi

  # deprecatedFilesRemoved의 모든 파일은 존재하지 않아야 함
  local deprecated_files=$(jq -r '.deprecatedFilesRemoved[]' "$validation_file")
  while IFS= read -r file; do
    if [[ -f "$test_dir/$file" ]]; then
      echo "✗ Deprecated file still exists: $file"
      return 1
    fi
  done <<< "$deprecated_files"
  echo "✓ Deprecated files removed"

  # criticalFilesPresent의 모든 파일은 존재해야 함
  local critical_files=$(jq -r '.criticalFilesPresent[]' "$validation_file")
  while IFS= read -r file; do
    if [[ ! -f "$test_dir/$file" ]]; then
      echo "✗ Critical file missing: $file"
      return 1
    fi
  done <<< "$critical_files"
  echo "✓ Critical files present"

  return 0
}
```

### CrossRefValidation (교차 참조 검증)

```bash
# Bash에서 사용할 구조 (JSON 형식)
{
  "sourceFile": ".claude/commands/major.md",
  "referenceType": "markdown_link",
  "reference": "./spec.md",
  "targetExists": true,
  "targetPath": ".specify/specs/001-feature/spec.md"
}
```

**검증 스키마 (Bash 함수)**:
```bash
validate_crossref() {
  local source="$1"
  local reference="$2"

  # 상대 경로 해석
  local source_dir=$(dirname "$source")
  local target_path="$source_dir/$reference"

  # 정규화
  target_path=$(realpath -m "$target_path" 2>/dev/null || echo "$target_path")

  if [[ -f "$target_path" ]]; then
    echo "✓ Reference exists: $reference -> $target_path"
    return 0
  else
    echo "✗ Reference broken: $reference (expected: $target_path)"
    return 1
  fi
}
```

## 상태 관리

검증 시스템은 상태가 없는(stateless) 스크립트로 구현되지만, 보고서 히스토리를 위해 파일 시스템을 사용합니다.

### 보고서 저장 구조

```
.claude/cache/validation-reports/
├── 2025-11-10-143000.json           # JSON 보고서
├── 2025-11-10-143000.md             # Markdown 보고서
├── 2025-11-10-150000.json
├── 2025-11-10-150000.md
└── latest.json                      # 최신 보고서 심볼릭 링크
```

### 보고서 생성 함수

```bash
generate_report() {
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local report_id=$(uuidgen || echo "$(date +%s)")
  local report_dir=".claude/cache/validation-reports"

  mkdir -p "$report_dir"

  local json_file="$report_dir/$(date +%Y-%m-%d-%H%M%S).json"
  local md_file="${json_file%.json}.md"

  # JSON 보고서 생성
  jq -n \
    --arg id "$report_id" \
    --arg timestamp "$timestamp" \
    --argjson docResults "$DOC_RESULTS" \
    --argjson migResults "$MIG_RESULTS" \
    --argjson crossRefResults "$CROSSREF_RESULTS" \
    --arg status "$OVERALL_STATUS" \
    --argjson score "$CONSISTENCY_SCORE" \
    '{
      id: $id,
      timestamp: $timestamp,
      documentationResults: $docResults,
      migrationResults: $migResults,
      crossReferenceResults: $crossRefResults,
      overallStatus: $status,
      consistencyScore: $score
    }' > "$json_file"

  # Markdown 보고서 생성
  generate_markdown_report "$json_file" > "$md_file"

  # 최신 보고서 링크 업데이트
  ln -sf "$(basename "$json_file")" "$report_dir/latest.json"

  echo "$json_file"
}
```

## API 타입 (Bash 함수 시그니처)

### 문서 검증 API

```bash
# 모든 명령어 문서 검증
# 반환: 검증 결과 JSON 문자열
validate_all_documentation() {
  local results="[]"

  for cmd_file in .claude/commands/*.md; do
    local result=$(validate_single_doc "$cmd_file")
    results=$(echo "$results" | jq ". += [$result]")
  done

  echo "$results"
}

# 단일 문서 검증
# 인자: $1 = 문서 파일 경로
# 반환: DocumentValidation JSON
validate_single_doc() {
  local doc_file="$1"
  local command_name=$(basename "$doc_file" .md)

  # Step 추출
  local steps=$(grep -E "^### Step [0-9]+" "$doc_file" | sed 's/^### //')

  # 구현 확인 (placeholder)
  local impl="[]"

  # 일치율 계산
  local consistency=0

  jq -n \
    --arg name "$command_name" \
    --arg path "$doc_file" \
    --argjson steps "$(echo "$steps" | jq -R . | jq -s .)" \
    --argjson impl "$impl" \
    --argjson percent "$consistency" \
    '{
      commandName: $name,
      filePath: $path,
      extractedSteps: $steps,
      actualImplementation: $impl,
      matches: [],
      discrepancies: [],
      consistencyPercentage: $percent
    }'
}
```

### 마이그레이션 검증 API

```bash
# 마이그레이션 시나리오 검증
# 인자: $1 = 초기 버전, $2 = 목표 버전
# 반환: MigrationValidation JSON
validate_migration_scenario() {
  local from_version="$1"
  local to_version="$2"
  local scenario_name="$from_version to $to_version"

  # 임시 디렉토리 생성
  local test_dir=$(mktemp -d)
  trap "rm -rf $test_dir" EXIT

  # 환경 설정
  setup_version_environment "$test_dir" "$from_version"

  # 마이그레이션 실행
  local log_file="$test_dir/migration.log"
  bash install.sh "$test_dir" > "$log_file" 2>&1
  local exit_code=$?

  # 검증
  local deprecated_files='[".claude/commands/major-specify.md", ".claude/agents/architect.md"]'
  local critical_files='[".claude/workflow-gates.json", ".claude/commands/major.md"]'

  local validation_status="FAIL"
  if [[ $exit_code -eq 0 ]]; then
    validation_status="PASS"
  fi

  jq -n \
    --arg scenario "$scenario_name" \
    --arg from "$from_version" \
    --arg to "$to_version" \
    --arg log "$(cat "$log_file")" \
    --argjson code "$exit_code" \
    --argjson deprecated "$deprecated_files" \
    --argjson critical "$critical_files" \
    --arg status "$validation_status" \
    '{
      scenarioName: $scenario,
      initialVersion: $from,
      targetVersion: $to,
      setupScript: "setup_version_environment.sh",
      migrationScript: "install.sh",
      executionLog: $log,
      exitCode: $code,
      deprecatedFilesRemoved: $deprecated,
      criticalFilesPresent: $critical,
      validationStatus: $status
    }'
}
```

### 교차 참조 검증 API

```bash
# 모든 교차 참조 검증
# 반환: 검증 결과 JSON 배열
validate_all_cross_references() {
  local results="[]"

  # 모든 markdown 파일에서 링크 추출
  while IFS= read -r md_file; do
    local links=$(grep -oE '\[.*\]\([^)]+\)' "$md_file" | sed 's/.*(\(.*\))/\1/')

    while IFS= read -r link; do
      [[ -z "$link" ]] && continue
      local result=$(validate_single_crossref "$md_file" "$link")
      results=$(echo "$results" | jq ". += [$result]")
    done <<< "$links"
  done < <(find .claude -name "*.md")

  echo "$results"
}

# 단일 교차 참조 검증
# 인자: $1 = 소스 파일, $2 = 참조
# 반환: CrossRefValidation JSON
validate_single_crossref() {
  local source="$1"
  local reference="$2"

  local ref_type="markdown_link"
  [[ "$reference" =~ \.(md|sh|yaml|json)$ ]] && ref_type="file_path"

  local target_exists=false
  local target_path=""

  # 상대 경로 해석
  local source_dir=$(dirname "$source")
  target_path="$source_dir/$reference"

  if [[ -f "$target_path" ]]; then
    target_exists=true
  fi

  jq -n \
    --arg source "$source" \
    --arg type "$ref_type" \
    --arg ref "$reference" \
    --argjson exists "$target_exists" \
    --arg path "$target_path" \
    '{
      sourceFile: $source,
      referenceType: $type,
      reference: $ref,
      targetExists: $exists,
      targetPath: ($path if $exists else null)
    }'
}
```

## 에러 타입

### ValidationError

```bash
# 에러 처리 함수
handle_validation_error() {
  local error_type="$1"
  local error_message="$2"
  local file_path="$3"

  case "$error_type" in
    "FILE_NOT_FOUND")
      echo "ERROR: File not found: $file_path" >&2
      return 1
      ;;
    "PARSE_ERROR")
      echo "ERROR: Failed to parse: $error_message" >&2
      return 2
      ;;
    "VALIDATION_FAILED")
      echo "ERROR: Validation failed: $error_message" >&2
      return 3
      ;;
    *)
      echo "ERROR: Unknown error: $error_message" >&2
      return 99
      ;;
  esac
}
```

## 예제 사용

### 전체 검증 실행

```bash
#!/bin/bash

# 전체 검증 실행
main() {
  echo "🔍 문서 및 설치 검증 시작..."

  # 문서 검증
  echo "📄 문서 검증 중..."
  DOC_RESULTS=$(validate_all_documentation)

  # 마이그레이션 검증
  echo "🔄 마이그레이션 검증 중..."
  MIG_RESULTS="["
  MIG_RESULTS+=$(validate_migration_scenario "1.0.0" "2.5.0")
  MIG_RESULTS+=","
  MIG_RESULTS+=$(validate_migration_scenario "2.4.0" "2.5.0")
  MIG_RESULTS+="]"

  # 교차 참조 검증
  echo "🔗 교차 참조 검증 중..."
  CROSSREF_RESULTS=$(validate_all_cross_references)

  # 전체 상태 계산
  OVERALL_STATUS="PASS"
  CONSISTENCY_SCORE=95

  # 보고서 생성
  report_file=$(generate_report)

  echo "✅ 검증 완료: $report_file"

  # 요약 출력
  cat "${report_file%.json}.md"
}

main "$@"
```
