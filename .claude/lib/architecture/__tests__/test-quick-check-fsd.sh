#!/bin/bash
# test-quick-check-fsd.sh
# FSD Quick Check 통합 테스트
#
# Usage: bash test-quick-check-fsd.sh

set -euo pipefail

# ============================================================================
# 설정
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")"

# Source dependencies
source "${LIB_DIR}/../common.sh"

# 테스트 결과
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 테스트용 임시 디렉토리
TEST_DIR=$(mktemp -d)
TEST_PROJECT="${TEST_DIR}/test-fsd-project"

# ============================================================================
# 테스트 헬퍼
# ============================================================================

test_assert() {
  local test_name="$1"
  local command="$2"
  local expected_exit_code="${3:-0}"

  TOTAL_TESTS=$((TOTAL_TESTS + 1))

  echo -n "  Testing: $test_name ... "

  set +e
  eval "$command" > /dev/null 2>&1
  local actual_exit_code=$?
  set -e

  if [[ "$actual_exit_code" == "$expected_exit_code" ]]; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
  else
    echo -e "${RED}✗ FAIL${NC} (expected: $expected_exit_code, got: $actual_exit_code)"
    FAILED_TESTS=$((FAILED_TESTS + 1))
  fi
}

# ============================================================================
# 테스트 프로젝트 설정
# ============================================================================

setup_fsd_project() {
  mkdir -p "$TEST_PROJECT/src"
  cd "$TEST_PROJECT"

  # FSD 구조 생성
  mkdir -p src/{app,pages,features,entities,shared}
  mkdir -p src/entities/{user,order}
  mkdir -p src/features/{auth,payment}
  mkdir -p src/pages/home

  log_success "FSD test project created: $TEST_PROJECT"
}

# ============================================================================
# 테스트 케이스 생성
# ============================================================================

# 1. Valid FSD 파일 생성
create_valid_fsd_files() {
  # Valid entity
  cat > src/entities/user/model.ts <<'EOF'
export interface User {
  id: string;
  name: string;
  email: string;
}

export const getUser = (id: string): User => {
  return { id, name: 'Test', email: 'test@example.com' };
};
EOF

  # Valid feature
  cat > src/features/auth/service.ts <<'EOF'
import type { User } from '@/entities/user';

export const login = (email: string): User => {
  return { id: '1', name: 'Test', email };
};
EOF

  # Valid page
  cat > src/pages/home/index.ts <<'EOF'
import { login } from '@/features/auth/service';

export const HomePage = () => {
  const user = login('test@example.com');
  return user;
};
EOF

  log_success "Valid FSD files created"
}

# 2. Layer violation 파일 생성
create_layer_violation_files() {
  # entities importing features (하위 레이어가 상위 레이어 import)
  cat > src/entities/order/model.ts <<'EOF'
import { payment } from '@/features/payment/service';

export const createOrder = () => {
  return payment();
};
EOF

  log_success "Layer violation files created"
}

# 3. Feature-to-feature runtime import (금지)
create_feature_import_violation() {
  cat > src/features/payment/service.ts <<'EOF'
import { login } from '@/features/auth/service';

export const payment = () => {
  login('test@example.com');
};
EOF

  log_success "Feature-to-feature violation files created"
}

# 4. Entity purity violation (React hooks)
create_entity_purity_violation() {
  cat > src/entities/user/component.tsx <<'EOF'
import { useState } from 'react';

export const UserCard = () => {
  const [user, setUser] = useState(null);
  return <div>{user}</div>;
};
EOF

  log_success "Entity purity violation files created"
}

# 5. Shared purity violation (domain keywords)
create_shared_purity_violation() {
  cat > src/shared/lib/orderUtils.ts <<'EOF'
export const formatOrder = (order: any) => {
  return order.toString();
};
EOF

  log_success "Shared purity violation files created"
}

# ============================================================================
# 테스트 실행
# ============================================================================

