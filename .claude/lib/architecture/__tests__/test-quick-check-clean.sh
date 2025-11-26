#!/bin/bash
# test-quick-check-clean.sh
# Clean Architecture Quick Check 통합 테스트
#
# Usage: bash test-quick-check-clean.sh

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
TEST_PROJECT="${TEST_DIR}/test-clean-project"

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

setup_clean_project() {
  mkdir -p "$TEST_PROJECT/src"
  cd "$TEST_PROJECT"

  # Clean Architecture 구조 생성
  mkdir -p src/{domain,application,infrastructure,presentation}
  mkdir -p src/domain/entities
  mkdir -p src/domain/repositories
  mkdir -p src/application/usecases
  mkdir -p src/infrastructure/persistence
  mkdir -p src/presentation/controllers

  log_success "Clean Architecture test project created: $TEST_PROJECT"
}

# ============================================================================
# 테스트 케이스 생성
# ============================================================================

# 1. Valid Clean Architecture 파일 생성
create_valid_clean_files() {
  # Valid domain entity
  cat > src/domain/entities/User.ts <<'EOF'
export class User {
  constructor(
    public readonly id: string,
    public readonly name: string,
    public readonly email: string
  ) {}

  isValid(): boolean {
    return this.email.includes('@');
  }
}
EOF

  # Valid domain repository interface
  cat > src/domain/repositories/UserRepository.ts <<'EOF'
import { User } from '../entities/User';

export interface UserRepository {
  findById(id: string): Promise<User | null>;
  save(user: User): Promise<void>;
}
EOF

  # Valid application use case
  cat > src/application/usecases/CreateUser.ts <<'EOF'
import { User } from '@/domain/entities/User';
import type { UserRepository } from '@/domain/repositories/UserRepository';

export class CreateUser {
  constructor(private userRepository: UserRepository) {}

  async execute(name: string, email: string): Promise<User> {
    const user = new User(Date.now().toString(), name, email);
    await this.userRepository.save(user);
    return user;
  }
}
EOF

  # Valid infrastructure implementation
  cat > src/infrastructure/persistence/TypeOrmUserRepository.ts <<'EOF'
import { User } from '@/domain/entities/User';
import type { UserRepository } from '@/domain/repositories/UserRepository';

export class TypeOrmUserRepository implements UserRepository {
  async findById(id: string): Promise<User | null> {
    // TypeORM implementation
    return null;
  }

  async save(user: User): Promise<void> {
    // TypeORM implementation
  }
}
EOF

  # Valid presentation controller
  cat > src/presentation/controllers/UserController.ts <<'EOF'
import { CreateUser } from '@/application/usecases/CreateUser';

export class UserController {
  constructor(private createUser: CreateUser) {}

  async handleCreate(req: any, res: any): Promise<void> {
    const user = await this.createUser.execute(req.body.name, req.body.email);
    res.json(user);
  }
}
EOF

  log_success "Valid Clean Architecture files created"
}

# 2. Domain layer violations
create_domain_violations() {
  # Domain importing infrastructure (절대 금지)
  cat > src/domain/entities/Order.ts <<'EOF'
import { TypeOrmUserRepository } from '@/infrastructure/persistence/TypeOrmUserRepository';

export class Order {
  constructor(private repo: TypeOrmUserRepository) {}
}
EOF

  # Domain importing framework
  cat > src/domain/entities/Product.ts <<'EOF'
import { Request, Response } from 'express';

export class Product {
  handleRequest(req: Request, res: Response) {}
}
EOF

  log_success "Domain violation files created"
}

# 3. Application layer violations
create_application_violations() {
  # Application importing infrastructure (금지)
  cat > src/application/usecases/GetUser.ts <<'EOF'
import { TypeOrmUserRepository } from '@/infrastructure/persistence/TypeOrmUserRepository';

export class GetUser {
  constructor(private repo: TypeOrmUserRepository) {}
}
EOF

  # Application importing presentation (금지)
  cat > src/application/usecases/UpdateUser.ts <<'EOF'
import { UserController } from '@/presentation/controllers/UserController';

export class UpdateUser {
  constructor(private controller: UserController) {}
}
EOF

  log_success "Application violation files created"
}

# 4. Presentation layer violations
create_presentation_violations() {
  # Presentation importing infrastructure directly (should use application)
  cat > src/presentation/controllers/OrderController.ts <<'EOF'
import { TypeOrmUserRepository } from '@/infrastructure/persistence/TypeOrmUserRepository';

export class OrderController {
  constructor(private repo: TypeOrmUserRepository) {}
}
EOF

  # Presentation importing domain directly (should use application)
  cat > src/presentation/controllers/ProductController.ts <<'EOF'
import { User } from '@/domain/entities/User';

export class ProductController {
  createUser(): User {
    return new User('1', 'Test', 'test@example.com');
  }
}
EOF

  log_success "Presentation violation files created"
}

# 5. Infrastructure layer violations
create_infrastructure_violations() {
  # Infrastructure importing presentation (금지)
  cat > src/infrastructure/persistence/OrderRepository.ts <<'EOF'
import { UserController } from '@/presentation/controllers/UserController';

export class OrderRepository {
  constructor(private controller: UserController) {}
}
EOF

  log_success "Infrastructure violation files created"
}

