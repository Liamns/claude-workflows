#!/bin/bash
# test-quick-check-hexagonal.sh
# Hexagonal Architecture Quick Check 통합 테스트
#
# Usage: bash test-quick-check-hexagonal.sh

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
TEST_PROJECT="${TEST_DIR}/test-hexagonal-project"

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

setup_hexagonal_project() {
  mkdir -p "$TEST_PROJECT/src"
  cd "$TEST_PROJECT"

  # Hexagonal Architecture 구조 생성
  mkdir -p src/core/{domain,ports}
  mkdir -p src/adapters/{inbound,outbound}
  mkdir -p src/adapters/inbound/http
  mkdir -p src/adapters/outbound/persistence

  log_success "Hexagonal Architecture test project created: $TEST_PROJECT"
}

# ============================================================================
# 테스트 케이스 생성
# ============================================================================

# 1. Valid Hexagonal 파일 생성
create_valid_hexagonal_files() {
  # Valid domain entity
  cat > src/core/domain/User.ts <<'EOF'
export class User {
  constructor(
    public readonly id: string,
    public readonly email: string
  ) {}

  isValid(): boolean {
    return this.email.includes('@');
  }
}
EOF

  # Valid inbound port
  cat > src/core/ports/IUserService.ts <<'EOF'
import { User } from '../domain/User';

export interface IUserService {
  createUser(email: string): Promise<User>;
  getUser(id: string): Promise<User | null>;
}
EOF

  # Valid outbound port
  cat > src/core/ports/IUserRepository.ts <<'EOF'
import { User } from '../domain/User';

export interface IUserRepository {
  save(user: User): Promise<void>;
  findById(id: string): Promise<User | null>;
}
EOF

  # Valid domain service (core/application logic)
  cat > src/core/domain/UserService.ts <<'EOF'
import { User } from './User';
import type { IUserService } from '../ports/IUserService';
import type { IUserRepository } from '../ports/IUserRepository';

export class UserService implements IUserService {
  constructor(private repository: IUserRepository) {}

  async createUser(email: string): Promise<User> {
    const user = new User(Date.now().toString(), email);
    await this.repository.save(user);
    return user;
  }

  async getUser(id: string): Promise<User | null> {
    return await this.repository.findById(id);
  }
}
EOF

  # Valid inbound adapter (HTTP)
  cat > src/adapters/inbound/http/UserController.ts <<'EOF'
import type { IUserService } from '@/core/ports/IUserService';

export class UserController {
  constructor(private userService: IUserService) {}

  async handleCreate(req: any, res: any): Promise<void> {
    const user = await this.userService.createUser(req.body.email);
    res.json(user);
  }
}
EOF

  # Valid outbound adapter (Persistence)
  cat > src/adapters/outbound/persistence/TypeOrmUserRepository.ts <<'EOF'
import { User } from '@/core/domain/User';
import type { IUserRepository } from '@/core/ports/IUserRepository';

export class TypeOrmUserRepository implements IUserRepository {
  async save(user: User): Promise<void> {
    // TypeORM implementation
  }

  async findById(id: string): Promise<User | null> {
    // TypeORM implementation
    return null;
  }
}
EOF

  log_success "Valid Hexagonal files created"
}

# 2. Core independence violations
create_core_independence_violations() {
  # Core importing inbound adapter (절대 금지)
  cat > src/core/domain/Order.ts <<'EOF'
import { UserController } from '@/adapters/inbound/http/UserController';

export class Order {
  constructor(private controller: UserController) {}
}
EOF

  # Core importing outbound adapter (절대 금지)
  cat > src/core/domain/Product.ts <<'EOF'
import { TypeOrmUserRepository } from '@/adapters/outbound/persistence/TypeOrmUserRepository';

export class Product {
  constructor(private repo: TypeOrmUserRepository) {}
}
EOF

  # Ports importing adapters (금지)
  cat > src/core/ports/IOrderService.ts <<'EOF'
import { UserController } from '@/adapters/inbound/http/UserController';

export interface IOrderService {
  controller: UserController;
}
EOF

  log_success "Core independence violation files created"
}

# 3. Domain purity violations
create_domain_purity_violations() {
  # Domain importing ports (금지)
  cat > src/core/domain/Account.ts <<'EOF'
import type { IUserService } from '../ports/IUserService';

export class Account {
  constructor(private service: IUserService) {}
}
EOF

  # Domain importing framework
  cat > src/core/domain/Payment.ts <<'EOF'
import { Request, Response } from 'express';

export class Payment {
  handleRequest(req: Request, res: Response) {}
}
EOF

  log_success "Domain purity violation files created"
}

# 4. Adapter violations
create_adapter_violations() {
  # Inbound adapter importing outbound adapter directly
  cat > src/adapters/inbound/http/OrderController.ts <<'EOF'
import { TypeOrmUserRepository } from '@/adapters/outbound/persistence/TypeOrmUserRepository';

export class OrderController {
  constructor(private repo: TypeOrmUserRepository) {}
}
EOF

  # Outbound adapter not implementing port
  cat > src/adapters/outbound/persistence/DirectRepository.ts <<'EOF'
export class DirectRepository {
  // Not implementing any port interface
  save(data: any) {}
}
EOF

  log_success "Adapter violation files created"
}

# 5. Port naming violations
create_port_naming_violations() {
  # Port without 'I' prefix
  cat > src/core/ports/UserPort.ts <<'EOF'
export interface UserPort {
  getUser(id: string): Promise<any>;
}
EOF

  log_success "Port naming violation files created"
}

# ============================================================================
# 테스트 실행
# ============================================================================