run_tests() {
  log_info "Starting FSD Quick Check tests..."
  echo ""

  # Quick Check 스크립트 source
  source "${LIB_DIR}/quick-check-fsd.sh"

  # 테스트 프로젝트 설정
  setup_fsd_project

  # ============================================================================
  # 1. Valid Files Tests
  # ============================================================================

  echo -e "${BLUE}1. Valid FSD Files Tests${NC}"

  create_valid_fsd_files

  test_assert \
    "Valid entity passes" \
    "validate_fsd_file 'src/entities/user/model.ts'" \
    0

  test_assert \
    "Valid feature passes" \
    "validate_fsd_file 'src/features/auth/service.ts'" \
    0

  test_assert \
    "Valid page passes" \
    "validate_fsd_file 'src/pages/home/index.ts'" \
    0

  echo ""

  # ============================================================================
  # 2. Layer Dependency Violation Tests
  # ============================================================================

  echo -e "${BLUE}2. Layer Dependency Violation Tests${NC}"

  create_layer_violation_files

  test_assert \
    "Entity importing feature fails" \
    "validate_fsd_file 'src/entities/order/model.ts'" \
    1

  echo ""

  # ============================================================================
  # 3. Feature-to-Feature Import Tests
  # ============================================================================

  echo -e "${BLUE}3. Feature-to-Feature Import Tests${NC}"

  create_feature_import_violation

  test_assert \
    "Feature runtime import fails" \
    "validate_fsd_file 'src/features/payment/service.ts'" \
    1

  # Type-only import는 허용
  cat > src/features/payment/types.ts <<'EOF'
import type { User } from '@/features/auth/service';

export type Payment = {
  user: User;
};
EOF

  test_assert \
    "Feature type-only import passes" \
    "validate_fsd_file 'src/features/payment/types.ts'" \
    0

  echo ""

  # ============================================================================
  # 4. Entity Purity Tests
  # ============================================================================

  echo -e "${BLUE}4. Entity Purity Tests${NC}"

  create_entity_purity_violation

  test_assert \
    "Entity with React hooks fails" \
    "validate_fsd_file 'src/entities/user/component.tsx'" \
    1

  # Mutation API
  cat > src/entities/order/api.ts <<'EOF'
export const createOrder = () => {
  fetch('/api/orders', { method: 'POST' });
};
EOF

  test_assert \
    "Entity with POST fails" \
    "validate_fsd_file 'src/entities/order/api.ts'" \
    1

  echo ""

  # ============================================================================
  # 5. Shared Purity Tests
  # ============================================================================

  echo -e "${BLUE}5. Shared Purity Tests${NC}"

  create_shared_purity_violation

  test_assert \
    "Shared with domain keyword fails" \
    "validate_fsd_file 'src/shared/lib/orderUtils.ts'" \
    1

  # Generic utility는 통과
  cat > src/shared/lib/formatters.ts <<'EOF'
export const formatCurrency = (amount: number) => {
  return `$${amount.toFixed(2)}`;
};
EOF

  test_assert \
    "Shared generic utility passes" \
    "validate_fsd_file 'src/shared/lib/formatters.ts'" \
    0

  echo ""

  # ============================================================================
  # 6. Directory Validation Tests
  # ============================================================================

  echo -e "${BLUE}6. Directory Validation Tests${NC}"

  test_assert \
    "Directory validation detects violations" \
    "validate_fsd_directory 'src'" \
    1

  echo ""

  # ============================================================================
  # 테스트 결과 요약
  # ============================================================================

  echo ""
  echo "=========================================="
  echo "Test Results Summary"
  echo "=========================================="
  echo "Total tests: $TOTAL_TESTS"
  echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
  echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
  echo ""

  if [[ "$FAILED_TESTS" -eq 0 ]]; then
    log_success "All tests passed! ✅"
    return 0
  else
    log_error "$FAILED_TESTS test(s) failed"
    return 1
  fi
}

# ============================================================================
# 정리
# ============================================================================

cleanup() {
  rm -rf "$TEST_DIR"
}

trap cleanup EXIT

# ============================================================================
# 메인
# ============================================================================

main() {
  echo ""
  echo "=========================================="
  echo "FSD Quick Check Integration Tests"
  echo "=========================================="
  echo ""

  run_tests
  local result=$?

  if [[ "$result" -eq 0 ]]; then
    log_success "FSD Quick Check tests completed successfully! 🎉"
    exit 0
  else
    log_error "FSD Quick Check tests failed"
    exit 1
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