# 6. Domain purity violations
create_domain_purity_violations() {
  # Domain with external framework dependency
  cat > src/domain/entities/Account.ts <<'EOF'
import { Entity } from 'typeorm';

@Entity()
export class Account {
  id: string;
}
EOF

  log_success "Domain purity violation files created"
}

# ============================================================================
# 테스트 실행
# ============================================================================

run_tests() {
  log_info "Starting Clean Architecture Quick Check tests..."
  echo ""

  # Quick Check 스크립트 source
  source "${LIB_DIR}/quick-check-clean.sh"

  # 테스트 프로젝트 설정
  setup_clean_project

  # ============================================================================
  # 1. Valid Files Tests
  # ============================================================================

  echo -e "${BLUE}1. Valid Clean Architecture Files Tests${NC}"

  create_valid_clean_files

  test_assert \
    "Valid domain entity passes" \
    "validate_clean_file 'src/domain/entities/User.ts'" \
    0

  test_assert \
    "Valid domain repository interface passes" \
    "validate_clean_file 'src/domain/repositories/UserRepository.ts'" \
    0

  test_assert \
    "Valid application use case passes" \
    "validate_clean_file 'src/application/usecases/CreateUser.ts'" \
    0

  test_assert \
    "Valid infrastructure implementation passes" \
    "validate_clean_file 'src/infrastructure/persistence/TypeOrmUserRepository.ts'" \
    0

  test_assert \
    "Valid presentation controller passes" \
    "validate_clean_file 'src/presentation/controllers/UserController.ts'" \
    0

  echo ""

  # ============================================================================
  # 2. Domain Layer Violation Tests
  # ============================================================================

  echo -e "${BLUE}2. Domain Layer Violation Tests${NC}"

  create_domain_violations

  test_assert \
    "Domain importing infrastructure fails" \
    "validate_clean_file 'src/domain/entities/Order.ts'" \
    1

  test_assert \
    "Domain importing framework fails" \
    "validate_clean_file 'src/domain/entities/Product.ts'" \
    1

  echo ""

  # ============================================================================
  # 3. Application Layer Violation Tests
  # ============================================================================

  echo -e "${BLUE}3. Application Layer Violation Tests${NC}"

  create_application_violations

  test_assert \
    "Application importing infrastructure fails" \
    "validate_clean_file 'src/application/usecases/GetUser.ts'" \
    1

  test_assert \
    "Application importing presentation fails" \
    "validate_clean_file 'src/application/usecases/UpdateUser.ts'" \
    1

  echo ""

  # ============================================================================
  # 4. Presentation Layer Violation Tests
  # ============================================================================

  echo -e "${BLUE}4. Presentation Layer Violation Tests${NC}"

  create_presentation_violations

  test_assert \
    "Presentation importing infrastructure fails" \
    "validate_clean_file 'src/presentation/controllers/OrderController.ts'" \
    1

  test_assert \
    "Presentation importing domain directly fails" \
    "validate_clean_file 'src/presentation/controllers/ProductController.ts'" \
    1

  echo ""

  # ============================================================================
  # 5. Infrastructure Layer Violation Tests
  # ============================================================================

  echo -e "${BLUE}5. Infrastructure Layer Violation Tests${NC}"

  create_infrastructure_violations

  test_assert \
    "Infrastructure importing presentation fails" \
    "validate_clean_file 'src/infrastructure/persistence/OrderRepository.ts'" \
    1

  echo ""

  # ============================================================================
  # 6. Domain Purity Tests
  # ============================================================================

  echo -e "${BLUE}6. Domain Purity Tests${NC}"

  create_domain_purity_violations

  test_assert \
    "Domain with framework dependency fails" \
    "validate_clean_file 'src/domain/entities/Account.ts'" \
    1

  echo ""

  # ============================================================================
  # 7. Type-only Import Tests
  # ============================================================================

  echo -e "${BLUE}7. Type-only Import Tests${NC}"

  # Type-only imports are allowed even for restricted layers
  cat > src/presentation/controllers/TypeOnlyController.ts <<'EOF'
import type { TypeOrmUserRepository } from '@/infrastructure/persistence/TypeOrmUserRepository';

export class TypeOnlyController {
  repo?: TypeOrmUserRepository;
}
EOF

  test_assert \
    "Type-only import passes" \
    "validate_clean_file 'src/presentation/controllers/TypeOnlyController.ts'" \
    0

  echo ""

  # ============================================================================
  # 8. Directory Validation Tests
  # ============================================================================

  echo -e "${BLUE}8. Directory Validation Tests${NC}"

  test_assert \
    "Directory validation detects violations" \
    "validate_clean_directory 'src'" \
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
  echo "Clean Architecture Quick Check Tests"
  echo "=========================================="
  echo ""

  run_tests
  local result=$?

  if [[ "$result" -eq 0 ]]; then
    log_success "Clean Architecture Quick Check tests completed successfully! 🎉"
    exit 0
  else
    log_error "Clean Architecture Quick Check tests failed"
    exit 1
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
