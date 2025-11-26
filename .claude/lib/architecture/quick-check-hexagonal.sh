#!/bin/bash
# quick-check-hexagonal.sh
# Hexagonal Architecture (Ports and Adapters) Quick Check Rules
#
# Based on Hexagonal Architecture principles:
# - Core independence: Core has no dependencies on adapters
# - Ports abstraction: All external communication through ports
# - Adapter implementation: Adapters implement port interfaces
#
# Usage: bash quick-check-hexagonal.sh [directory]

set -euo pipefail

# ============================================================================
# Hexagonal Architecture 구조 정의
# ============================================================================

# Get Hexagonal Architecture component type (bash 3.2 compatible)
get_hexagonal_component() {
  local file="$1"

  # core/domain
  if [[ "$file" =~ core/domain/ ]] || [[ "$file" =~ src/core/domain/ ]]; then
    echo "core/domain"
  # core/ports
  elif [[ "$file" =~ core/ports/ ]] || [[ "$file" =~ src/core/ports/ ]]; then
    echo "core/ports"
  # core (general)
  elif [[ "$file" =~ core/ ]] || [[ "$file" =~ src/core/ ]]; then
    echo "core"
  # adapters/inbound
  elif [[ "$file" =~ adapters/inbound/ ]] || [[ "$file" =~ src/adapters/inbound/ ]]; then
    echo "adapters/inbound"
  # adapters/outbound
  elif [[ "$file" =~ adapters/outbound/ ]] || [[ "$file" =~ src/adapters/outbound/ ]]; then
    echo "adapters/outbound"
  # adapters (general)
  elif [[ "$file" =~ adapters/ ]] || [[ "$file" =~ src/adapters/ ]]; then
    echo "adapters"
  else
    echo ""
  fi
}

# ============================================================================
# 유틸리티 함수
# ============================================================================

# Framework/library blacklist for core
is_framework_import() {
  local import_path="$1"

  # 프레임워크/라이브러리 패턴
  local framework_patterns=(
    "express"
    "fastify"
    "koa"
    "axios"
    "node-fetch"
    "typeorm"
    "mongoose"
    "prisma"
    "sequelize"
    "redis"
    "mysql"
    "pg"
    "mongodb"
    "amqp"
    "kafka"
  )

  for pattern in "${framework_patterns[@]}"; do
    if [[ "$import_path" =~ $pattern ]]; then
      return 0
    fi
  done

  return 1
}

# ============================================================================
# Core 독립성 규칙 (가장 중요)
# ============================================================================

# Core 독립성 검증
# Rule: Core must NOT depend on adapters or frameworks
validate_hexagonal_core_independence() {
  local file="$1"
  local component=$(get_hexagonal_component "$file")

  # core가 아니면 스킵
  if [[ ! "$component" =~ ^core ]]; then
    return 0
  fi

  local has_errors=0

  # import 문 추출
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

    # adapters import 체크 (절대 금지)
    if [[ "$import_path" =~ adapters/ ]] || [[ "$import_path" =~ /adapters/ ]]; then
      echo "❌ Hexagonal core violation: Core cannot import adapters"
      echo "   File: $file"
      echo "   Import: $import_path"
      echo "   Rule: Core must be completely independent of adapters"
      has_errors=1
      continue
    fi

    # 외부 패키지는 framework check
    if [[ ! "$import_path" =~ ^\.\.?/ ]] && [[ ! "$import_path" =~ ^src/ ]] && [[ ! "$import_path" =~ ^@/ ]]; then
      if is_framework_import "$import_path"; then
        echo "❌ Hexagonal core purity violation: Framework dependency detected"
        echo "   File: $file"
        echo "   Import: $import_path"
        echo "   Rule: Core must not depend on frameworks"
        has_errors=1
      fi
    fi

  done <<< "$import_lines"

  if [[ $has_errors -eq 0 ]]; then
    return 0
  else
    return 1
  fi
}

# ============================================================================
# Domain 순수성 규칙
# ============================================================================