run_tests() {
  log_info "Starting Hexagonal Architecture Quick Check tests..."
  echo ""

  # Quick Check 스크립트 source
  source "${LIB_DIR}/quick-check-hexagonal.sh"

  # 테스트 프로젝트 설정
  setup_hexagonal_project

  # ============================================================================
  # 1. Valid Files Tests
  # ============================================================================

  echo -e "${BLUE}1. Valid Hexagonal Architecture Files Tests${NC}"

  create_valid_hexagonal_files

  test_assert \
    "Valid domain entity passes" \
    "validate_hexagonal_file 'src/core/domain/User.ts'" \
    0

  test_assert \
    "Valid inbound port passes" \
    "validate_hexagonal_file 'src/core/ports/IUserService.ts'" \
    0

  test_assert \
    "Valid outbound port passes" \
    "validate_hexagonal_file 'src/core/ports/IUserRepository.ts'" \
    0

  test_assert \
    "Valid domain service passes" \
    "validate_hexagonal_file 'src/core/domain/UserService.ts'" \
    0

  test_assert \
    "Valid inbound adapter passes" \
    "validate_hexagonal_file 'src/adapters/inbound/http/UserController.ts'" \
    0

  test_assert \
    "Valid outbound adapter passes" \
    "validate_hexagonal_file 'src/adapters/outbound/persistence/TypeOrmUserRepository.ts'" \
    0

  echo ""

  # ============================================================================
  # 2. Core Independence Violation Tests
  # ============================================================================

  echo -e "${BLUE}2. Core Independence Violation Tests (Most Critical)${NC}"

  create_core_independence_violations

  test_assert \
    "Core importing inbound adapter fails" \
    "validate_hexagonal_file 'src/core/domain/Order.ts'" \
    1

  test_assert \
    "Core importing outbound adapter fails" \
    "validate_hexagonal_file 'src/core/domain/Product.ts'" \
    1

  test_assert \
    "Ports importing adapters fails" \
    "validate_hexagonal_file 'src/core/ports/IOrderService.ts'" \
    1

  echo ""

  # ============================================================================
  # 3. Domain Purity Violation Tests
  # ============================================================================

  echo -e "${BLUE}3. Domain Purity Violation Tests${NC}"

  create_domain_purity_violations

  test_assert \
    "Domain importing ports fails" \
    "validate_hexagonal_file 'src/core/domain/Account.ts'" \
    1

  test_assert \
    "Domain importing framework fails" \
    "validate_hexagonal_file 'src/core/domain/Payment.ts'" \
    1

  echo ""

  # ============================================================================
  # 4. Adapter Violation Tests
  # ============================================================================

  echo -e "${BLUE}4. Adapter Violation Tests${NC}"

  create_adapter_violations

  test_assert \
    "Inbound adapter importing outbound adapter fails" \
    "validate_hexagonal_file 'src/adapters/inbound/http/OrderController.ts'" \
    1

  test_assert \
    "Outbound adapter without port implementation shows warnings but passes" \
    "validate_hexagonal_file 'src/adapters/outbound/persistence/DirectRepository.ts'" \
    0

  echo ""

  # ============================================================================
  # 5. Port Naming Tests
  # ============================================================================

  echo -e "${BLUE}5. Port Naming Tests${NC}"

  create_port_naming_violations

  test_assert \
    "Port without I prefix shows warnings but passes" \
    "validate_hexagonal_file 'src/core/ports/UserPort.ts'" \
    0

  echo ""

  # ============================================================================
  # 6. Valid Dependencies Tests
  # ============================================================================

  echo -e "${BLUE}6. Valid Dependencies Tests${NC}"

  # Ports can import domain
  cat > src/core/ports/IProductRepository.ts <<'EOF'
import { User } from '../domain/User';

export interface IProductRepository {
  getUserForProduct(id: string): Promise<User>;
}
EOF

  test_assert \
    "Ports importing domain passes" \
    "validate_hexagonal_file 'src/core/ports/IProductRepository.ts'" \
    0

  # Adapters can import ports and domain
  cat > src/adapters/inbound/http/ProductController.ts <<'EOF'
import type { IUserService } from '@/core/ports/IUserService';
import type { User } from '@/core/domain/User';

export class ProductController {
  constructor(private service: IUserService) {}

  async getUser(id: string): Promise<User | null> {
    return await this.service.getUser(id);
  }
}
EOF

  test_assert \
    "Adapter importing ports and domain passes" \
    "validate_hexagonal_file 'src/adapters/inbound/http/ProductController.ts'" \
    0

  echo ""

  # ============================================================================
  # 7. Type-only Import Tests
  # ============================================================================

  echo -e "${BLUE}7. Type-only Import Tests${NC}"

  # Type-only imports allow more flexibility
  cat > src/core/domain/TypeOnlyService.ts <<'EOF'
import type { TypeOrmUserRepository } from '@/adapters/outbound/persistence/TypeOrmUserRepository';

export class TypeOnlyService {
  repo?: TypeOrmUserRepository;
}
EOF

  test_assert \
    "Type-only import from core to adapter passes" \
    "validate_hexagonal_file 'src/core/domain/TypeOnlyService.ts'" \
    0

  echo ""

  # ============================================================================
  # 8. Directory Validation Tests
  # ============================================================================

  echo -e "${BLUE}8. Directory Validation Tests${NC}"

  test_assert \
    "Directory validation detects violations" \
    "validate_hexagonal_directory 'src'" \
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
  echo "Hexagonal Architecture Quick Check Tests"
  echo "=========================================="
  echo ""

  run_tests
  local result=$?

  if [[ "$result" -eq 0 ]]; then
    log_success "Hexagonal Architecture Quick Check tests completed successfully! 🎉"
    exit 0
  else
    log_error "Hexagonal Architecture Quick Check tests failed"
    exit 1
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
