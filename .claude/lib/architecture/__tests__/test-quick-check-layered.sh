#!/bin/bash
# test-quick-check-layered.sh
# Layered Architecture Quick Check 통합 테스트
#
# Usage: bash test-quick-check-layered.sh

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
TEST_PROJECT="${TEST_DIR}/test-layered-project"

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

setup_layered_project() {
  mkdir -p "$TEST_PROJECT/src"
  cd "$TEST_PROJECT"

  # Layered Architecture 구조 생성
  mkdir -p src/{presentation,business,data,common}
  mkdir -p src/presentation/controllers
  mkdir -p src/business/services
  mkdir -p src/data/repositories
  mkdir -p src/common/utils

  log_success "Layered Architecture test project created: $TEST_PROJECT"
}

# ============================================================================
# 테스트 케이스 생성
# ============================================================================

# 1. Valid Layered 파일 생성
create_valid_layered_files() {
  # Valid common utility
  cat > src/common/utils/logger.ts <<'EOF'
export class Logger {
  log(message: string): void {
    console.log(`[LOG] ${message}`);
  }
}
EOF

  # Valid data repository
  cat > src/data/repositories/UserRepository.ts <<'EOF'
import { Logger } from '@/common/utils/logger';

export class UserRepository {
  private logger = new Logger();

  async findById(id: string): Promise<any> {
    this.logger.log(`Finding user ${id}`);
    return { id, name: 'Test User' };
  }
}
EOF

  # Valid business service
  cat > src/business/services/UserService.ts <<'EOF'
import { UserRepository } from '@/data/repositories/UserRepository';
import { Logger } from '@/common/utils/logger';

export class UserService {
  constructor(
    private userRepository: UserRepository,
    private logger: Logger
  ) {}

  async getUser(id: string): Promise<any> {
    this.logger.log(`Getting user ${id}`);
    return await this.userRepository.findById(id);
  }
}
EOF

  # Valid presentation controller
  cat > src/presentation/controllers/UserController.ts <<'EOF'
import { UserService } from '@/business/services/UserService';

export class UserController {
  constructor(private userService: UserService) {}

  async handleGetUser(req: any, res: any): Promise<void> {
    const user = await this.userService.getUser(req.params.id);
    res.json(user);
  }
}
EOF

  log_success "Valid Layered files created"
}

# 2. Upward dependency violations
create_upward_violations() {
  # Data importing business (금지)
  cat > src/data/repositories/OrderRepository.ts <<'EOF'
import { UserService } from '@/business/services/UserService';

export class OrderRepository {
  constructor(private service: UserService) {}
}
EOF

  # Data importing presentation (금지)
  cat > src/data/repositories/ProductRepository.ts <<'EOF'
import { UserController } from '@/presentation/controllers/UserController';

export class ProductRepository {
  constructor(private controller: UserController) {}
}
EOF

  # Business importing presentation (금지)
  cat > src/business/services/OrderService.ts <<'EOF'
import { UserController } from '@/presentation/controllers/UserController';

export class OrderService {
  constructor(private controller: UserController) {}
}
EOF

  # Common importing any layer (금지)
  cat > src/common/utils/helpers.ts <<'EOF'
import { UserService } from '@/business/services/UserService';

export const getService = () => new UserService();
EOF

  log_success "Upward dependency violation files created"
}

# 3. Presentation skip violation
create_presentation_skip_violations() {
  # Presentation importing data directly (should use business)
  cat > src/presentation/controllers/OrderController.ts <<'EOF'
import { UserRepository } from '@/data/repositories/UserRepository';

export class OrderController {
  constructor(private repo: UserRepository) {}

  async getUser(id: string) {
    return await this.repo.findById(id);
  }
}
EOF

  log_success "Presentation skip violation files created"
}

# 4. Data abstraction violations
create_data_abstraction_violations() {
  # Business importing database library directly
  cat > src/business/services/ProductService.ts <<'EOF'
import { Connection } from 'typeorm';
import { MongoClient } from 'mongodb';

export class ProductService {
  constructor(
    private db: Connection,
    private mongo: MongoClient
  ) {}
}
EOF

  log_success "Data abstraction violation files created"
}

# 5. Layer responsibility violations
create_responsibility_violations() {
  # Presentation with too much business logic
  cat > src/presentation/controllers/ComplexController.ts <<'EOF'
export class ComplexController {
  handleRequest(req: any, res: any) {
    if (req.user.role === 'admin') {
      if (req.body.amount > 1000) {
        if (req.body.currency === 'USD') {
          if (req.user.verified) {
            // Too much logic in controller
          }
        }
      }
    }
    res.json({ ok: true });
  }
}
EOF

  # Business importing HTTP framework
  cat > src/business/services/WebService.ts <<'EOF'
import { Request, Response } from 'express';

export class WebService {
  handleRequest(req: Request, res: Response) {
    res.json({ ok: true });
  }
}
EOF

  log_success "Layer responsibility violation files created"
}