# Core/Domain 순수성 검증
# Rule: Domain is the innermost layer - no dependencies at all
validate_hexagonal_domain_purity() {
  local file="$1"
  local component=$(get_hexagonal_component "$file")

  # core/domain이 아니면 스킵
  if [[ "$component" != "core/domain" ]]; then
    return 0
  fi

  local has_errors=0

  # import 문 추출
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

    # core/ports import 금지
    if [[ "$import_path" =~ core/ports ]] || [[ "$import_path" =~ /ports/ ]]; then
      echo "⚠️  Hexagonal domain warning: Domain importing ports"
      echo "   File: $file"
      echo "   Import: $import_path"
      echo "   Rule: Domain should be pure business logic (no port dependencies)"
      # Warning only (some patterns allow minimal coupling)
    fi

    # adapters import 체크 (절대 금지)
    if [[ "$import_path" =~ adapters/ ]] || [[ "$import_path" =~ /adapters/ ]]; then
      echo "❌ Hexagonal domain violation: Domain cannot import adapters"
      echo "   File: $file"
      echo "   Import: $import_path"
      echo "   Rule: Domain must be completely independent"
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
# Ports 규칙
# ============================================================================

# Ports 규칙 검증
# Rule: Ports can only import from core/domain
validate_hexagonal_ports_rules() {
  local file="$1"
  local component=$(get_hexagonal_component "$file")

  # core/ports가 아니면 스킵
  if [[ "$component" != "core/ports" ]]; then
    return 0
  fi

  local has_errors=0

  # import 문 추출
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

    # adapters import 금지
    if [[ "$import_path" =~ adapters/ ]] || [[ "$import_path" =~ /adapters/ ]]; then
      echo "❌ Hexagonal ports violation: Ports cannot import adapters"
      echo "   File: $file"
      echo "   Import: $import_path"
      echo "   Rule: Ports define abstractions, not implementations"
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
# Adapters 규칙
# ============================================================================

# Adapters 규칙 검증
# Rule: Adapters must implement ports
validate_hexagonal_adapter_rules() {
  local file="$1"
  local component=$(get_hexagonal_component "$file")

  # adapters가 아니면 스킵
  if [[ ! "$component" =~ ^adapters ]]; then
    return 0
  fi

  # Adapter 파일은 port를 import해야 함
  if ! grep -qE "from .*(core/ports|/ports/)" "$file" 2>/dev/null; then
    echo "⚠️  Hexagonal adapter warning: Adapter should import port interface"
    echo "   File: $file"
    echo "   Rule: Adapters implement port interfaces"
    # Warning only (일부 파일은 helper일 수 있음)
  fi

  # Adapter는 interface 구현 또는 class 정의가 있어야 함
  if ! grep -qE "implements |extends |class " "$file" 2>/dev/null; then
    echo "⚠️  Hexagonal adapter warning: Adapter should implement or extend"
    echo "   File: $file"
    echo "   Rule: Adapters implement port interfaces"
    # Warning only
  fi

  return 0
}

# ============================================================================
# 의존성 방향 규칙
# ============================================================================

# Hexagonal 의존성 방향 검증
# Rule: Dependencies point inward (adapters → ports → domain)
validate_hexagonal_dependency_direction() {
  local source_file="$1"
  local import_path="$2"

  local source_component=$(get_hexagonal_component "$source_file")
  local target_component=$(get_hexagonal_component "$import_path")

  # Hexagonal 구조가 아니면 스킵
  if [[ -z "$source_component" || -z "$target_component" ]]; then
    return 0
  fi

  # 동일 컴포넌트 내 import는 허용
  if [[ "$source_component" == "$target_component" ]]; then
    return 0
  fi

  # 의존성 규칙 검증
  case "$source_component" in
    "core/domain")
      # Domain은 아무것도 import 불가 (이미 domain_purity에서 체크)
      return 0
      ;;

    "core/ports")
      # Ports는 core/domain만 import 가능
      if [[ "$target_component" != "core/domain" ]]; then
        echo "❌ Hexagonal dependency violation: ports can only import domain"
        echo "   Source: $source_file"
        echo "   Import: $import_path ($target_component)"
        echo "   Rule: core/ports → core/domain only"
        return 1
      fi
      ;;

    "core")
      # Core는 adapters import 불가 (이미 core_independence에서 체크)
      return 0
      ;;

    "adapters/inbound"|"adapters/outbound"|"adapters")
      # Adapters는 core만 import 가능 (adapters끼리는 금지 - 분리되어야 함)
      if [[ "$target_component" =~ ^adapters ]]; then
        echo "⚠️  Hexagonal adapter coupling warning: Adapter importing another adapter"
        echo "   Source: $source_file ($source_component)"
        echo "   Import: $import_path ($target_component)"
        echo "   Rule: Adapters should be independent (communicate through ports)"
        # Warning only
      fi

      # Core가 아닌 것을 import하면 에러
      if [[ ! "$target_component" =~ ^core ]]; then
        echo "❌ Hexagonal dependency violation: adapter can only import core"
        echo "   Source: $source_file"
        echo "   Import: $import_path ($target_component)"
        echo "   Rule: adapters → core only"
        return 1
      fi
      ;;
  esac

  return 0
}

# ============================================================================
# Port 명명 규칙 검증
# ============================================================================

