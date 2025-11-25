#!/bin/bash
# quick-check-serverless.sh
# Serverless Architecture Quick Check Rules
#
# Based on Serverless/FaaS principles:
# - Stateless functions
# - Event-driven architecture
# - Cold start optimization
# - Single responsibility per function
#
# Usage: bash quick-check-serverless.sh [directory]

set -euo pipefail

# ============================================================================
# Serverless 구조 정의
# ============================================================================

# Get Serverless component type (bash 3.2 compatible)
get_serverless_component() {
  local file="$1"

  if [[ "$file" =~ functions/ ]] || [[ "$file" =~ src/functions/ ]]; then
    echo "functions"
  elif [[ "$file" =~ layers/ ]] || [[ "$file" =~ src/layers/ ]]; then
    echo "layers"
  elif [[ "$file" =~ events/ ]] || [[ "$file" =~ src/events/ ]]; then
    echo "events"
  elif [[ "$file" =~ shared/ ]] || [[ "$file" =~ src/shared/ ]]; then
    echo "shared"
  elif [[ "$file" =~ infrastructure/ ]] || [[ "$file" =~ src/infrastructure/ ]]; then
    echo "infrastructure"
  else
    echo ""
  fi
}

# ============================================================================
# Statelessness 규칙
# ============================================================================

# 무상태성 검증
# Rule: Serverless functions must be completely stateless
validate_serverless_statelessness() {
  local file="$1"
  local component=$(get_serverless_component "$file")

  # functions가 아니면 스킵
  if [[ "$component" != "functions" ]]; then
    return 0
  fi

  local has_warnings=0

  # State 패턴 감지 (간단한 휴리스틱)
  local stateful_patterns=(
    "static.*="
    "global.*="
    "var.*cache.*="
    "let.*cache.*="
    "const.*cache.*="
  )

  for pattern in "${stateful_patterns[@]}"; do
    if grep -qE "$pattern" "$file" 2>/dev/null; then
      echo "⚠️  Serverless statelessness warning: Potential stateful pattern"
      echo "   File: $file"
      echo "   Pattern: $pattern"
      echo "   Rule: Functions should be stateless (no global state)"
      echo "   Note: Use external storage (DynamoDB, S3, ElastiCache) for state"
      has_warnings=1
      break
    fi
  done

  # File system write 감지 (Lambda의 /tmp는 제한적)
  if grep -qE "fs\.writeFile|fs\.writeFileSync|open\(.*'w'" "$file" 2>/dev/null; then
    echo "⚠️  Serverless statelessness warning: File system write detected"
    echo "   File: $file"
    echo "   Rule: Use S3 or EFS for persistent storage"
    has_warnings=1
  fi

  # Warning only (일부 패턴은 정상적일 수 있음)
  return 0
}

# ============================================================================
# 의존성 규칙
# ============================================================================

# Serverless 의존성 규칙 검증
# Rule: Dependencies flow outward from functions
#   - functions → layers, shared, events
#   - layers → shared
#   - events → (none)
#   - shared → (none)
validate_serverless_dependency_rule() {
  local source_file="$1"
  local import_path="$2"

  local source_component=$(get_serverless_component "$source_file")
  local target_component=$(get_serverless_component "$import_path")

  # Serverless 구조가 아니면 스킵
  if [[ -z "$source_component" || -z "$target_component" ]]; then
    return 0
  fi

  # 동일 컴포넌트 내 import는 허용
  if [[ "$source_component" == "$target_component" ]]; then
    return 0
  fi

  # 의존성 규칙 검증
  case "$source_component" in
    "functions")
      # Functions는 layers, shared, events만 import 가능
      if [[ "$target_component" != "layers" ]] && [[ "$target_component" != "shared" ]] && [[ "$target_component" != "events" ]]; then
        echo "❌ Serverless dependency violation: functions can only import layers/shared/events"
        echo "   Source: $source_file"
        echo "   Import: $import_path ($target_component)"
        echo "   Rule: functions → layers, shared, events only"
        return 1
      fi
      ;;

    "layers")
      # Layers는 shared만 import 가능
      if [[ "$target_component" == "functions" ]]; then
        echo "❌ Serverless dependency violation: layers cannot import functions"
        echo "   Source: $source_file"
        echo "   Import: $import_path"
        echo "   Rule: layers → shared only (no function dependencies)"
        return 1
      fi
      ;;

    "shared")
      # Shared는 다른 컴포넌트를 import 불가
      if [[ "$target_component" != "shared" ]]; then
        echo "❌ Serverless dependency violation: shared cannot import other components"
        echo "   Source: $source_file"
        echo "   Import: $import_path ($target_component)"
        echo "   Rule: shared must be independent"
        return 1
      fi
      ;;

    "events")
      # Events는 다른 컴포넌트를 import 불가 (schemas만)
      if [[ "$target_component" != "events" ]]; then
        echo "❌ Serverless dependency violation: events cannot import other components"
        echo "   Source: $source_file"
        echo "   Import: $import_path ($target_component)"
        echo "   Rule: events are pure schemas"
        return 1
      fi
      ;;
  esac

  return 0
}