# ============================================================================
# 테스트 실행
# ============================================================================

run_tests() {
  log_info "Starting Layered Architecture Quick Check tests..."
  echo ""

  # Quick Check 스크립트 source
  source "${LIB_DIR}/quick-check-layered.sh"

  # 테스트 프로젝트 설정
  setup_layered_project

  # ============================================================================
  # 1. Valid Files Tests
  # ============================================================================

  echo -e "${BLUE}1. Valid Layered Architecture Files Tests${NC}"

  create_valid_layered_files

  test_assert \
    "Valid common utility passes" \
    "validate_layered_file 'src/common/utils/logger.ts'" \
    0

  test_assert \
    "Valid data repository passes" \
    "validate_layered_file 'src/data/repositories/UserRepository.ts'" \
    0

  test_assert \
    "Valid business service passes" \
    "validate_layered_file 'src/business/services/UserService.ts'" \
    0

  test_assert \
    "Valid presentation controller passes" \
    "validate_layered_file 'src/presentation/controllers/UserController.ts'" \
    0

  echo ""

  # ============================================================================
  # 2. Upward Dependency Violation Tests
  # ============================================================================

  echo -e "${BLUE}2. Upward Dependency Violation Tests${NC}"

  create_upward_violations

  test_assert \
    "Data importing business fails" \
    "validate_layered_file 'src/data/repositories/OrderRepository.ts'" \
    1

  test_assert \
    "Data importing presentation fails" \
    "validate_layered_file 'src/data/repositories/ProductRepository.ts'" \
    1

  test_assert \
    "Business importing presentation fails" \
    "validate_layered_file 'src/business/services/OrderService.ts'" \
    1

  test_assert \
    "Common importing business fails" \
    "validate_layered_file 'src/common/utils/helpers.ts'" \
    1

  echo ""

  # ============================================================================
  # 3. Presentation Skip Violation Tests
  # ============================================================================

  echo -e "${BLUE}3. Presentation Skip Violation Tests${NC}"

  create_presentation_skip_violations

  test_assert \
    "Presentation importing data directly fails" \
    "validate_layered_file 'src/presentation/controllers/OrderController.ts'" \
    1

  echo ""

  # ============================================================================
  # 4. Data Abstraction Violation Tests
  # ============================================================================

  echo -e "${BLUE}4. Data Abstraction Violation Tests${NC}"

  create_data_abstraction_violations

  test_assert \
    "Business importing database library fails" \
    "validate_layered_file 'src/business/services/ProductService.ts'" \
    1

  echo ""

  # ============================================================================
  # 5. Layer Responsibility Tests (warnings)
  # ============================================================================

  echo -e "${BLUE}5. Layer Responsibility Tests (warnings)${NC}"

  create_responsibility_violations

  test_assert \
    "Presentation with complex logic shows warnings but passes" \
    "validate_layered_file 'src/presentation/controllers/ComplexController.ts'" \
    0

  test_assert \
    "Business with HTTP framework shows warnings but passes" \
    "validate_layered_file 'src/business/services/WebService.ts'" \
    0

  echo ""

  # ============================================================================
  # 6. Common Layer Tests
  # ============================================================================

  echo -e "${BLUE}6. Common Layer (Cross-cutting) Tests${NC}"

  # Common can be imported from any layer
  cat > src/presentation/controllers/LoggingController.ts <<'EOF'
import { Logger } from '@/common/utils/logger';

export class LoggingController {
  private logger = new Logger();

  handleRequest() {
    this.logger.log('Request handled');
  }
}
EOF

  test_assert \
    "Presentation importing common passes" \
    "validate_layered_file 'src/presentation/controllers/LoggingController.ts'" \
    0

  cat > src/business/services/LoggingService.ts <<'EOF'
import { Logger } from '@/common/utils/logger';

export class LoggingService {
  private logger = new Logger();
}
EOF

  test_assert \
    "Business importing common passes" \
    "validate_layered_file 'src/business/services/LoggingService.ts'" \
    0

  echo ""

  # ============================================================================
  # 7. Directory Validation Tests
  # ============================================================================

  echo -e "${BLUE}7. Directory Validation Tests${NC}"

  test_assert \
    "Directory validation detects violations" \
    "validate_layered_directory 'src'" \
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
  echo "Layered Architecture Quick Check Tests"
  echo "=========================================="
  echo ""

  run_tests
  local result=$?

  if [[ "$result" -eq 0 ]]; then
    log_success "Layered Architecture Quick Check tests completed successfully! 🎉"
    exit 0
  else
    log_error "Layered Architecture Quick Check tests failed"
    exit 1
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