# Port 명명 규칙 검증
# Convention: I${Name}Port (예: IUserRepositoryPort)
validate_hexagonal_port_naming() {
  local file="$1"
  local component=$(get_hexagonal_component "$file")

  # core/ports가 아니면 스킵
  if [[ "$component" != "core/ports" ]]; then
    return 0
  fi

  local filename=$(basename "$file")

  # Port 파일 명명 규칙 체크 (엄격하지 않게, warning만)
  if [[ ! "$filename" =~ Port\. ]] && [[ ! "$filename" =~ port\. ]]; then
    echo "⚠️  Hexagonal naming warning: Port file should include 'Port' in name"
    echo "   File: $file"
    echo "   Suggestion: Use naming like IUserRepositoryPort or UserServicePort"
    # Warning only
  fi

  return 0
}

# ============================================================================
# 메인 검증 함수
# ============================================================================

# Hexagonal Architecture 파일 검증 (모든 규칙 통합)
validate_hexagonal_file() {
  local file="$1"

  # 파일 존재 확인
  if [[ ! -f "$file" ]]; then
    echo "File not found: $file"
    return 1
  fi

  # Hexagonal Architecture 구조가 아니면 스킵
  local component=$(get_hexagonal_component "$file")
  if [[ -z "$component" ]]; then
    return 0
  fi

  local has_errors=0

  # 1. Core 독립성 검증 (최우선)
  if ! validate_hexagonal_core_independence "$file"; then
    has_errors=1
  fi

  # 2. Domain 순수성 검증
  if ! validate_hexagonal_domain_purity "$file"; then
    has_errors=1
  fi

  # 3. Ports 규칙 검증
  if ! validate_hexagonal_ports_rules "$file"; then
    has_errors=1
  fi

  # 4. Adapters 규칙 검증
  if ! validate_hexagonal_adapter_rules "$file"; then
    # warnings only
    :
  fi

  # 5. Port 명명 규칙 검증
  if ! validate_hexagonal_port_naming "$file"; then
    # warnings only
    :
  fi

  # 6. import 문 추출 및 의존성 방향 검증
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

    # 외부 패키지는 core independence에서 체크했으므로 스킵
    if [[ ! "$import_path" =~ ^\.\.?/ ]] && [[ ! "$import_path" =~ ^src/ ]] && [[ ! "$import_path" =~ ^@/ ]]; then
      continue
    fi

    # 상대 경로를 프로젝트 경로로 변환
    local resolved_import=""
    if [[ "$import_path" =~ ^@/ ]]; then
      # Alias import (@/...)
      resolved_import="${import_path#@/}"
      resolved_import="src/$resolved_import"
    elif [[ "$import_path" =~ ^\.\.?/ ]]; then
      # 상대 경로
      local source_dir=$(dirname "$file")
      resolved_import="${source_dir}/${import_path}"
      # realpath가 없으면 간단히 경로만 사용
      if command -v realpath &> /dev/null; then
        resolved_import=$(realpath -m "$resolved_import" 2>/dev/null || echo "$resolved_import")
      fi
    else
      # 절대 경로
      resolved_import="$import_path"
    fi

    # 의존성 방향 검증
    if ! validate_hexagonal_dependency_direction "$file" "$resolved_import"; then
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

# 디렉토리 내 모든 Hexagonal Architecture 파일 검증
validate_hexagonal_directory() {
  local root_dir="${1:-src}"

  if [[ ! -d "$root_dir" ]]; then
    echo "Directory not found: $root_dir"
    return 1
  fi

  local total_files=0
  local passed_files=0
  local failed_files=0

  echo "Validating Hexagonal Architecture (Ports and Adapters) in: $root_dir"
  echo ""

  # Hexagonal 구조별로 파일 검색
  for component in core/domain core/ports core adapters/inbound adapters/outbound adapters; do
    local component_dir="${root_dir}/${component}"
    if [[ ! -d "$component_dir" ]]; then
      continue
    fi

    while IFS= read -r file; do
      if [[ -f "$file" ]]; then
        total_files=$((total_files + 1))

        if validate_hexagonal_file "$file"; then
          passed_files=$((passed_files + 1))
        else
          failed_files=$((failed_files + 1))
          echo ""
        fi
      fi
    done < <(find "$component_dir" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.java" -o -name "*.go" \) 2>/dev/null)
  done

  echo ""
  echo "=========================================="
  echo "Hexagonal Architecture Validation Summary"
  echo "=========================================="
  echo "Total files: $total_files"
  echo "Passed: $passed_files"
  echo "Failed: $failed_files"
  echo ""

  if [[ $failed_files -eq 0 ]]; then
    echo "✓ All Hexagonal Architecture rules validated successfully"
    return 0
  else
    echo "✗ $failed_files file(s) failed Hexagonal Architecture validation"
    return 1
  fi
}

# Note: This module is designed to be sourced by other scripts
# Based on Hexagonal Architecture (Ports and Adapters) by Alistair Cockburn