# ============================================================================
# Cold Start 최적화 규칙
# ============================================================================

# Cold Start 최적화 검증
# Rule: Minimize cold start time by reducing dependencies
validate_serverless_cold_start() {
  local file="$1"
  local component=$(get_serverless_component "$file")

  # functions가 아니면 스킵
  if [[ "$component" != "functions" ]]; then
    return 0
  fi

  # import 개수 체크 (너무 많으면 cold start 증가)
  local import_count=$(grep -cE "^import |^from " "$file" 2>/dev/null || echo "0")

  if [[ $import_count -gt 20 ]]; then
    echo "⚠️  Serverless cold start warning: Too many imports ($import_count)"
    echo "   File: $file"
    echo "   Rule: Minimize dependencies for faster cold starts"
    echo "   Suggestion: Use lazy loading, tree shaking, or layers"
    # Warning only
  fi

  # 파일 크기 체크 (너무 크면 cold start 증가)
  if command -v wc &> /dev/null; then
    local line_count=$(wc -l < "$file" 2>/dev/null || echo "0")
    if [[ $line_count -gt 500 ]]; then
      echo "⚠️  Serverless cold start warning: Large function file ($line_count lines)"
      echo "   File: $file"
      echo "   Rule: Keep function files small and focused"
      echo "   Suggestion: Extract business logic to separate modules"
      # Warning only
    fi
  fi

  return 0
}

# ============================================================================
# Single Responsibility 규칙
# ============================================================================

# Single Responsibility 검증
# Rule: Each function should have a single, clear purpose
validate_serverless_single_responsibility() {
  local file="$1"
  local component=$(get_serverless_component "$file")

  # functions가 아니면 스킵
  if [[ "$component" != "functions" ]]; then
    return 0
  fi

  # Handler 함수가 너무 길면 단일 책임 위반 가능성
  # handler, main, exports 등의 함수 길이 체크 (간단한 휴리스틱)

  # handler 함수 찾기
  if grep -qE "(export.*handler|exports\.handler|def handler|func handler)" "$file" 2>/dev/null; then
    # handler 함수 이후 줄 수 체크 (대략적)
    local handler_line=$(grep -nE "(export.*handler|exports\.handler|def handler|func handler)" "$file" 2>/dev/null | head -1 | cut -d: -f1)

    if [[ -n "$handler_line" ]]; then
      local total_lines=$(wc -l < "$file" 2>/dev/null || echo "0")
      local handler_length=$((total_lines - handler_line))

      if [[ $handler_length -gt 100 ]]; then
        echo "⚠️  Serverless single responsibility warning: Large handler function"
        echo "   File: $file"
        echo "   Handler size: ~$handler_length lines"
        echo "   Rule: Keep handler thin, delegate to business logic modules"
        echo "   Suggestion: Extract logic to separate functions/modules"
        # Warning only
      fi
    fi
  fi

  return 0
}

# ============================================================================
# Error Handling 규칙
# ============================================================================

# Error Handling 검증
# Rule: Functions should have proper error handling
validate_serverless_error_handling() {
  local file="$1"
  local component=$(get_serverless_component "$file")

  # functions가 아니면 스킵
  if [[ "$component" != "functions" ]]; then
    return 0
  fi

  # try-catch 또는 error handling 체크
  if ! grep -qE "try\s*\{|catch|except|rescue|recover" "$file" 2>/dev/null; then
    echo "⚠️  Serverless error handling warning: No error handling detected"
    echo "   File: $file"
    echo "   Rule: Implement proper error handling and logging"
    echo "   Suggestion: Use try-catch blocks and log errors"
    # Warning only (일부 간단한 함수는 불필요)
  fi

  return 0
}

# ============================================================================
# Timeout Awareness 규칙
# ============================================================================

# Timeout Awareness 검증
# Rule: Functions should be aware of execution time limits
validate_serverless_timeout_awareness() {
  local file="$1"
  local component=$(get_serverless_component "$file")

  # functions가 아니면 스킵
  if [[ "$component" != "functions" ]]; then
    return 0
  fi

  # 무한 루프 또는 long-running 패턴 체크
  if grep -qE "while\s*\(\s*true|while\s+True|loop\s*\{" "$file" 2>/dev/null; then
    echo "⚠️  Serverless timeout warning: Infinite loop pattern detected"
    echo "   File: $file"
    echo "   Rule: Be aware of function timeout limits"
    echo "   Suggestion: Use step functions for long-running workflows"
    # Warning only
  fi

  # sleep/delay 패턴 (polling은 serverless에 비효율적)
  if grep -qE "sleep\(|setTimeout\(|time\.sleep|delay\(" "$file" 2>/dev/null; then
    echo "⚠️  Serverless timeout warning: Sleep/delay detected"
    echo "   File: $file"
    echo "   Rule: Avoid polling, use event-driven patterns"
    echo "   Suggestion: Use SQS, SNS, or EventBridge for delays"
    # Warning only
  fi

  return 0
}

# ============================================================================
# 메인 검증 함수
# ============================================================================

# Serverless Architecture 파일 검증 (모든 규칙 통합)
validate_serverless_file() {
  local file="$1"

  # 파일 존재 확인
  if [[ ! -f "$file" ]]; then
    echo "File not found: $file"
    return 1
  fi

  # Serverless 구조가 아니면 스킵
  local component=$(get_serverless_component "$file")
  if [[ -z "$component" ]]; then
    return 0
  fi

  local has_errors=0

  # 1. Statelessness 검증
  if ! validate_serverless_statelessness "$file"; then
    # warnings only
    :
  fi

  # 2. Cold Start 최적화 검증
  if ! validate_serverless_cold_start "$file"; then
    # warnings only
    :
  fi

  # 3. Single Responsibility 검증
  if ! validate_serverless_single_responsibility "$file"; then
    # warnings only
    :
  fi

  # 4. Error Handling 검증
  if ! validate_serverless_error_handling "$file"; then
    # warnings only
    :
  fi

  # 5. Timeout Awareness 검증
  if ! validate_serverless_timeout_awareness "$file"; then
    # warnings only
    :
  fi

  # 6. import 문 추출 및 의존성 검증
  local import_lines=$(grep -E "^import |^from " "$file" 2>/dev/null || true)

  while IFS= read -r import_line; do
    if [[ -z "$import_line" ]]; then
      continue
    fi

    # import 경로 추출
    local import_path=""
    if [[ "$import_line" =~ from[[:space:]]+[\'\"](.*)[\'\"] ]] || [[ "$import_line" =~ import[[:space:]]+[\'\"](.*)[\'\"] ]]; then
      import_path="${BASH_REMATCH[1]}"
    else
      continue
    fi

    # 외부 패키지는 스킵 (AWS SDK 등은 허용)
    if [[ ! "$import_path" =~ ^\.\.?/ ]] && [[ ! "$import_path" =~ ^src/ ]] && [[ ! "$import_path" =~ ^@/ ]]; then
      continue
    fi

    # 상대 경로를 프로젝트 경로로 변환
    local resolved_import=""
    if [[ "$import_path" =~ ^@/ ]]; then
      resolved_import="${import_path#@/}"
      resolved_import="src/$resolved_import"
    elif [[ "$import_path" =~ ^\.\.?/ ]]; then
      local source_dir=$(dirname "$file")
      resolved_import="${source_dir}/${import_path}"
      if command -v realpath &> /dev/null; then
        resolved_import=$(realpath -m "$resolved_import" 2>/dev/null || echo "$resolved_import")
      fi
    else
      resolved_import="$import_path"
    fi

    # 의존성 규칙 검증
    if ! validate_serverless_dependency_rule "$file" "$resolved_import"; then
      has_errors=1
    fi

  done <<< "$import_lines"

  if [[ $has_errors -eq 0 ]]; then
    return 0
  else
    return 1
  fi
}

# ============================================================================
# 배치 검증
# ============================================================================

# 디렉토리 내 모든 Serverless Architecture 파일 검증
validate_serverless_directory() {
  local root_dir="${1:-src}"

  if [[ ! -d "$root_dir" ]]; then
    echo "Directory not found: $root_dir"
    return 1
  fi

  local total_files=0
  local passed_files=0
  local failed_files=0

  echo "Validating Serverless Architecture (FaaS) in: $root_dir"
  echo ""

  # Serverless 구조별로 파일 검색
  for component in functions layers events shared infrastructure; do
    local component_dir="${root_dir}/${component}"
    if [[ ! -d "$component_dir" ]]; then
      continue
    fi

    while IFS= read -r file; do
      if [[ -f "$file" ]]; then
        total_files=$((total_files + 1))

        if validate_serverless_file "$file"; then
          passed_files=$((passed_files + 1))
        else
          failed_files=$((failed_files + 1))
          echo ""
        fi
      fi
    done < <(find "$component_dir" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.go" -o -name "*.java" -o -name "*.cs" \) 2>/dev/null)
  done

  echo ""
  echo "=========================================="
  echo "Serverless Architecture Validation Summary"
  echo "=========================================="
  echo "Total files: $total_files"
  echo "Passed: $passed_files"
  echo "Failed: $failed_files"
  echo ""

  if [[ $failed_files -eq 0 ]]; then
    echo "✓ All Serverless Architecture rules validated successfully"
    return 0
  else
    echo "✗ $failed_files file(s) failed Serverless Architecture validation"
    return 1
  fi
}

# Note: This module is designed to be sourced by other scripts
# Based on AWS Lambda and Serverless Architecture best practices
